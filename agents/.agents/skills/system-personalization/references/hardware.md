# Hardware Specifications (`surface` - Surface Book 3)

Live physical system specifications probed automatically.

## System & Architecture
- **Product / Model**: Surface Book 3
- **Hostname**: `surface`
- **Architecture**: x86_64
- **Active Profiles**: surface

## CPU & Processing
- **Processor**: Intel(R) Core(TM) i5-1035G7 CPU @ 1.20GHz
- **Physical Cores / Threads**: 8
- **CPU max MHz**: 3700.0000
- **CPU min MHz**: 400.0000
- **L3 cache**: 6 MiB (1 instance)

## Graphics Processing Units (GPUs)
- **Detected GPU(s)**: Intel Corporation Iris Plus Graphics G7
  00:02.0 VGA compatible controller: Intel Corporation Iris Plus Graphics G7 (rev 07)
  	Subsystem: Microsoft Corporation Device 0043
  	Kernel driver in use: i915

## Memory & Swap
- **Total System RAM**: 7.4Gi
- **Swap Space**: 16Gi

## Storage & Filesystems
```
Filesystem      Size  Used Avail Use% Mounted on
/dev/nvme0n1p2  226G  9.8G  215G   5% /
/dev/nvme0n1p2  226G  9.8G  215G   5% /home
```

## Displays & Monitors
- **Primary Display**: eDP-1 (3000x2000@60Hz, scale 2)
```
Monitor eDP-1 (ID 0):
	3000x2000@59.98500 at 0x0
	make: Panasonic Industry Company
	model: TDM13O56    
	scale: 2
	transform: 0
	availableModes: 3000x2000@59.98Hz 
```

## Audio & Sound Processing
- **Audio Controller**: Intel Corporation Ice Lake-LP Smart Sound Technology Audio Controller (`8086:34c8`, `snd_hda_intel`)
- **Audio Codec**: Realtek ALC274 Analog (`10ec0274`, Subsystem `10ec11f0`)
- **Default Routing**: PipeWire 1.6.9 + WirePlumber 0.5.18 (`alsa_output.pci-0000_00_1f.3.analog-stereo`)
- **Physical Transducers**: Front-firing stereo micro-speakers integrated into tablet display glass bezel
- **Active DSP Engine**: EasyEffects 8.3 (`easyeffects --service-mode`) backed by `lsp-plugins-lv2` & `calf`
- **Active Preset**: `surface-book-hybrid` (90Hz subsonic high-pass filter, 145Hz missing-fundamental psychoacoustic bass synthesis, 3.2kHz chassis resonance suppression EQ, Dolby Atmos 3D Convolver impulse, 15% stereo expansion, -1.0dB true-peak lookahead limiter)
