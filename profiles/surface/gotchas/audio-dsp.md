# Surface Book 3 Audio DSP & EasyEffects Tuning Gotchas

## 1. Hardware Architecture & Acoustic Quirks

- **Host & Hardware**: Microsoft Surface Book 3 (`surface`), Intel Ice Lake-LP Smart Sound Technology Audio Controller (`8086:34c8`, `snd_hda_intel`), Realtek ALC274 codec (`10ec0274`), PipeWire 1.6.9 + WirePlumber 0.5.18.
- **Physical Transducers**: Dual stereo micro-speakers (~15-18mm) embedded inside the magnesium tablet glass bezel.
- **The Raw ALSA Quirk**: On Windows, Microsoft bundles a proprietary Dolby Audio / Dolby Atmos APO hardware-tuned DSP profile. On Linux, the standard ALSA/PipeWire driver outputs an unprocessed, flat stereo signal. Without DSP:
  - Frequencies below ~140 Hz cannot physically be reproduced by the tiny cones, causing voice-coil overheating, cone turbulence, and clipping distortion.
  - The magnesium/glass tablet cavity creates harsh resonance spikes in the 2.8 kHz – 4 kHz band ("tinny" or "glare" sound).
  - Stereo perception is narrow due to tablet dimensions.

---

## 2. DSP Pipeline Solution (`surface-book.json`)

To artificially recreate missing bass and correct chassis acoustics, a tailored 5-stage DSP chain runs via EasyEffects:
1. **High-Pass Filter (`filter#0`)**: 90 Hz steep 12 dB/oct cut (RLC BT) to strip inaudible sub-bass and protect the speakers from distortion.
2. **Harmonic Bass Enhancer (`bass_enhancer#0` via Calf)**: Exploits the psychoacoustic **"Missing Fundamental"** effect. Detects low frequencies (up to 145 Hz) and generates 2nd and 3rd order harmonics (in the 150 Hz – 350 Hz audible range) with +10 dB virtual bass presence, tricking the brain into perceiving deep sub-bass that the physical cones cannot produce.
3. **Parametric Equalizer (`equalizer#0` via LSP)**: 32-band EQ providing +2.5 dB warm lower-mid body (156–194 Hz), +1.5–2.0 dB vocal presence (1.3–1.7 kHz), -3.0 dB suppression of harsh chassis resonance (3.2 kHz), and +1.5–2.0 dB airy clarity (9.5–12 kHz).
4. **Stereo Tools (`stereo_tools#0` via Calf)**: +15% stereo expansion and 0.04 ms Haas effect delay to broaden the soundstage past the physical tablet screen.
5. **Lookahead Peak Limiter (`limiter#0` via LSP)**: Transparent fast limiter (ceiling at -1.0 dB) to completely eliminate clipping and distortion even at 100% volume.

---

## 3. Plugin Engine Gotcha (`calf` vs `lsp-plugins-lv2`)

In EasyEffects 8.3+:
- **`calf` (Calf Studio Gear LV2)** is strictly required for `BassEnhancer` and `StereoTools`. If `calf` is not installed, EasyEffects throws `Could not find the plugin: http://calf.sourceforge.net/plugins/BassEnhancer`.
- **`lsp-plugins-lv2` (Linux Studio Plugins)** is strictly required for `Equalizer`, `Limiter`, and `Filter`.
- Both must be listed in `profiles/surface/packages.txt`.

---

## 4. EasyEffects 8.3 Preset Storage Path Migration

- **Old Path**: `~/.config/easyeffects/output/<preset>.json`
- **New Path (8.3+)**: `~/.local/share/easyeffects/output/<preset>.json`
- **Gotcha**: On startup, EasyEffects 8.3 migrates JSON presets from `~/.config/easyeffects/output/` into `~/.local/share/easyeffects/output/`. Dotfiles stores the master copy in `profiles/surface/.local/share/easyeffects/output/surface-book.json` and symlinks it to ensure persistence.
- Live state and last loaded presets are stored in QSettings INI files at `~/.config/easyeffects/db/easyeffectsrc`.

---

## 5. Background Autostart & Control Commands

- **Autostart**: Configured in `profiles/surface/.config/hypr/config/profile/autostart.lua`:
  ```lua
  hl.on("hyprland.start", function ()
      hl.exec_cmd(homeDir .. "/.local/bin/hypr-lisgd")
      hl.exec_cmd("easyeffects --service-mode")
  end)
  ```
- **A/B Comparison (Toggle Bypass)**:
  ```bash
  easyeffects --bypass-toggle
  ```
  *(Toggles the DSP on/off instantly so you can hear the raw vs. enhanced difference).*
- **Force Reload Preset**:
  ```bash
  easyeffects -l surface-book
  ```
- **Emergency Clean Audio Pipeline Reset**:
  ```bash
  pkill -x easyeffects
  systemctl --user restart pipewire wireplumber
  wpctl set-volume @DEFAULT_AUDIO_SINK@ 40%
  easyeffects --service-mode &
  ```
