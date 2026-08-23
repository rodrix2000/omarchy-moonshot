pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Window
import qs.Commons
import qs.Ui
import "../../"

Window {
  id: previewWindow

  width: 1280
  height: 800
  visible: true
  color: "#0b0f14"
  flags: Qt.FramelessWindowHint

  readonly property string outputPath: String(Qt.resolvedUrl("../../preview.png")).replace(/^file:\/\//, "")

  QtObject {
    id: previewModel

    property var snapshot: ({ preview: true })
    property var observation: ({
      mode: "now",
      selectedLocalDate: "2026-08-22",
      localDateTime: "2026-08-22T19:30:00-05:00"
    })
    property bool locationConfigured: true
    property string locationLabel: "Austin, Texas"
    property real phaseAngleDeg: 122.5
    property real illuminationFraction: 0.77
    property real illuminationPercent: 77
    property string phaseName: "Waxing Gibbous"
    property string direction: "waxing"
    property real ageDays: 10.3
    property var riseEvent: ({ status: "event", localDateTime: "2026-08-22T16:42:00-05:00" })
    property var setEvent: ({ status: "event", localDateTime: "2026-08-23T01:27:00-05:00" })
    property bool aboveHorizon: true
    property real altitudeDeg: 28
    property var nextMajorPhases: [
      { quarter: 2, name: "Full Moon", localDateTime: "2026-08-27T23:19:00-05:00", instantUtc: "2026-08-28T04:19:00Z" },
      { quarter: 3, name: "Last Quarter", localDateTime: "2026-09-04T02:51:00-05:00", instantUtc: "2026-09-04T07:51:00Z" }
    ]
    property bool isToday: true
    property bool loading: false
    property var lastError: null
    property bool stale: false
  }

  Item {
    id: scene
    anchors.fill: parent

    Rectangle {
      anchors.fill: parent
      gradient: Gradient {
        GradientStop { position: 0.0; color: "#080b10" }
        GradientStop { position: 0.62; color: "#101722" }
        GradientStop { position: 1.0; color: "#151b24" }
      }
    }

    // Quiet orbit motif in the desktop context; the plugin itself never
    // changes the user's wallpaper.
    Repeater {
      model: [720, 540, 360]
      delegate: Rectangle {
        required property int modelData
        width: modelData
        height: width
        x: 80 - width / 2
        y: 520 - height / 2
        radius: width / 2
        color: "transparent"
        border.width: 1
        border.color: "#0bffffff"
      }
    }

    Rectangle {
      id: barMock
      width: parent.width
      height: 32
      color: "#f20b0f14"
      border.color: "#22ffffff"
      border.width: 1

      Row {
        anchors.left: parent.left
        anchors.leftMargin: 18
        anchors.verticalCenter: parent.verticalCenter
        spacing: 18

        Text {
          text: "Moonshot"
          font.family: Style.font.family
          font.pixelSize: 12
          font.bold: true
          color: "#e8edf2"
        }
        Text {
          text: "1    2    3    4"
          font.family: Style.font.family
          font.pixelSize: 12
          color: "#8d98a5"
        }
      }

      Row {
        anchors.right: parent.right
        anchors.rightMargin: 18
        anchors.verticalCenter: parent.verticalCenter
        spacing: 18

        Rectangle {
          width: 74
          height: 24
          radius: 5
          color: "#102f81f7"
          border.color: "#643f8cff"

          Row {
            anchors.centerIn: parent
            spacing: 7
            MoonDisk {
              size: 17
              phaseAngleDeg: previewModel.phaseAngleDeg
              illumination: previewModel.illuminationFraction
              direction: previewModel.direction
              surfaceColor: barMock.color
            }
            Text {
              text: "77%"
              font.family: Style.font.family
              font.pixelSize: 11
              font.bold: true
              color: "#e8edf2"
            }
          }
        }

        Text {
          anchors.verticalCenter: parent.verticalCenter
          text: "19:30"
          font.family: Style.font.family
          font.pixelSize: 12
          font.bold: true
          color: "#e8edf2"
        }
      }
    }

    BorderSurface {
      id: panelMock
      width: 430
      height: Math.min(738, previewContent.implicitHeight + 36)
      anchors.top: barMock.bottom
      anchors.topMargin: 12
      anchors.right: parent.right
      anchors.rightMargin: 42
      radius: 10
      color: Color.popups.background
      borderSpec: Border.surfaceSpec("popups", "border", Color.popups.border, 1)

      MoonshotContent {
        id: previewContent
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 18
        model: previewModel
        settings: ({ renderMode: "realistic", reducedMotion: false, timeFormat: "12h" })
      }
    }
  }

  Timer {
    interval: 900
    running: true
    repeat: false
    onTriggered: {
      scene.grabToImage(function(result) {
        if (!result.saveToFile(previewWindow.outputPath)) {
          console.error("PREVIEW_RENDER_FAILURE", previewWindow.outputPath)
          Qt.exit(2)
          return
        }
        console.log("PREVIEW_RENDERED", previewWindow.outputPath)
        Qt.quit()
      }, Qt.size(1280, 800))
    }
  }
}
