# Repository Instructions

## Product contract

Moonshot is an offline-first lunar companion for the Omarchy bar. Correct,
honestly labeled astronomical data and native Omarchy behavior take precedence
over animation, novelty, or feature breadth.

## Platform contract

- Target the installed Omarchy shell and current Quickshell APIs.
- Use plugin ID `io.github.rodrix2000.moonshot`.
- Use one `bar-widget` entry point unless verified evidence requires otherwise.
- Follow the current first-party weather widget's bar/panel handoff, keyboard
  focus, popout, summon, and multi-monitor conventions.
- Run `omarchy plugin validate .` before every release candidate.
- Never modify files under `$OMARCHY_PATH`.

## Architecture boundaries

- QML owns presentation, interaction, theme, focus, and in-memory view state.
- `AstronomyClient.qml` owns typed helper invocation and protocol decoding.
- `scripts/moonshot_ephemeris.py` owns input validation, astronomy, time-zone logic,
  event filtering, and JSON serialization.
- `vendor/astronomy/` is pinned upstream source. Do not edit it without a
  documented patch/ADR.
- Rendering consumes normalized phase data and never recomputes astronomy.
- Network access is isolated to explicit location search.

## Astronomy truth

Use Astronomy Engine results and validate integration against committed
USNO/NASA fixtures. Do not substitute emoji, fixed average-month shortcuts, or
unverified API values for precise data.

## State and privacy

- No account, analytics, telemetry, advertising, or tracking.
- Exact coordinates remain local except for explicit city search.
- Manual coordinates/time zone work offline.
- Never write runtime data inside the plugin checkout.
- Prefer Omarchy inline settings; use XDG state only for a verified host gap.
- Weather-location import is explicit and one-time.

## Dependency and security limits

Runtime is limited to current Omarchy platform software, Quickshell/Qt, Python
3 standard library, and pinned vendored Astronomy Engine source.

Forbidden:

- runtime installation/package management;
- sudo, pkexec, sudoers, polkit policy, or privileged helpers;
- systemd services/background daemons;
- compiled or opaque bundled executables;
- remote source execution or unpinned Git code;
- shell evaluation of user-controlled values;
- shared `/tmp` control files;
- collection or transmission beyond explicit city search.

## Required gates

```text
make format-check
make lint
make test
make test-astronomy
make test-protocol
make test-qml
make test-integration
make test-accessibility
make test-performance
make validate-plugin
make package-check
make release-check
```

A flaky astronomy, protocol, lifecycle, or focus test is a release blocker.

## Submission control

An AI agent may draft the marketplace issue, but must show the final content and
exact commit to Rudy and receive explicit approval before issue creation.
