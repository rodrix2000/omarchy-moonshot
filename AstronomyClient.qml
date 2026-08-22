import QtQuick
import Quickshell
import Quickshell.Io

Item {
  id: root

  property string helperPath: Qt.resolvedUrl("scripts/moonshot_ephemeris.py").toString().replace(/^file:\/\//, "")
  property bool loading: false
  property var lastGoodSnapshot: null
  property var lastError: null
  property int currentGeneration: 0
  property int pendingGeneration: 0

  signal snapshotReceived(var snapshot)
  signal errorOccurred(var error)

  property string capturedStdout: ""
  property string capturedStderr: ""

  function requestSnapshot(options) {
    options = options || {}
    currentGeneration++
    var genId = "gen-" + currentGeneration
    pendingGeneration = currentGeneration

    var cmd = ["python3", root.helperPath, "snapshot", "--request-id", genId]

    if (options.instantUtc) {
      cmd.push("--instant-utc", String(options.instantUtc))
    }
    if (options.selectedDate) {
      cmd.push("--selected-date", String(options.selectedDate))
    }
    if (options.timeZone) {
      cmd.push("--timezone", String(options.timeZone))
    }
    if (options.latitude !== undefined && options.latitude !== null &&
        options.longitude !== undefined && options.longitude !== null) {
      cmd.push("--latitude", String(options.latitude))
      cmd.push("--longitude", String(options.longitude))
      if (options.elevationM !== undefined && options.elevationM !== null) {
        cmd.push("--elevation-m", String(options.elevationM))
      }
    }
    if (options.locationLabel) {
      cmd.push("--location-label", String(options.locationLabel))
    }

    root.capturedStdout = ""
    root.capturedStderr = ""
    root.loading = true

    if (ephemProc.running) {
      ephemProc.running = false
    }

    ephemProc.command = cmd
    ephemProc.running = true
  }

  Process {
    id: ephemProc
    command: []
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        root.capturedStdout = String(text || "")
      }
    }
    stderr: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        root.capturedStderr = String(text || "")
      }
    }
    onExited: function(exitCode) {
      root.loading = false
      var rawOut = root.capturedStdout.trim()

      if (exitCode !== 0 || rawOut === "") {
        var errCode = "HELPER_EXIT"
        var errMsg = "Ephemeris calculation failed with exit code " + exitCode
        try {
          if (root.capturedStderr.trim()) {
            var parsedErr = JSON.parse(root.capturedStderr.trim())
            if (parsedErr && parsedErr.error) {
              errCode = parsedErr.error.code || errCode
              errMsg = parsedErr.error.message || errMsg
            }
          }
        } catch (e) {
          if (root.capturedStderr.trim()) errMsg = root.capturedStderr.trim()
        }

        root.lastError = { code: errCode, message: errMsg }
        root.errorOccurred(root.lastError)
        return
      }

      try {
        var doc = JSON.parse(rawOut)
        if (!doc || doc.protocolVersion !== 1 || doc.status !== "ok" || !doc.data) {
          root.lastError = {
            code: "PROTOCOL_PARSE",
            message: "Malformed ephemeris response structure."
          }
          root.errorOccurred(root.lastError)
          return
        }

        // Validate generation match
        var reqGen = doc.requestId || ""
        if (reqGen && reqGen !== "gen-" + root.pendingGeneration) {
          // Stale response from earlier generation; ignore
          return
        }

        root.lastError = null
        root.lastGoodSnapshot = doc.data
        root.snapshotReceived(doc.data)
      } catch (err) {
        root.lastError = {
          code: "PROTOCOL_PARSE",
          message: "Failed to parse JSON ephemeris output: " + err
        }
        root.errorOccurred(root.lastError)
      }
    }
  }
}
