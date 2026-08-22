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
│         │                 ├── Hero MoonDisk (Canvas)   │
│         │                 ├── Primary Metrics          │
│         │                 ├── Phase Events List        │
│         │                 ├── Date Navigation Bar      │
│         │                 └── LocationEditor.qml       │
│         │                                              │
│   MoonshotModel.qml (State, Request Generations)       │
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
2. **AstronomyClient:** Owns subprocess spawning with typed parameter vectors and JSON decoding.
3. **Ephemeris Helper:** Pure Python subprocess with standard library + pinned Astronomy Engine. Validates all inputs and outputs one versioned JSON snapshot.
4. **Vendored Astronomy Engine:** Upstream release pinned to commit `865d3da7d8112bbc7911238052c6af4aaf877181`.
