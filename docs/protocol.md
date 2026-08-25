# Data Protocol Specification

## CLI Invocation

```bash
python3 scripts/moonshot_ephemeris.py snapshot \
  --request-id <generation-id> \
  --mode <auto|now|browse|event> \
  --instant-utc <ISO-8601-UTC> \
  --selected-date <YYYY-MM-DD> \
  --timezone <IANA-Timezone> \
  [--latitude <float>] \
  [--longitude <float>] \
  [--elevation-m <float>] \
  [--location-label <label>]
```

## Response Schema (Protocol v1)

```json
{
  "protocolVersion": 1,
  "requestId": "generation-42",
  "generatedAtUtc": "2026-08-22T19:30:00Z",
  "status": "ok",
  "data": {
    "observation": {
      "instantUtc": "2026-08-22T19:30:00Z",
      "instantEpochMs": 1787427000000,
      "selectedLocalDate": "2026-08-22",
      "localDateTime": "2026-08-22T14:30:00-05:00",
      "timeZone": "America/Chicago",
      "timeZoneAbbreviation": "CDT",
      "utcOffsetSeconds": -18000,
      "mode": "now"
    },
    "location": {
      "configured": true,
      "label": "Celina, Texas",
      "latitude": 33.0,
      "longitude": -96.0,
      "elevationM": 0.0
    },
    "moon": {
      "phaseAngleDeg": 134.2,
      "phaseName": "Waxing Gibbous",
      "direction": "waxing",
      "illuminationFraction": 0.83,
      "illuminationPercent": 83.0,
      "ageDays": 11.4,
      "previousNewMoonUtc": "2026-08-11T00:00:00Z",
      "renderConvention": "north-up"
    },
    "horizon": {
      "configured": true,
      "altitudeDeg": 28.4,
      "azimuthDeg": 117.2,
      "aboveHorizon": true,
      "convention": "astronomy-engine-apparent"
    },
    "events": {
      "rise": {
        "status": "event",
        "instantUtc": "2026-08-22T22:42:00Z",
        "localDateTime": "2026-08-22T17:42:00-05:00"
      },
      "set": {
        "status": "event",
        "instantUtc": "2026-08-23T09:18:00Z",
        "localDateTime": "2026-08-23T04:18:00-05:00"
      },
      "nextMajorPhases": [
        {
          "quarter": 2,
          "name": "Full Moon",
          "instantUtc": "2026-08-25T00:00:00Z",
          "localDateTime": "2026-08-24T19:00:00-05:00"
        }
      ]
    },
    "planning": {
      "calendar": {
        "year": 2026,
        "month": 8,
        "firstWeekday": 5,
        "dayCount": 31,
        "todayLocalDate": "2026-08-22",
        "days": [
          {
            "date": "2026-08-01",
            "day": 1,
            "phaseAngleDeg": 220.13,
            "phaseName": "Waning Gibbous",
            "direction": "waning",
            "illuminationFraction": 0.8826,
            "illuminationPercent": 88.3,
            "majorPhase": null
          }
        ]
      },
      "cycle": {
        "startInstantUtc": "2026-08-12T17:37:11Z",
        "endInstantUtc": "2026-09-11T03:27:28Z",
        "durationDays": 29.41,
        "ageDays": 10.08,
        "position": 0.34269,
        "events": []
      },
      "upcomingEclipses": [
        {
          "type": "lunar",
          "kind": "partial",
          "title": "Partial Lunar Eclipse",
          "peakUtc": "2026-08-28T04:12:49Z",
          "peakLocalDateTime": "2026-08-27T23:12:49-05:00",
          "startLocalDateTime": "2026-08-27T20:23:36-05:00",
          "endLocalDateTime": "2026-08-28T02:02:02-05:00",
          "visibility": "visible",
          "visibilityLabel": "Visible from this location"
        }
      ]
    },
    "engine": {
      "name": "Astronomy Engine",
      "version": "2.1.19",
      "sourceCommit": "865d3da7d8112bbc7911238052c6af4aaf877181"
    }
  },
  "warnings": []
}
```
