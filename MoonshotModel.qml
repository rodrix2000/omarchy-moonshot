import QtQuick
import Quickshell
import Quickshell.Io

Item {
  id: root

  property var settings: ({})

  // Observation selection. Calendar browsing stays independent of the
  // machine's current UTC offset, and event jumps retain their exact instant.
  property string selectionMode: "now"
  property string selectedLocalDate: ""
  property string selectedInstantUtc: ""
  readonly property bool isToday: root.selectionMode === "now"

  // Location configuration.
  property bool locationConfigured: false
  property string locationLabel: ""
  property var latitude: null
  property var longitude: null
  property real elevationM: 0.0
  property string timeZone: ""
  property var pendingLocation: null
  readonly property int savedLocationLimit: 6
  property var savedLocations: []

  // Ephemeris snapshot (last-good).
  property var snapshot: null
  readonly property var observation: snapshot ? snapshot.observation : null
  readonly property var moon: snapshot ? snapshot.moon : null
  readonly property var horizon: snapshot ? snapshot.horizon : null
  readonly property var events: snapshot ? snapshot.events : null
  readonly property var nextMajorPhases: events && events.nextMajorPhases ? events.nextMajorPhases : []

  readonly property real phaseAngleDeg: moon ? moon.phaseAngleDeg : 0.0
  readonly property string phaseName: moon ? moon.phaseName : "Loading…"
  readonly property string direction: moon ? moon.direction : "neutral"
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

  readonly property string homeDir: Quickshell.env("HOME") || ""
  readonly property string stateHome: Quickshell.env("XDG_STATE_HOME")
    || (root.homeDir !== "" ? root.homeDir + "/.local/state" : "")
  readonly property string settingsStateDir: root.stateHome !== "" ? root.stateHome + "/moonshot" : ""
  readonly property string settingsStatePath: root.settingsStateDir !== ""
    ? root.settingsStateDir + "/settings-v1.json" : ""
  property bool settingsLoaded: false

  signal dataUpdated()
  signal locationSaveFinished(bool success, string message)

  AstronomyClient {
    id: client

    onSnapshotReceived: function(data) {
      if (root.pendingLocation !== null) {
        var accepted = root.pendingLocation
        root.pendingLocation = null
        root.applyLocation(accepted)
        root.savedLocations = root.locationListWith(accepted, root.savedLocations)
        root.saveSettingsState()
        root.locationSaveFinished(true, "")
      }

      root.snapshot = data
      if (data.observation && data.observation.selectedLocalDate)
        root.selectedLocalDate = data.observation.selectedLocalDate
      root.dataUpdated()
    }

    onErrorOccurred: function(error) {
      if (root.pendingLocation === null) return
      root.pendingLocation = null
      root.locationSaveFinished(false, error && error.message
        ? error.message : "The location could not be validated.")
    }
  }

  function finiteNumber(value) {
    if (value === null || value === undefined) return false
    if (typeof value === "string" && value.trim() === "") return false
    var n = Number(value)
    return isFinite(n)
  }

  function validLocationRecord(record) {
    if (!record || record.locationConfigured !== true) return false
    if (!root.finiteNumber(record.latitude) || Number(record.latitude) < -90 || Number(record.latitude) > 90) return false
    if (!root.finiteNumber(record.longitude) || Number(record.longitude) < -180 || Number(record.longitude) > 180) return false
    if (!root.finiteNumber(record.elevationM) || Number(record.elevationM) < -500 || Number(record.elevationM) > 9000) return false
    if (record.locationLabel !== undefined && String(record.locationLabel).length > 128) return false
    return typeof record.timeZone === "string" && record.timeZone.trim() !== ""
  }

  function normalizedLocationRecord(record) {
    if (!root.validLocationRecord(record)) return null
    var latitudeValue = Number(record.latitude)
    var longitudeValue = Number(record.longitude)
    var label = String(record.locationLabel || "").trim().substring(0, 128)
    return {
      locationConfigured: true,
      locationLabel: label !== "" ? label
        : latitudeValue.toFixed(2) + ", " + longitudeValue.toFixed(2),
      latitude: latitudeValue,
      longitude: longitudeValue,
      timeZone: String(record.timeZone).trim(),
      elevationM: Number(record.elevationM || 0)
    }
  }

  function sameLocation(first, second) {
    var a = root.normalizedLocationRecord(first)
    var b = root.normalizedLocationRecord(second)
    if (a === null || b === null) return false
    return Math.abs(a.latitude - b.latitude) < 0.000001
      && Math.abs(a.longitude - b.longitude) < 0.000001
      && a.timeZone === b.timeZone
  }

  function normalizedSavedLocations(records) {
    if (!Array.isArray(records)) return []
    var result = []
    for (var i = 0; i < records.length && result.length < root.savedLocationLimit; i++) {
      var candidate = root.normalizedLocationRecord(records[i])
      if (candidate === null) continue
      var duplicate = false
      for (var j = 0; j < result.length; j++) {
        if (root.sameLocation(candidate, result[j])) {
          duplicate = true
          break
        }
      }
      if (!duplicate) result.push(candidate)
    }
    return result
  }

  function locationListWith(record, records) {
    var candidate = root.normalizedLocationRecord(record)
    if (candidate === null) return root.normalizedSavedLocations(records)
    var result = [candidate]
    var existing = root.normalizedSavedLocations(records)
    for (var i = 0; i < existing.length && result.length < root.savedLocationLimit; i++) {
      if (!root.sameLocation(candidate, existing[i])) result.push(existing[i])
    }
    return result
  }

  function isActiveLocation(record) {
    if (!root.locationConfigured) return false
    return root.sameLocation(record, {
      locationConfigured: true,
      locationLabel: root.locationLabel,
      latitude: root.latitude,
      longitude: root.longitude,
      timeZone: root.timeZone,
      elevationM: root.elevationM
    })
  }

  function applyLocation(record) {
    var normalized = root.normalizedLocationRecord(record)
    root.locationConfigured = normalized !== null
    root.locationLabel = normalized ? normalized.locationLabel : ""
    root.latitude = normalized ? normalized.latitude : null
    root.longitude = normalized ? normalized.longitude : null
    root.timeZone = normalized ? normalized.timeZone : ""
    root.elevationM = normalized ? normalized.elevationM : 0.0
  }

  function hydrateSettings(raw) {
    if (root.settingsLoaded) return

    var persisted = null
    if (String(raw || "").trim() !== "") {
      try {
        var parsed = JSON.parse(String(raw))
        if (parsed && parsed.version === 1) persisted = parsed
      } catch (e) {
        // Corrupt state is treated as unconfigured; no private values are logged.
      }
    }

    root.savedLocations = root.normalizedSavedLocations(
      persisted && persisted.savedLocations ? persisted.savedLocations : [])

    var record = null
    if (root.settings && root.settings.latitude !== undefined && root.settings.latitude !== null) {
      record = {
        locationConfigured: true,
        locationLabel: root.settings.locationLabel || "Custom location",
        latitude: root.settings.latitude,
        longitude: root.settings.longitude,
        timeZone: root.settings.timeZone || "",
        elevationM: root.settings.elevationM || 0
      }
    } else if (persisted) record = persisted

    if (root.validLocationRecord(record)) {
      root.applyLocation(record)
      root.savedLocations = root.locationListWith(record, root.savedLocations)
    } else {
      root.applyLocation({ locationConfigured: false })
    }

    root.settingsLoaded = true
    root.refresh()
  }

  function requestOptions(locationOverride) {
    var location = locationOverride || {
      locationConfigured: root.locationConfigured,
      locationLabel: root.locationLabel,
      latitude: root.latitude,
      longitude: root.longitude,
      timeZone: root.timeZone,
      elevationM: root.elevationM
    }
    var options = {
      mode: root.selectionMode,
      timeZone: location.timeZone || undefined,
      latitude: location.locationConfigured ? location.latitude : null,
      longitude: location.locationConfigured ? location.longitude : null,
      elevationM: location.locationConfigured ? location.elevationM : 0.0,
      locationLabel: location.locationConfigured ? location.locationLabel : ""
    }

    if (root.selectionMode === "browse") options.selectedDate = root.selectedLocalDate
    else if (root.selectionMode === "event") {
      options.selectedDate = root.selectedLocalDate
      options.instantUtc = root.selectedInstantUtc
    }
    return options
  }

  function refresh() {
    if (!root.settingsLoaded) return
    client.requestSnapshot(root.requestOptions(null))
  }

  function isoDatePlusDays(isoDate, delta) {
    var match = /^(\d{4})-(\d{2})-(\d{2})$/.exec(String(isoDate || ""))
    if (!match) return Qt.formatDate(new Date(), "yyyy-MM-dd")
    var date = new Date(Date.UTC(Number(match[1]), Number(match[2]) - 1, Number(match[3])))
    date.setUTCDate(date.getUTCDate() + delta)
    return date.getUTCFullYear() + "-" + String(date.getUTCMonth() + 1).padStart(2, "0")
      + "-" + String(date.getUTCDate()).padStart(2, "0")
  }

  function stepDate(delta) {
    var baseDate = root.selectedLocalDate || (root.observation ? root.observation.selectedLocalDate : "")
    root.selectedLocalDate = root.isoDatePlusDays(baseDate, delta)
    root.selectedInstantUtc = ""
    root.selectionMode = "browse"
    root.refresh()
  }

  function jumpToToday() {
    root.selectionMode = "now"
    root.selectedLocalDate = ""
    root.selectedInstantUtc = ""
    root.refresh()
  }

  function jumpToPhase(quarterNum) {
    for (var i = 0; i < root.nextMajorPhases.length; i++) {
      var event = root.nextMajorPhases[i]
      if (event.quarter !== quarterNum || !event.instantUtc || !event.localDateTime) continue
      root.selectionMode = "event"
      root.selectedLocalDate = String(event.localDateTime).split("T")[0]
      root.selectedInstantUtc = String(event.instantUtc)
      root.refresh()
      return
    }
  }

  function validateAndSaveLocation(label, lat, lon, tzName, elev) {
    var candidate = {
      locationConfigured: true,
      locationLabel: String(label || "").trim().substring(0, 128),
      latitude: Number(lat),
      longitude: Number(lon),
      timeZone: String(tzName || "").trim(),
      elevationM: Number(elev || 0)
    }
    if (!root.validLocationRecord(candidate)) {
      root.locationSaveFinished(false, "Enter valid coordinates, elevation, and an IANA time zone.")
      return
    }
    if (candidate.locationLabel === "")
      candidate.locationLabel = candidate.latitude.toFixed(2) + ", " + candidate.longitude.toFixed(2)

    root.pendingLocation = candidate
    client.requestSnapshot(root.requestOptions(candidate))
  }

  function activateSavedLocation(record) {
    var candidate = root.normalizedLocationRecord(record)
    if (candidate === null) {
      root.locationSaveFinished(false, "This saved place is no longer valid.")
      return
    }
    root.validateAndSaveLocation(
      candidate.locationLabel,
      candidate.latitude,
      candidate.longitude,
      candidate.timeZone,
      candidate.elevationM)
  }

  function clearLocation() {
    root.pendingLocation = null
    root.applyLocation({ locationConfigured: false })
    root.saveSettingsState()
    root.refresh()
  }

  function resetLocations() {
    root.pendingLocation = null
    root.savedLocations = []
    root.applyLocation({ locationConfigured: false })
    root.saveSettingsState()
    root.refresh()
  }

  function saveSettingsState() {
    if (!root.settingsLoaded || root.settingsStatePath === "") return
    var stateData = {
      version: 1,
      locationConfigured: root.locationConfigured,
      locationLabel: root.locationLabel,
      latitude: root.latitude,
      longitude: root.longitude,
      timeZone: root.timeZone,
      elevationM: root.elevationM,
      savedLocations: root.normalizedSavedLocations(root.savedLocations)
    }
    settingsFile.setText(JSON.stringify(stateData, null, 2) + "\n")
    permissionsTimer.restart()
  }

  FileView {
    id: settingsFile
    path: root.settingsStatePath
    atomicWrites: true
    watchChanges: false
    printErrors: false
    onLoaded: root.hydrateSettings(text())
    onLoadFailed: root.hydrateSettings("")
  }

  Process {
    id: ensureStateDir
    command: ["install", "-d", "-m", "700", root.settingsStateDir]
    onExited: settingsFile.reload()
  }

  Timer {
    id: permissionsTimer
    interval: 120
    repeat: false
    onTriggered: {
      statePermissions.command = ["chmod", "600", root.settingsStatePath]
      statePermissions.running = true
    }
  }

  Process {
    id: statePermissions
    command: []
  }

  Timer {
    interval: Math.max(5, (root.settings && root.settings.refreshMinutes
      ? root.settings.refreshMinutes : 15)) * 60 * 1000
    running: root.settingsLoaded
    repeat: true
    onTriggered: if (root.isToday) root.refresh()
  }

  Component.onCompleted: {
    if (root.settingsStateDir !== "") ensureStateDir.running = true
    else root.hydrateSettings("")
  }
}
