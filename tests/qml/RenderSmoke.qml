pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../"

Rectangle {
  id: root
  width: 760
  height: 420
  color: "#101315"

  Grid {
    anchors.centerIn: parent
    columns: 4
    spacing: 20

    Repeater {
      model: [0, 45, 90, 135, 180, 225, 270, 315]
      delegate: Column {
        id: phaseCell
        required property real modelData
        spacing: 6
        MoonDisk {
          size: 64
          phaseAngleDeg: phaseCell.modelData
          illumination: (1 - Math.cos(phaseCell.modelData * Math.PI / 180)) / 2
          direction: phaseCell.modelData < 180 ? "waxing" : "waning"
          hero: true
        }
        Text {
          text: phaseCell.modelData + "°"
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
