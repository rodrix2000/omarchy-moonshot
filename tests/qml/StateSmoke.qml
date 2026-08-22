pragma ComponentBehavior: Bound

import QtQuick
import "../../"

Item {
  id: root
  width: 380
  height: 560
  property bool requested: false
  property bool saved: false

  MoonshotModel {
    id: model

    onDataUpdated: {
      if (root.requested) return
      if (model.validLocationRecord({
          locationConfigured: true,
          locationLabel: "Missing coordinates",
          latitude: "",
          longitude: "",
          elevationM: 0,
          timeZone: "UTC"
        })) {
        console.error("StateSmoke: empty coordinates were accepted")
        Qt.exit(4)
        return
      }
      root.requested = true
      model.validateAndSaveLocation(
        "Runtime Test",
        33.2,
        -96.6,
        "America/Chicago",
        180)
    }

    onLocationSaveFinished: function(success, message) {
      if (!success) {
        console.error("StateSmoke: location validation failed", message)
        Qt.exit(2)
        return
      }
      root.saved = true
      finishTimer.start()
    }
  }

  Timer {
    id: finishTimer
    interval: 500
    repeat: false
    onTriggered: {
      console.log("StateSmoke: validated location persisted OK")
      Qt.quit()
    }
  }

  Timer {
    interval: 6000
    running: true
    repeat: false
    onTriggered: {
      console.error("StateSmoke: timed out", root.requested, root.saved)
      Qt.exit(3)
    }
  }
}
