pragma ComponentBehavior: Bound

import QtQuick
import "../../"

Item {
  id: root
  width: 380
  height: 560
  property int step: 0
  property bool complete: false

  function fail(message) {
    console.error("StateSmoke:", message)
    Qt.exit(2)
  }

  MoonshotModel {
    id: model

    onDataUpdated: {
      if (root.step !== 0) return
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
      root.step = 1
      model.validateAndSaveLocation(
        "Runtime Test",
        33.2,
        -96.6,
        "America/Chicago",
        180)
    }

    onLocationSaveFinished: function(success, message) {
      if (!success) {
        root.fail("location validation failed: " + message)
        return
      }

      if (root.step === 1) {
        if (model.savedLocations.length !== 1 || !model.isActiveLocation(model.savedLocations[0])) {
          root.fail("first saved place was not retained and activated")
          return
        }
        root.step = 2
        model.validateAndSaveLocation(
          "Travel Test",
          34.0522,
          -118.2437,
          "America/Los_Angeles",
          71)
        return
      }

      if (root.step === 2) {
        if (model.savedLocations.length !== 2 || model.savedLocations[0].locationLabel !== "Travel Test") {
          root.fail("second saved place was not moved to the front")
          return
        }
        model.resetLocations()
        if (model.locationConfigured || model.savedLocations.length !== 0) {
          root.fail("reset did not clear the active and saved locations")
          return
        }
        root.step = 3
        model.validateAndSaveLocation(
          "Runtime Test",
          33.2,
          -96.6,
          "America/Chicago",
          180)
        return
      }

      if (root.step === 3) {
        root.step = 4
        model.validateAndSaveLocation(
          "Travel Test",
          34.0522,
          -118.2437,
          "America/Los_Angeles",
          71)
        return
      }

      if (root.step === 4) {
        if (model.savedLocations.length !== 2) {
          root.fail("rebuilt saved-place list has the wrong size")
          return
        }
        model.clearLocation()
        if (model.locationConfigured || model.savedLocations.length !== 2) {
          root.fail("clear active removed saved places")
          return
        }
        root.step = 5
        model.activateSavedLocation(model.savedLocations[1])
        return
      }

      if (root.step === 5) {
        if (!model.locationConfigured || model.locationLabel !== "Runtime Test"
            || model.savedLocations.length !== 2
            || model.savedLocations[0].locationLabel !== "Runtime Test") {
          root.fail("saved-place switch did not activate and reorder Home")
          return
        }
        root.complete = true
        finishTimer.start()
      }
    }
  }

  Timer {
    id: finishTimer
    interval: 500
    repeat: false
    onTriggered: {
      console.log("StateSmoke: travel presets persisted and switched OK")
      Qt.quit()
    }
  }

  Timer {
    interval: 10000
    running: true
    repeat: false
    onTriggered: {
      console.error("StateSmoke: timed out", root.step, root.complete)
      Qt.exit(3)
    }
  }
}
