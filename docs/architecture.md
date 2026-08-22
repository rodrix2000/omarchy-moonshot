# Architecture & Design

## System Overview

Moonshot follows a strict separation of concerns between presentation and astronomical calculation:

```
┌────────────────────────────────────────────────────────┐
│ Omarchy Bar & Shell (Quickshell / Qt6 QML)             │
│                                                        │
│   BarWidget.qml ──────> Bar Button (Status Slot)       │
│         │                                              │
│         ├─── Loader ──> Panel.qml (KeyboardPanel)      │
│         │                 ├── MoonshotContent.qml      │
│         │                 │   ├── MoonDisk + texture   │
│         │                 │   ├── Observer metrics     │
│         │                 │   └── Events + commands    │
│         │                 ├── Primary Metrics          │
│         │                 ├── Phase Events List        │
│         │                 ├── Date Navigation Bar      │
│         │                 └── LocationEditor.qml       │
│         │                                              │
│   MoonshotModel.qml (Selection, XDG state, last-good)  │
│         │                                              │
│   AstronomyClient.qml (Process Invocation)             │
└─────────┼──────────────────────────────────────────────┘
          │ Direct argument array (Process.command)
          ▼
┌────────────────────────────────────────────────────────┐
│ Python Helper (Isolated Subprocess)                    │
│                                                        │
│   scripts/moonshot_ephemeris.py                        │
│         │                                              │
│   vendor/astronomy/astronomy.py (Astronomy Engine)     │
└────────────────────────────────────────────────────────┘
```

## Architectural Boundaries

1. **QML Presentation Layer:** Owns UI components, interaction, animations, themes, and in-memory view model state.
2. **AstronomyClient:** Owns subprocess spawning with typed argument vectors, one-active/newest-pending request scheduling, a three-second timeout, 64 KiB output ceilings, protocol validation, and redacted failures.
3. **Ephemeris Helper:** Pure Python subprocess with standard library + pinned Astronomy Engine. Validates coordinates, elevation, time zone, date, instant, and observation mode, then outputs one versioned JSON snapshot.
4. **Vendored Astronomy Engine:** Upstream release pinned to commit `865d3da7d8112bbc7911238052c6af4aaf877181`.

## State and Rendering

- Host plugin settings are read first. Otherwise, validated location state is loaded from `${XDG_STATE_HOME:-$HOME/.local/state}/moonshot/settings-v1.json`.
- Writes are atomic; the state directory is mode `0700` and the file is normalized to `0600`.
- Date browsing uses local calendar dates anchored at 21:00 in the selected location. Phase-event jumps use their exact UTC instant.
- `MoonDisk.qml` combines a neutral generated RGBA texture with a computed north-up phase silhouette. Omarchy theme tokens control surrounding surfaces, rim, glow, focus, and text.
