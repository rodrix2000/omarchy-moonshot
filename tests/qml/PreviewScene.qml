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
        Row {
          anchors.verticalCenter: parent.verticalCenter
          spacing: 4

          Repeater {
            model: [1, 2, 3, 4]

            delegate: Rectangle {
              id: workspaceChip
              required property int modelData
              width: 22
              height: 22
              radius: 4
              color: modelData === 2 ? "#24384f" : "transparent"
              border.width: modelData === 2 ? 1 : 0
              border.color: "#5d7897"

              Text {
                anchors.centerIn: parent
                text: workspaceChip.modelData
                font.family: Style.font.family
                font.pixelSize: 11
                font.bold: workspaceChip.modelData === 2
                color: workspaceChip.modelData === 2 ? "#f0f4f8" : "#8d98a5"
              }
            }
          }
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

    Rectangle {
      id: companionMock
      anchors.top: barMock.bottom
      anchors.topMargin: 12
      anchors.bottom: parent.bottom
      anchors.bottomMargin: 12
      anchors.left: parent.left
      anchors.leftMargin: 12
      width: (parent.width - 36) / 2
      radius: 6
      color: "#0c1118"
      border.width: 1
      border.color: "#3b4654"
      clip: true

      Rectangle {
        id: notesTitleBar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 38
        color: "#111821"
        border.width: 1
        border.color: "#24303d"

        Row {
          anchors.left: parent.left
          anchors.leftMargin: 14
          anchors.verticalCenter: parent.verticalCenter
          spacing: 9

          Rectangle {
            width: 15
            height: 15
            radius: 4
            color: "#d7e0e8"

            Rectangle {
              anchors.centerIn: parent
              width: 7
              height: 7
              radius: 2
              color: notesTitleBar.color
            }
          }

          Text {
            text: "Travel Notes · Austin evening"
            font.family: Style.font.family
            font.pixelSize: 12
            font.bold: true
            color: "#e2e8ef"
          }
        }

        Text {
          anchors.right: parent.right
          anchors.rightMargin: 14
          anchors.verticalCenter: parent.verticalCenter
          text: "Workspace 2"
          font.family: Style.font.family
          font.pixelSize: 10
          color: "#7f8b98"
        }
      }

      Rectangle {
        id: placesSidebar
        anchors.top: notesTitleBar.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        width: 146
        color: "#090e14"
        border.width: 1
        border.color: "#202a35"

        Column {
          anchors.top: parent.top
          anchors.topMargin: 16
          anchors.left: parent.left
          anchors.leftMargin: 12
          anchors.right: parent.right
          anchors.rightMargin: 12
          spacing: 8

          Text {
            text: "PLACES"
            font.family: Style.font.family
            font.pixelSize: 9
            font.bold: true
            color: "#687584"
          }

          Rectangle {
            width: parent.width
            height: 34
            radius: 5
            color: "#172331"
            border.width: 1
            border.color: "#304156"

            Text {
              anchors.left: parent.left
              anchors.leftMargin: 10
              anchors.verticalCenter: parent.verticalCenter
              text: "Austin, Texas"
              font.family: Style.font.family
              font.pixelSize: 11
              font.bold: true
              color: "#e4eaf0"
            }
          }

          Text {
            text: "Reykjavík"
            leftPadding: 10
            font.family: Style.font.family
            font.pixelSize: 11
            color: "#8793a0"
          }

          Text {
            text: "Tokyo"
            leftPadding: 10
            font.family: Style.font.family
            font.pixelSize: 11
            color: "#8793a0"
          }
        }

        Text {
          anchors.left: parent.left
          anchors.leftMargin: 12
          anchors.bottom: parent.bottom
          anchors.bottomMargin: 14
          text: "Austin trip · Aug 22"
          font.family: Style.font.family
          font.pixelSize: 9
          color: "#5f6b78"
        }
      }

      Item {
        anchors.top: notesTitleBar.bottom
        anchors.bottom: parent.bottom
        anchors.left: placesSidebar.right
        anchors.right: parent.right

        Column {
          anchors.top: parent.top
          anchors.topMargin: 30
          anchors.left: parent.left
          anchors.leftMargin: 30
          anchors.right: parent.right
          anchors.rightMargin: 30
          spacing: 18

          Text {
            text: "Evening sky plan"
            font.family: Style.font.family
            font.pixelSize: 20
            font.bold: true
            color: "#edf2f7"
          }

          Text {
            width: parent.width
            text: "Keep travel notes open while Moonshot tracks the local lunar view beside them on the same workspace."
            wrapMode: Text.WordWrap
            lineHeight: 1.35
            font.family: Style.font.family
            font.pixelSize: 12
            color: "#9da9b5"
          }

          Rectangle {
            width: parent.width
            height: 164
            radius: 7
            color: "#080d13"
            border.width: 1
            border.color: "#25313e"

            Column {
              anchors.fill: parent
              anchors.margins: 16
              spacing: 11

              Text {
                text: "TONIGHT IN AUSTIN"
                font.family: Style.font.family
                font.pixelSize: 9
                font.bold: true
                color: "#6f8296"
              }
              Text {
                text: "Moonrise      4:42 PM"
                font.family: Style.font.family
                font.pixelSize: 11
                color: "#c7d0da"
              }
              Text {
                text: "Moonset       1:27 AM"
                font.family: Style.font.family
                font.pixelSize: 11
                color: "#c7d0da"
              }
              Text {
                text: "Phase         Waxing Gibbous · 77%"
                font.family: Style.font.family
                font.pixelSize: 11
                color: "#c7d0da"
              }
              Text {
                text: "Horizon       Above · 28°"
                font.family: Style.font.family
                font.pixelSize: 11
                color: "#82b39a"
              }
            }
          }

          Rectangle {
            width: parent.width
            height: 76
            radius: 7
            color: "#121923"
            border.width: 1
            border.color: "#2c3947"

            Text {
              anchors.fill: parent
              anchors.margins: 14
              text: "Saved locations stay one click away in Moonshot."
              verticalAlignment: Text.AlignVCenter
              font.family: Style.font.family
              font.pixelSize: 12
              color: "#aeb9c4"
            }
          }
        }
      }
    }

    BorderSurface {
      id: panelMock
      width: companionMock.width
      anchors.top: barMock.bottom
      anchors.topMargin: 12
      anchors.bottom: parent.bottom
      anchors.bottomMargin: 12
      anchors.right: parent.right
      anchors.rightMargin: 12
      radius: 6
      color: Color.popups.background
      borderSpec: Border.surfaceSpec("popups", "border", Color.popups.border, 1)
      clip: true

      MoonshotContent {
        id: previewContent
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 16
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
