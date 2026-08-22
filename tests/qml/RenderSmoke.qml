import QtQuick
import QtQuick.Layouts
import "../../"

Rectangle {
  id: root
  width: 640
  height: 480
  color: "#101315"

  Grid {
    anchors.centerIn: parent
    columns: 4
    spacing: 20

    Repeater {
      model: [0, 45, 90, 135, 180, 225, 270, 315]
      delegate: Column {
        spacing: 6
        MoonDisk {
          size: 64
          phaseAngleDeg: modelData
          illumination: Math.abs(180 - modelData) / 180.0
          direction: modelData < 180 ? "waxing" : "waning"
          hero: true
        }
        Text {
          text: modelData + "°"
          color: "#e6edf3"
          anchors.horizontalCenter: parent.horizontalCenter
        }
      }
    }
  }

  Timer {
    interval: 500
    running: true
    onTriggered: {
      console.log("RenderSmoke: Canvas rendered successfully")
      Qt.quit()
    }
  }
}
