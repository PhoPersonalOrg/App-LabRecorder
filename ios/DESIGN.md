# Design System: LabRecorder iOS
**Project ID:** 15853052594003468744  
**Source screen:** Lab Recorder - Segmented Layout (`568ec19f8f734677b29b6651beb5a498`)

## 1. Visual Theme & Atmosphere
Dense, utilitarian lab-instrument aesthetic in true dark mode. Obsidian canvas with inset charcoal cards, glass-blurred sticky chrome, and emerald/cyan telemetry accents. Feels like a precision acquisition cockpit rather than a consumer lifestyle app—tight mono labels, status pills, and a tactile primary record control.

## 2. Color Palette & Roles
- **Obsidian Canvas** (`#0C0D0E`) — App background / sticky header & footer glass base
- **Charcoal Card** (`#1C1C1E`) — Grouped lists, segmented track, secondary buttons
- **Elevated Ink** (`#161618`) — HUD telemetry inset panel
- **Deep Well** (`#121214`) — Nested path/metric wells
- **Hairline Border** (`#2C2C2E`) — Dividers, unselected segment fill, checkbox wells
- **Whisper White Border** (`rgba(255,255,255,0.05)`) — Soft card outlines
- **Primary Text** (`#FFFFFF`) — Titles and selected segment labels
- **Secondary Label** (`#A3A3A3` / neutral-400) — Hostnames, section captions, inactive tabs
- **Muted Mono** (`#8E8E93`) — Tertiary iOS gray sublabels
- **System Accent Blue** (`#007AFF`) — Select All, Browse Files, checkbox selected
- **Signal Emerald** (`#34C759` / emerald-400–500) — Online names, signal bars, BIDS/RCS toggles on
- **Standby Pill Fill** (`emerald-950/80` ≈ `#022c22cc`) + border emerald-500/30 — STANDBY • READY badge
- **Telemetry Cyan** (`#22D3EE`) — Active stream counts, modality value
- **Record Gradient** (`#10B981` → `#16A34A`) — Start Recording primary CTA
- **Tag accents** — Blue (EEG), Purple (IMU), Amber (CQ), Teal (Markers), Indigo (ASR), Rose (Video)

## 3. Typography Rules
SF Pro / system sans for UI chrome; SF Mono for rates, durations, ports, paths, and BIDS IDs. Section headers are uppercase, semibold, ~12pt with wide tracking. Stream titles are 14–15pt semibold emerald when selected, muted when idle. Badge/chip copy is 10–11pt medium.

## 4. Component Stylings
* **Buttons:** Circular 32pt tool buttons (settings/help) on charcoal; primary CTA is full-width 48pt pill with generously rounded corners (~16pt), emerald gradient, black label, soft emerald glow; lock/stop are 48pt rounded-2xl charcoal squares.
* **Cards/Containers:** Inset grouped lists with ~16pt corner radius, hairline borders, row dividers. HUD uses ~12pt radius inset panel.
* **Inputs/Forms:** Transparent mono fields inside card rows; iOS-style green switches; compact stepper in charcoal capsule.
* **Segmented control:** Charcoal track, 4pt padding, selected segment elevated mid-gray fill with white label.
* **Status pills:** Capsule badges with hairline borders and optional pulsing green dot.

## 5. Layout Principles
Horizontal margin ~16pt. Sticky header stacks nav + HUD + segmented control. Main content scrolls with bottom padding clearing the floating record dock. Three-column metric strip under status. Stream rows: checkbox | text stack | trailing signal/status. Dense vertical rhythm (~12pt between sections, 12pt row padding).
