# Idle Power Baseline Tracking (Surface Book 3)

**Scope:** device-specific (`profiles/surface`): sums the dual-battery `power_now` and reads the Surface backlight.

Purpose: measure idle battery draw with comparable conditions so kernel/package updates (e.g. the
CachyOS jump to 7.3) can be judged with numbers instead of impressions.

## 1. Tool
`~/dotfiles/profiles/surface/scripts/surface-idle-power.py` (Python 3, **no root**; run in place, not installed to `/usr/local/bin`).

```bash
~/dotfiles/profiles/surface/scripts/surface-idle-power.py --label "7.3 baseline"   # 30-60s settle + 300s window
~/dotfiles/profiles/surface/scripts/surface-idle-power.py --history                # markdown table of past runs
```
- Samples `BAT1 + BAT2` `power_now` every 5 s; headline number is the **median**.
- Also records CPU idle %, avg MHz, per-state C-state residency, busiest processes, brightness, power profile/governor/EPP.
- Appends every run to `~/.local/state/surface-idle-power/log.jsonl` (outside dotfiles; local measurement data).
- Refuses to run on AC (draw would be meaningless) unless `--allow-ac`.
- Flags: `noisy:<proc>=N%core` (a process >= 5% of one core), `brightness-changed`, `battery-not-discharging`, `ac-connected-during-run`, `uptime<10min`. Only compare **clean** runs.

## 2. Gotchas
- **hypridle changes the screen mid-run.** `~/.config/hypr/hypridle.conf` dims to 10% at 150 s idle and DPMS-offs at 300 s. The script re-execs itself under `systemd-inhibit --what=idle` (hypridle has `ignore_systemd_inhibit = false`) so the screen state stays constant. `--no-inhibit` disables this.
- **Start from the normal screen state.** After a long idle, brightness is dimmed to 10% until input arrives; run `brightnessctl -r` first (what hypridle's `on-resume` does) so every baseline starts at the usual **25% (24000/96000)**. Compare runs only at equal brightness.
- **Energy counters are unreliable here.** The `energy_now`-delta cross-check gave 17.7 W in one run (vs 5.9 W `power_now`) and 5.62 W in a clean run. Trust the `power_now` median; use the energy figure only as a sanity check.
- **The AI agent session is part of the load.** `agy` used ~4.6% of a core during the "idle" baseline (17% while actively running tools). Repeat runs with a comparably quiet agent (or none) or the numbers are not comparable.
- **Short runs mislead.** A 12 s smoke test read ~10 W (agent busy); 300 s windows read ~5.9 W. Use the default window.
- Run on battery, Wi-Fi connected, uptime > 10 min, `power-saver` profile (current default), nothing else running.

## 3. Recorded baselines (median of `BAT1+BAT2` `power_now`)
| Date | Kernel | Median W | Mean W | Stdev | Energy-delta W | CPU idle | C3 residency | Flags / notes |
|---|---|---|---|---|---|---|---|---|
| 2026-10-19 | `7.2.11-1-cachyos` | **5.86** | 5.91 | 0.14 | 5.62 | 99.1% | 95.5% | **clean**: 25% brightness, idle-inhibited, power-saver/powersave/power |
| 2026-10-19 | `7.2.11-1-cachyos` | 5.94 | 6.04 | 0.29 | 17.7 (glitch) | 99.0% | 95.0% | `brightness-changed` (hypridle dimmed late in window); superseded, kept for the noise estimate |

Two same-kernel runs differed by 0.08 W in median, so treat differences below roughly 0.2 W as noise until more runs exist.
Previous kernel `7.2.9-2-cachyos` was **not** measured, so there is no before/after for the 7.2.11 update.

## 4. Planned comparison
When CachyOS ships Linux 7.3, run the tool once on `7.2.11` (if not recent) and once after the update, under identical conditions
(25% brightness via `brightnessctl -r`, on battery, similar agent load), then add the rows above.
