import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

Item {
  id: root

  property var settings: ({})

  // Date selection state
  property int dateOffsetDays: 0
  property string selectedLocalDate: ""
  property bool isToday: dateOffsetDays === 0

  // Location configuration state
  property bool locationConfigured: false
  property string locationLabel: ""
  property var latitude: null
  property var longitude: null
  property real elevationM: 0.0
  property string timeZone: ""

  // Ephemeris Snapshot Data (Last-good)
  property var snapshot: null
  readonly property var observation: snapshot ? snapshot.observation : null
  readonly property var moon: snapshot ? snapshot.moon : null
  readonly property var horizon: snapshot ? snapshot.horizon : null
  readonly property var events: snapshot ? snapshot.events : null
  readonly property var nextMajorPhases: events && events.nextMajorPhases ? events.nextMajorPhases : []

  // Derived metrics with safe fallbacks
  readonly property real phaseAngleDeg: moon ? moon.phaseAngleDeg : 0.0
  readonly property string phaseName: moon ? moon.phaseName : "Loading..."
  readonly property string direction: moon ? moon.direction : "waxing"
  readonly property real illuminationFraction: moon ? moon.illuminationFraction : 0.0
  readonly property real illuminationPercent: moon ? moon.illuminationPercent : 0.0
  readonly property real ageDays: moon ? moon.ageDays : 0.0

  readonly property var riseEvent: events ? events.rise : ({ status: "not-configured" })
  readonly property var setEvent: events ? events.set : ({ status: "not-configured" })
  readonly property bool aboveHorizon: horizon ? horizon.aboveHorizon : false
  readonly property real altitudeDeg: horizon ? horizon.altitudeDeg : 0.0

  readonly property bool loading: client.loading
  readonly property var lastError: client.lastError
  readonly property bool stale: lastError !== null && snapshot !== null

  signal dataUpdated()

  property string settingsStatePath: (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")) + "/moonshot/settings-v1.json"

  // Astronomy Engine Subprocess Client
  AstronomyClient {
    id: client
    onSnapshotReceived: function(data) {
      root.snapshot = data
      if (data.observation && data.observation.selectedLocalDate) {
        root.selectedLocalDate = data.observation.selectedLocalDate
      }
      root.dataUpdated()
    }
  }

  // Load persistent location settings from XDG state on init
  Component.onCompleted: {
    loadSettings()
    refresh()
  }

  function loadSettings() {
    try {
      if (settings && settings.latitude !== undefined && settings.latitude !== null) {
        root.latitude = parseFloat(settings.latitude)
        root.longitude = parseFloat(settings.longitude)
        root.locationLabel = settings.locationLabel || "Custom Location"
        root.timeZone = settings.timeZone || ""
        root.elevationM = settings.elevationM ? parseFloat(settings.elevationM) : 0.0
        root.locationConfigured = true
      }
    } catch (e) {}
  }

  function computeTargetDateString() {
    var d = new Date()
    if (root.dateOffsetDays !== 0) {
      d.setDate(d.getDate() + root.dateOffsetDays)
    }
    var yyyy = d.getFullYear()
    var mm = String(d.getMonth() + 1).padStart(2, '0')
    var dd = String(d.getDate()).padStart(2, '0')
    return yyyy + "-" + mm + "-" + dd
  }

  function refresh() {
    var targetDate = computeTargetDateString()
    var opts = {
      selectedDate: targetDate,
      timeZone: root.timeZone || undefined,
      latitude: root.locationConfigured ? root.latitude : null,
      longitude: root.locationConfigured ? root.longitude : null,
      elevationM: root.locationConfigured ? root.elevationM : 0.0,
      locationLabel: root.locationLabel
    }
    client.requestSnapshot(opts)
  }

  function stepDate(delta) {
    root.dateOffsetDays += delta
    root.refresh()
  }

  function jumpToToday() {
    root.dateOffsetDays = 0
    root.refresh()
  }

  function jumpToPhase(quarterNum) {
    if (!root.nextMajorPhases || root.nextMajorPhases.length === 0) return
    for (var i = 0; i < root.nextMajorPhases.length; i++) {
      var ev = root.nextMajorPhases[i]
      if (ev.quarter === quarterNum) {
        if (ev.localDateTime) {
          var targetDateStr = ev.localDateTime.split("T")[0]
          var now = new Date()
          var target = new Date(targetDateStr + "T12:00:00")
          var diffTime = target.getTime() - now.getTime()
          var diffDays = Math.round(diffTime / (1000 * 3600 * 24))
          root.dateOffsetDays = diffDays
          root.refresh()
        }
        break
      }
    }
  }

  function saveLocation(label, lat, lon, tzName, elev) {
    root.locationLabel = label || ""
    root.latitude = lat !== null && lat !== undefined ? parseFloat(lat) : null
    root.longitude = lon !== null && lon !== undefined ? parseFloat(lon) : null
    root.timeZone = tzName || ""
    root.elevationM = elev ? parseFloat(elev) : 0.0
    root.locationConfigured = (root.latitude !== null && root.longitude !== null)

    // Save to state file asynchronously
    saveSettingsState()
    root.refresh()
  }

  function clearLocation() {
    root.locationLabel = ""
    root.latitude = null
    root.longitude = null
    root.timeZone = ""
    root.elevationM = 0.0
    root.locationConfigured = false

    saveSettingsState()
    root.refresh()
  }

  function saveSettingsState() {
    var stateData = {
      locationConfigured: root.locationConfigured,
      locationLabel: root.locationLabel,
      latitude: root.latitude,
      longitude: root.longitude,
      timeZone: root.timeZone,
      elevationM: root.elevationM
    }
    var jsonStr = JSON.stringify(stateData, null, 2)
    var cmd = [
      "python3",
      "-c",
      "import os, sys, pathlib; p = pathlib.Path(sys.argv[1]); p.parent.mkdir(parents=True, exist_ok=True); p.write_text(sys.argv[2], encoding='utf-8')",
      root.settingsStatePath,
      jsonStr
    ]
    saveProc.command = cmd
    saveProc.running = true
  }

  Process {
    id: saveProc
    command: []
  }

  // Periodic refresh timer (15 minutes by default)
  Timer {
    interval: Math.max(5, (root.settings && root.settings.refreshMinutes ? root.settings.refreshMinutes : 15)) * 60 * 1000
    running: true
    repeat: true
    onTriggered: {
      if (root.isToday) {
        root.refresh()
      }
    }
  }
}
