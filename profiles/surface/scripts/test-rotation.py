#!/usr/bin/env python3
"""Mocked regression tests; never rotate a display or open the DTX hardware."""

import importlib.machinery
import importlib.util
import json
import os
from pathlib import Path
import re
import shlex
import shutil
import stat
import struct
import subprocess
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import MagicMock, Mock, patch


PROFILE = Path(__file__).resolve().parent.parent


def load(name, path):
    loader = importlib.machinery.SourceFileLoader(name, str(path))
    module = importlib.util.module_from_spec(importlib.util.spec_from_loader(name, loader))
    loader.exec_module(module)
    return module


base = load("base_state", PROFILE / "scripts/surface-base-state.py")
rotation = load("autorotate", PROFILE / ".local/bin/surface-autorotate")
with patch("signal.signal"), patch("atexit.register"):
    resizer = load("touch_resizer", PROFILE / ".local/bin/hypr-touch-resizer")


class BaseStateTests(unittest.TestCase):
    def test_detached_requires_absent_base_id(self):
        self.assertIs(base.decode_base(struct.pack("=HH", 0, 0))["attached"], False)
        self.assertIsNone(base.decode_base(struct.pack("=HH", 0, 0x201))["attached"])

    def test_kernel_type_tagged_empty_base_is_detached(self):
        self.assertIs(base.decode_base(struct.pack("=HH", 0, 0x200))["attached"], False)

    def test_attached_including_reversed_base(self):
        self.assertIs(base.decode_base(struct.pack("=HH", 1, 0x201))["attached"], True)

    def test_low_battery_is_not_detached(self):
        self.assertIs(base.decode_base(struct.pack("=HH", 0x1001, 0x201))["attached"], True)

    def test_unknown_status_disables_rotation(self):
        self.assertIsNone(base.decode_base(struct.pack("=HH", 0xF001, 0))["attached"])

    def test_bad_payload_length(self):
        with self.assertRaises(ValueError):
            base.decode_base(b"\x00")

    def test_fragmented_and_unknown_events(self):
        event = struct.pack("=HHHH", 4, 3, 0, 0)
        buffer = bytearray(event[:5])
        self.assertEqual(base.consume_events(buffer), [])
        buffer.extend(event[5:] + struct.pack("=HH", 0, 99))
        self.assertEqual(base.consume_events(buffer), [(3, b"\x00" * 4), (99, b"")])
        self.assertEqual(buffer, bytearray())

    def test_invalid_event_length(self):
        with self.assertRaises(ValueError):
            base.consume_events(bytearray(struct.pack("=HH", 65535, 3)))


class RotationTests(unittest.TestCase):
    def read_status(self, value, uid=0, mode=0o644):
        stream = MagicMock()
        stream.__enter__.return_value = stream
        stream.read.return_value = json.dumps(value)
        info = SimpleNamespace(st_uid=uid, st_mode=stat.S_IFREG | mode)
        with patch.object(rotation.os, "open", return_value=123), \
             patch.object(rotation.os, "fdopen", return_value=stream), \
             patch.object(rotation.os, "fstat", return_value=info):
            return rotation.read_base()

    def test_status_reader_accepts_kernel_absent_base_tag(self):
        value = {"attached": False, "base_state": 0, "base_id": 0x200}
        self.assertIs(self.read_status(value), False)

    def test_status_reader_rejects_untrusted_owner_or_permissions(self):
        value = {"attached": False, "base_state": 0, "base_id": 0}
        self.assertIsNone(self.read_status(value, uid=1000))
        self.assertIsNone(self.read_status(value, mode=0o666))

    def test_status_reader_rejects_contradictory_detached_state(self):
        value = {"attached": False, "base_state": 1, "base_id": 527}
        self.assertIsNone(self.read_status(value))

    def controller(self):
        controller = rotation.AutoRotate()
        controller.watch_base = Mock()
        controller.set_transform = Mock()
        controller.claim_sensor = Mock()
        controller.release_sensor = Mock()
        return controller

    def test_attached_never_claims_sensor(self):
        controller = self.controller()
        with patch.object(rotation, "read_base", return_value=True):
            controller.sync_base()
        controller.claim_sensor.assert_not_called()
        controller.release_sensor.assert_called_once()
        controller.set_transform.assert_called_once_with(0, force=False)

    def test_unknown_state_returns_to_landscape(self):
        controller = self.controller()
        controller.base = False
        with patch.object(rotation, "read_base", return_value=None):
            controller.sync_base()
        controller.claim_sensor.assert_not_called()
        controller.set_transform.assert_called_once_with(0, force=False)

    def test_detached_claims_sensor(self):
        controller = self.controller()
        with patch.object(rotation, "read_base", return_value=False):
            controller.sync_base()
        controller.claim_sensor.assert_called_once()
        controller.set_transform.assert_not_called()

    def test_attach_cancels_pending_rotation_at_commit(self):
        controller = self.controller()
        controller.base = False
        controller.claimed = True
        with patch.object(rotation, "read_base", return_value=True):
            controller.commit_rotation(1)
        controller.set_transform.assert_called_once_with(0, force=False)

    def test_all_detached_orientations(self):
        for transform in range(4):
            with self.subTest(transform=transform):
                controller = self.controller()
                controller.base = False
                controller.claimed = True
                with patch.object(rotation, "read_base", return_value=False):
                    controller.commit_rotation(transform)
                controller.set_transform.assert_called_once_with(transform)

    def test_sleep_releases_sensor_and_cancels_rotation(self):
        controller = self.controller()
        parameters = Mock()
        parameters.unpack.return_value = (True,)
        controller.prepare_for_sleep(None, None, None, None, None, parameters)
        self.assertTrue(controller.suspended)
        controller.release_sensor.assert_called_once()

    def test_no_hardware_queries_during_attached_periodic_check(self):
        controller = self.controller()
        controller.base = True
        controller.applied = 0
        with patch.object(rotation, "read_base", return_value=True), patch.object(rotation, "hypr") as hypr:
            controller.periodic()
        hypr.assert_not_called()
        controller.claim_sensor.assert_not_called()
        controller.set_transform.assert_not_called()

    def test_lua_only_targets_internal_surface_inputs(self):
        devices = {
            "touch": [{"name": "iptsd-virtual-touchscreen-045e:09b2"}, {"name": "external-touchscreen"}],
            "tablets": [{"name": "iptsd-virtual-stylus-045e:09b2"}, {"name": "wacom"}],
        }
        code = rotation.rotation_lua(1, devices)
        self.assertIn('output = "eDP-1", transform = 1', code)
        self.assertIn("iptsd-virtual-touchscreen", code)
        self.assertIn("iptsd-virtual-stylus", code)
        self.assertNotIn("external-touchscreen", code)
        self.assertNotIn("wacom", code)
        self.assertNotIn("scale", code)
        self.assertNotIn("mode", code)

    def test_mirrored_transform_is_rejected(self):
        with self.assertRaises(ValueError):
            rotation.rotation_lua(4, {})

    def test_input_and_display_failure_attempts_landscape_rollback(self):
        controller = rotation.AutoRotate()
        with patch.object(rotation, "apply_transform", side_effect=[RuntimeError("failed"), None]) as apply:
            controller.set_transform(1)
        self.assertEqual([call.args[0] for call in apply.call_args_list], [1, 0])
        self.assertEqual(controller.applied, 0)


class CoordinateTests(unittest.TestCase):
    def test_resize_directions_in_every_orientation(self):
        expected = [(15, 10), (-10, 15), (-15, -10), (10, -15)]
        for transform in range(4):
            geometry = dict(resizer.DEFAULT_GEOMETRY, transform=transform)
            result = resizer.transform_delta(96, 72, [9600, 7200], geometry)
            self.assertEqual(result, expected[transform])

    def test_resize_uses_actual_axis_ranges_and_scale(self):
        geometry = {"width": 3000, "height": 2000, "scale": 1.5, "transform": 1}
        dx, dy = resizer.transform_delta(100, 100, [1000, 2000], geometry)
        self.assertAlmostEqual(dx, -2000 / 1.5 * 0.05)
        self.assertAlmostEqual(dy, 3000 / 1.5 * 0.1)

    def test_axis_ranges_are_queried_from_input_device(self):
        def ioctl(_fd, request, value, _mutate):
            self.assertIn(request, (0x80184575, 0x80184576))
            value[:] = struct.pack("=iiiiii", 0, 10, 1010, 0, 0, 0)
        with patch.object(resizer.fcntl, "ioctl", side_effect=ioctl):
            self.assertEqual(resizer.touch_ranges(123), [1000, 1000])

    def test_lisgd_uses_inverse_transform_and_native_dimensions(self):
        source = (PROFILE / ".local/bin/hypr-lisgd").read_text()
        self.assertIn("(4 - TRANSFORM) % 4", source)
        self.assertIn('-o "$ORIENTATION"', source)
        self.assertIn("-w 3000", source)
        self.assertIn("-h 2000", source)

    def test_lisgd_termination_exits_instead_of_restarting_child(self):
        source = (PROFILE / ".local/bin/hypr-lisgd").read_text()
        self.assertIn("trap 'exit 0' INT TERM", source)


class ReinstallTests(unittest.TestCase):
    def temporary_home(self):
        directory = "/tmp/opencode" if Path("/tmp/opencode").is_dir() else None
        return tempfile.TemporaryDirectory(prefix="surface-reinstall-test-", dir=directory)

    @unittest.skipUnless(shutil.which("stow"), "GNU Stow is required for the deployment test")
    def test_fresh_stow_includes_session_units_but_not_system_sources(self):
        repo = PROFILE.parent.parent
        installer = (repo / "install.sh").read_text()
        array = re.search(r"STOW_IGNORE_FLAGS=\((.*?)\n    \)", installer, re.S).group(1)
        flags = shlex.split(array)
        with self.temporary_home() as temporary:
            home = Path(temporary)
            result = subprocess.run(
                ["stow", "--no-folding", "-d", str(repo / "profiles"), "-t", str(home), *flags, "surface"],
                capture_output=True, text=True, env=dict(os.environ, HOME=str(home)),
            )
            self.assertEqual(result.returncode, 0, result.stderr)
            for relative in [
                ".local/bin/surface-autorotate",
                ".local/bin/hypr-lisgd",
                ".local/bin/hypr-touch-resizer",
                ".config/systemd/user/surface-autorotate.service",
                ".config/systemd/user/hypr-lisgd.service",
                ".config/systemd/user/hypr-touch-resizer.service",
                ".config/hypr/config/profile/autostart.lua",
            ]:
                self.assertTrue((home / relative).is_symlink(), relative)
                self.assertEqual((home / relative).resolve(), (PROFILE / relative).resolve())
            for metadata in ("systemd", "scripts", "gotchas"):
                self.assertFalse((home / metadata).exists(), metadata)

    def setup_calls(self, product, user_manager=True):
        text = (PROFILE / "setup.sh").read_text()
        fragment = text.split("# 12. Surface Book 3 physical-detachment-only screen rotation.", 1)[1]
        fragment = fragment.split('echo "==> Microsoft Surface setup finished."', 1)[0]
        with self.temporary_home() as temporary:
            home = Path(temporary)
            commands = home / "mock-bin"
            commands.mkdir()
            log = home / "commands.log"
            unit = home / ".config/systemd/user/surface-autorotate.service"
            unit.parent.mkdir(parents=True)
            unit.write_text("# Test fixture only\n")
            scripts = {
                "cat": 'printf "%s\\n" "$TEST_PRODUCT"\n',
                "sudo": 'printf "%s\\n" "sudo $*" >> "$AUDIT_LOG"\n',
                "systemctl": (
                    'printf "%s\\n" "systemctl $*" >> "$AUDIT_LOG"\n'
                    'if [[ "$*" == "--user show-environment" && "$TEST_USER_MANAGER" == 0 ]]; then exit 1; fi\n'
                ),
            }
            for name, body in scripts.items():
                path = commands / name
                path.write_text("#!/usr/bin/env bash\n" + body)
                path.chmod(0o755)
            environment = dict(
                os.environ, HOME=str(home), PATH=str(commands) + os.pathsep + os.environ["PATH"],
                AUDIT_LOG=str(log), TEST_PRODUCT=product, TEST_USER_MANAGER=str(int(user_manager)),
            )
            result = subprocess.run(
                ["bash", "-euc", "SCRIPT_DIR=" + shlex.quote(str(PROFILE)) + "\n" + fragment],
                capture_output=True, text=True, env=environment,
            )
            self.assertEqual(result.returncode, 0, result.stderr)
            return log.read_text() if log.exists() else ""

    def test_book3_setup_deploys_broker_and_enables_session_service(self):
        calls = self.setup_calls("Surface Book 3")
        self.assertIn("scripts/install-rotation.sh --no-packages", calls)
        if os.geteuid() != 0:
            self.assertIn("systemctl --user daemon-reload", calls)
            self.assertIn("systemctl --user enable surface-autorotate.service", calls)
        self.assertNotIn("systemctl --user start", calls)

    def test_no_user_manager_defers_to_next_hyprland_login(self):
        calls = self.setup_calls("Surface Book 3", user_manager=False)
        self.assertIn("scripts/install-rotation.sh --no-packages", calls)
        self.assertNotIn("systemctl --user enable", calls)

    def test_other_hardware_does_not_deploy_rotation(self):
        self.assertEqual(self.setup_calls("MacBookPro15,1"), "")

    def test_standalone_installer_covers_gobject_dependency(self):
        installer = (PROFILE / "scripts/install-rotation.sh").read_text()
        self.assertIn("pacman -S --needed iio-sensor-proxy python-gobject", installer)
        self.assertIn("pacman -Q iio-sensor-proxy python-gobject", installer)


if __name__ == "__main__":
    unittest.main(verbosity=2)
