pragma ComponentBehavior: Bound

import QtQuick
import "../../"

Item {
  id: root
  width: 420
  height: 600

  QtObject {
    id: fakeModel
    property bool locationConfigured: true
    property string locationLabel: "Home"
    property real latitude: 33.2
    property real longitude: -96.6
    property string timeZone: "America/Chicago"
    property real elevationM: 180
    property int resetCount: 0
    property var savedLocations: [
      { locationConfigured: true, locationLabel: "Home", latitude: 33.2,
        longitude: -96.6, timeZone: "America/Chicago", elevationM: 180 },
      { locationConfigured: true, locationLabel: "Travel", latitude: 34.0522,
        longitude: -118.2437, timeZone: "America/Los_Angeles", elevationM: 71 }
    ]
    signal locationSaveFinished(bool success, string message)
    function isActiveLocation(place) { return place && place.locationLabel === locationLabel }
    function activateSavedLocation(place) {}
    function validateAndSaveLocation(label, lat, lon, tzName, elev) {}
    function clearLocation() {}
    function resetLocations() { resetCount++ }
  }

  LocationEditor {
    id: editor
    width: parent.width
    visible: true
    model: fakeModel
  }

  Timer {
    interval: 500
    running: true
    repeat: false
    onTriggered: {
      if (editor.validationError !== "") {
        console.error("LocationEditorSmoke: eager Weather error", editor.validationError)
        Qt.exit(2)
        return
      }
      editor.requestResetAll()
      if (!editor.resetAllArmed || fakeModel.resetCount !== 0) {
        console.error("LocationEditorSmoke: reset was not armed safely")
        Qt.exit(3)
        return
      }
      editor.requestResetAll()
      if (fakeModel.resetCount !== 1) {
        console.error("LocationEditorSmoke: confirmed reset was not dispatched")
        Qt.exit(4)
        return
      }
      console.log("LocationEditorSmoke: saved places and guarded reset OK")
      Qt.quit()
    }
  }
}
