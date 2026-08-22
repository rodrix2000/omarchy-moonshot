import QtQuick
import Quickshell.Io

Item {
  id: root

  property string helperPath: Qt.resolvedUrl("scripts/moonshot_ephemeris.py").toString().replace(/^file:\/\//, "")
  readonly property bool loading: ephemProc.running || root.activeRequest !== null || root.pendingRequest !== null
  readonly property int outputLimitBytes: 65536
  readonly property int timeoutMs: 3000

  property var lastGoodSnapshot: null
  property var lastError: null
  property int currentGeneration: 0
  property var activeRequest: null
  property var pendingRequest: null
  property bool activeTimedOut: false
  property string capturedStdout: ""
  property string capturedStderr: ""

  signal snapshotReceived(var snapshot)
  signal errorOccurred(var error)

  function requestSnapshot(options) {
    root.currentGeneration++
    var request = {
      generation: root.currentGeneration,
      requestId: "gen-" + root.currentGeneration,
      options: options || {}
    }

    if (ephemProc.running || root.activeRequest !== null) {
      // Keep only the newest intent. The active helper is allowed to exit
      // cleanly, so navigation cannot create a process storm.
      root.pendingRequest = request
      return
    }
    root.startRequest(request)
  }

  function requestCommand(request) {
    var options = request.options
    var cmd = ["python3", root.helperPath, "snapshot", "--request-id", request.requestId]

    if (options.instantUtc) cmd.push("--instant-utc", String(options.instantUtc))
    if (options.selectedDate) cmd.push("--selected-date", String(options.selectedDate))
    if (options.timeZone) cmd.push("--timezone", String(options.timeZone))
    if (options.mode) cmd.push("--mode", String(options.mode))

    if (options.latitude !== undefined && options.latitude !== null &&
        options.longitude !== undefined && options.longitude !== null) {
      cmd.push("--latitude", String(options.latitude))
      cmd.push("--longitude", String(options.longitude))
      if (options.elevationM !== undefined && options.elevationM !== null)
        cmd.push("--elevation-m", String(options.elevationM))
    }
    if (options.locationLabel) cmd.push("--location-label", String(options.locationLabel))
    return cmd
  }

  function startRequest(request) {
    root.activeRequest = request
    root.activeTimedOut = false
    root.capturedStdout = ""
    root.capturedStderr = ""
    ephemProc.command = root.requestCommand(request)
    ephemProc.running = true
    requestTimeout.restart()
  }

  function finishActiveRequest() {
    requestTimeout.stop()
    root.activeRequest = null
    root.activeTimedOut = false

    if (root.pendingRequest !== null) {
      var next = root.pendingRequest
      root.pendingRequest = null
      Qt.callLater(function() { root.startRequest(next) })
    }
  }

  function emitCurrentError(code, message) {
    root.lastError = {
      code: String(code || "HELPER_EXIT").substring(0, 64),
      message: String(message || "The lunar calculation could not be completed.").substring(0, 240)
    }
    root.errorOccurred(root.lastError)
  }

  function safeMessageForCode(code) {
    var messages = {
      INVALID_MODE: "The requested observation mode is unavailable.",
      INVALID_LOCATION: "The location label is invalid.",
      INVALID_TIME_ZONE: "The requested IANA time zone is unavailable.",
      INVALID_COORDINATES: "The location coordinates are invalid.",
      INVALID_ELEVATION: "The location elevation is invalid.",
      INVALID_INSTANT: "The observation instant is invalid.",
      INVALID_DATE: "The selected calendar date is invalid.",
      ASTRONOMY_CALCULATION: "The lunar ephemeris could not be calculated."
    }
    return messages[code] || "The lunar calculation could not be completed."
  }

  function finiteNumber(value) {
    return typeof value === "number" && isFinite(value)
  }

  function validSnapshot(data) {
    if (!data || !data.observation || !data.moon || !data.events || !data.horizon) return false
    if (typeof data.observation.selectedLocalDate !== "string" ||
        typeof data.observation.localDateTime !== "string") return false
    if (!root.finiteNumber(data.moon.phaseAngleDeg) ||
        data.moon.phaseAngleDeg < 0 || data.moon.phaseAngleDeg >= 360) return false
    if (!root.finiteNumber(data.moon.illuminationFraction) ||
        data.moon.illuminationFraction < 0 || data.moon.illuminationFraction > 1) return false
    if (!root.finiteNumber(data.moon.illuminationPercent) ||
        data.moon.illuminationPercent < 0 || data.moon.illuminationPercent > 100) return false
    if (!root.finiteNumber(data.moon.ageDays) || data.moon.ageDays < 0 || data.moon.ageDays > 40) return false
    if (typeof data.moon.phaseName !== "string" || typeof data.moon.direction !== "string") return false
    if (!data.events.rise || !data.events.set || !Array.isArray(data.events.nextMajorPhases)) return false
    return true
  }

  function handleExit(exitCode) {
    var request = root.activeRequest
    if (request === null) return

    var isCurrent = request.generation === root.currentGeneration
    var rawOut = root.capturedStdout.trim()
    var rawErr = root.capturedStderr.trim()

    if (isCurrent && root.activeTimedOut) {
      root.emitCurrentError("HELPER_TIMEOUT", "The lunar calculation took too long.")
      root.finishActiveRequest()
      return
    }

    if (isCurrent && (rawOut.length > root.outputLimitBytes || rawErr.length > root.outputLimitBytes)) {
      root.emitCurrentError("INVALID_RESPONSE", "The lunar helper returned an oversized response.")
      root.finishActiveRequest()
      return
    }

    if (isCurrent && (exitCode !== 0 || rawOut === "")) {
      var errCode = "HELPER_EXIT"
      var errMessage = "The lunar calculation could not be completed."
      try {
        var parsedErr = rawErr === "" ? null : JSON.parse(rawErr)
        if (parsedErr && parsedErr.error) {
          errCode = String(parsedErr.error.code || errCode).substring(0, 64)
          errMessage = root.safeMessageForCode(errCode)
        }
      } catch (e) {
        // Raw stderr may contain a traceback or private values. Never expose it.
      }
      root.emitCurrentError(errCode, errMessage)
      root.finishActiveRequest()
      return
    }

    if (isCurrent) {
      try {
        var doc = JSON.parse(rawOut)
        if (!doc || doc.protocolVersion !== 1 || doc.status !== "ok" ||
            doc.requestId !== request.requestId || !root.validSnapshot(doc.data)) {
          root.emitCurrentError("INVALID_RESPONSE", "The lunar helper returned an invalid response.")
        } else {
          root.lastError = null
          root.lastGoodSnapshot = doc.data
          root.snapshotReceived(doc.data)
        }
      } catch (e) {
        root.emitCurrentError("PROTOCOL_PARSE", "The lunar helper response could not be parsed.")
      }
    }

    root.finishActiveRequest()
  }

  Timer {
    id: requestTimeout
    interval: root.timeoutMs
    repeat: false
    onTriggered: {
      if (!ephemProc.running || root.activeRequest === null) return
      root.activeTimedOut = true
      ephemProc.running = false
    }
  }

  Process {
    id: ephemProc
    command: []

    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.capturedStdout = String(text || "")
    }

    stderr: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.capturedStderr = String(text || "")
    }

    onExited: function(exitCode) {
      // Let the collectors publish their final text before parsing it.
      Qt.callLater(function() { root.handleExit(exitCode) })
    }
  }
}
