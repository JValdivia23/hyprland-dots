# Surface Book 3 Native PipeWire Factory Audio DSP Gotchas

## 1. Hardware Architecture & Acoustic Measurements

- **Host & Hardware**: Microsoft Surface Book 3 (`surface`), Intel Ice Lake-LP Smart Sound Technology Audio Controller (`8086:34c8`, `snd_hda_intel`), Realtek ALC274 codec (`10ec0274`, subsys `0x10ec11f0`, codename **`ViaolaE`** for 13.5", **`ViaolaF`** `0x10ec11f2` for 15"), PipeWire 1.6.10 + WirePlumber 0.5.18.
- **Physical Transducers**: Dual stereo micro-speakers embedded inside the magnesium tablet glass bezel slits, plus a dual-microphone beamforming array with 30mm spacing.
- **Why Heuristic Tuning Was Replaced**:
  Previously, an EasyEffects preset (`surface-book.json`) guessed acoustic parameters by ear (-3.0 dB at 3.2 kHz and +2.5 dB at 156–194 Hz).
  By reverse-engineering Microsoft's official Windows 11 driver package (`SurfaceBook3_Win11_22621_25.013.34389.0.msi`), we extracted the actual factory-measured acoustic profiles:
  1. **Speaker Inverse EQ**: Stored in `dax3extdolbyatmos_13/DEV_0274_SUBSYS_10EC11F0_PCI_SUBSYS_72708086.xml` (`<audio-optimizer-bands>` in 1/16 dB units).
  2. **Microphone Array EQ**: Stored in `hdxsstmd3a/RTAIODAT.DAT` under entry `ViaolaE` (`RTMICEQ0` 4-band parametric EQ).

---

## 2. Factory Dolby Atmos & Realtek Parameters

### A. 20-Band Speaker Optimizer Curve (`fs_48000`)
- **Sub-bass Protection**: `85 Hz` Butterworth highpass (`Q = 0.707`) preventing physical micro-transducer over-excursion and flapping.
- **Preamp Attenuation**: `-1.5 dB` headroom (`bq_highshelf freq = 0 gain = -1.5`) matched to Windows driver `volmax-boost` curve, preventing digital clipping while delivering full acoustic volume.
- **Factory Acoustic Optimizer**:
  - `47 Hz`: `+5.00 dB` (Q = 0.94)
  - `141 Hz`: `+10.50 dB` (Q = 1.41) — low-end fullness
  - `234 Hz`: `+11.00 dB` (Q = 2.45) — body/warmth
  - `328 Hz`: `+5.69 dB` (Q = 2.85)
  - `469 Hz`: `+1.00 dB` (Q = 2.89)
  - `656 Hz`: `-4.12 dB` (Q = 3.46) — enclosure resonance cut #1
  - **`844 Hz`: `-8.69 dB` (Q = 4.47)** — **Primary magnesium/glass tablet cavity resonance peak**
  - `1031 Hz`: `-1.19 dB` (Q = 4.47)
  - `1313 Hz`: `+3.69 dB` (Q = 4.04) — vocal presence
  - `1688 Hz`: `-0.12 dB` (Q = 3.67)
  - `2250 Hz`: `+3.62 dB` (Q = 3.47)
  - `3000 Hz`: `+2.44 dB` (Q = 3.97) — articulation
  - `3750 Hz`: `+5.12 dB` (Q = 4.47) — clarity
  - `4688 Hz`: `+4.81 dB` (Q = 4.56)
  - `5813 Hz`: `+0.31 dB` (Q = 4.78)
  - `7125 Hz`: `+3.38 dB` (Q = 4.53)
  - `9000 Hz`: `+1.94 dB` (Q = 4.38)
  - `11250 Hz`: `+8.50 dB` (Q = 4.63) — glass slot diffraction restoration
  - `13875 Hz`: `+11.31 dB` (Q = 3.44) — high treble restoration for narrow bezel slits
  - `19688 Hz`: `-6.69 dB` (Q = 2.77) — ultrasonic roll-off

### B. 4-Band Dual Mic Array Correction (`RTMICEQ0`)
- **Band 1**: `1250 Hz`, `+3.00 dB`, `Q = 3.00` (vocal intelligibility boost)
- **Band 2**: `2100 Hz`, `-2.00 dB`, `Q = 3.00` (nasal cavity attenuation)
- **Band 3**: `3500 Hz`, `-3.00 dB`, `Q = 3.00` (bezel aperture resonance notch)
- **Band 4**: `4000 Hz`, `-2.00 dB`, `Q = 3.00` (high-frequency glare reduction)

---

## 3. Implementation: WirePlumber 0.5 Smart Filter Architecture

Instead of running an external GUI or user-space daemon (like EasyEffects) or a detached virtual sink with decoupled volume, the factory DSP is executed natively inside PipeWire using `libpipewire-module-filter-chain` configured as a **WirePlumber 0.5 Smart Filter** (`filter.smart = true`):
- **Config Path**: `~/.config/pipewire/pipewire.conf.d/50-surface-audio-dsp.conf` (managed in dotfiles under `profiles/surface/.config/pipewire/pipewire.conf.d/50-surface-audio-dsp.conf`).
- **Unified Hardware Volume**: By declaring `filter.smart = true` and `filter.smart.target = "{ \"node.name\": \"alsa_output.pci-0000_00_1f.3.analog-stereo\" }"`, the physical ALSA device remains `@DEFAULT_AUDIO_SINK@`. Desktop volume keys and Noctalia/Waybar volume controls modulate the Realtek ALC274 DAC hardware mixer directly (0–100% full scale, 0.00 dB).
- **Automatic Interception**: WirePlumber transparently intercepts all audio streams playing to the laptop speakers and routes them through the 20-band factory Dolby Atmos EQ curve before reaching the physical DAC.
- **Microphone Source**: `surface_mic_dsp` (`Audio/Source`, `priority.session = 2015`), automatically established as default source and fed from `alsa_input.pci-0000_00_1f.3.analog-stereo`.
- **Zero Daemon Overhead**: Consumes near-zero CPU, requires no background `easyeffects` process, and persists across sessions.

---

## 4. Verification & Diagnostics

1. Check that the physical ALSA sink is the default sink and smart filter is loaded:
   ```bash
   wpctl status
   ```
   `* Built-in Audio Analog Stereo` is default with current volume (e.g. `[vol: 0.40]`), while `surface_speaker_dsp` is active under `Filters`.

2. Check node interconnection in PipeWire graph:
   ```bash
   pw-link -l
   ```
   Verifies:
   - Client streams (e.g. Brave) -> `surface_speaker_dsp:playback_FL/FR`
   - `playback.surface_speaker_dsp:output_FL/FR` -> `alsa_output.pci-0000_00_1f.3.analog-stereo:playback_FL/FR`
   - `alsa_input.pci-0000_00_1f.3.analog-stereo:capture_FL/FR` -> `capture.surface_mic_dsp:input_FL/FR`

3. Headphone Behavior:
   - Plugging in headphones switches the ALSA codec port to `analog-output-headphones`.
   - WirePlumber automatically unlinks the speaker smart filter, delivering uncolored, flat audio directly to headphones.
