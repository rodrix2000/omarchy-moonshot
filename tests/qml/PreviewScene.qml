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
  color: "#0d1117"
  flags: Qt.FramelessWindowHint

  readonly property string outputPath: String(Qt.resolvedUrl("../../preview.png")).replace(/^file:\/\//, "")

  Item {
    id: scene
    anchors.fill: parent

    // Background desktop
    Rectangle {
      anchors.fill: parent
      gradient: Gradient {
        GradientStop { position: 0.0; color: "#090d13" }
        GradientStop { position: 1.0; color: "#161b22" }
      }
    }

    // Top Omarchy Bar Simulation
    Rectangle {
      id: barMock
      width: parent.width
      height: 32
      color: "#f2161b22"
      border.color: "#1affffff"
      border.width: 1

      Row {
        anchors.left: parent.left
        anchors.leftMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        spacing: 12

        Text {
          text: "1 · 2 · 3"
          font.family: Style.font.family
          font.pixelSize: 12
          color: "#8b949e"
        }
      }

      Row {
        anchors.right: parent.right
        anchors.rightMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        spacing: 16

        // Moonshot Bar Widget Pill
        Rectangle {
          width: 80
          height: 24
          radius: 12
          color: "#26388bfd"
          border.color: "#66388bfd"
          border.width: 1
          anchors.verticalCenter: parent.verticalCenter

          Row {
            anchors.centerIn: parent
            spacing: 6
            MoonDisk {
              size: 16
              phaseAngleDeg: 122.5
              illumination: 0.77
              direction: "waxing"
              hero: false
            }
            Text {
              text: "77%"
              font.family: Style.font.family
              font.pixelSize: 11
              font.bold: true
              color: "#e6edf3"
            }
          }
        }

        Text {
          text: "19:30"
          font.family: Style.font.family
          font.pixelSize: 12
          font.bold: true
          color: "#e6edf3"
          anchors.verticalCenter: parent.verticalCenter
        }
      }
    }

    // Moonshot Panel Display Mockup
    Rectangle {
      id: panelMock
      width: 380
      height: 540
      anchors.top: barMock.bottom
      anchors.topMargin: 12
      anchors.right: parent.right
      anchors.rightMargin: 60
      radius: 12
      color: "#161b22"
      border.color: "#26ffffff"
      border.width: 1

      Column {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 14

        // 1. Header
        Item {
          width: parent.width
          height: 36
          Column {
            anchors.left: parent.left
            spacing: 2
            Text {
              text: "MOONSHOT"
              font.family: Style.font.family
              font.pixelSize: 10
              font.bold: true
              color: "#58a6ff"
            }
            Text {
              text: "Tonight · Saturday, August 22"
              font.family: Style.font.family
              font.pixelSize: 12
              color: "#e6edf3"
            }
          }
          Column {
            anchors.right: parent.right
            spacing: 2
                        Text {
              text: "Celina, Texas"
              font.family: Style.font.family
              font.pixelSize: 11
              color: "#e6edf3"
            }
            Text {
              text: "north-up chart"
              font.family: Style.font.family
              font.pixelSize: 10
              color: "#8b949e"
            }
          }
        }

        // 2. Hero Moon Disk & Metrics
        Column {
          width: parent.width
          spacing: 8
          
          MoonDisk {
            anchors.horizontalCenter: parent.horizontalCenter
            size: 140
            phaseAngleDeg: 122.5
            illumination: 0.77
            direction: "waxing"
            hero: true
            renderMode: "realistic"
          }

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Waxing Gibbous · 77%"
            font.family: Style.font.family
            font.pixelSize: 16
            font.bold: true
            color: "#e6edf3"
          }

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Waxing · 10.3 days old"
            font.family: Style.font.family
            font.pixelSize: 12
            color: "#8b949e"
          }
        }

        // 3. Observer Rise / Set Card
        Rectangle {
          width: parent.width
          height: 80
          radius: 8
          color: "#0affffff"
          border.color: "#14ffffff"
          border.width: 1

          Column {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 6

            Row {
              width: parent.width
              Column {
                width: parent.width / 2
                spacing: 2
                Text { text: "Moonrise"; font.family: Style.font.family; font.pixelSize: 10; color: "#8b949e" }
                Text { text: "4:42 PM"; font.family: Style.font.family; font.pixelSize: 14; font.bold: true; color: "#e6edf3" }
              }
              Column {
                width: parent.width / 2
                spacing: 2
                Text { text: "Moonset"; font.family: Style.font.family; font.pixelSize: 10; color: "#8b949e" }
                Text { text: "1:27 AM"; font.family: Style.font.family; font.pixelSize: 14; font.bold: true; color: "#e6edf3" }
              }
            }

            Text {
              text: "▲ Above horizon · Alt 28.0°"
              font.family: Style.font.family
              font.pixelSize: 10
              color: "#58a6ff"
            }
          }
        }

        // 4. Upcoming Phases
        Column {
          width: parent.width
          spacing: 6

          Text {
            text: "UPCOMING PHASES"
            font.family: Style.font.family
            font.pixelSize: 10
            font.bold: true
            color: "#8b949e"
          }

          Row {
            width: parent.width
            Text { width: 120; text: "Full Moon"; font.family: Style.font.family; font.pixelSize: 11; font.bold: true; color: "#e6edf3" }
            Text { text: "Thu Aug 27 · 11:19 PM"; font.family: Style.font.family; font.pixelSize: 11; color: "#8b949e" }
          }
          Row {
            width: parent.width
            Text { width: 120; text: "Last Quarter"; font.family: Style.font.family; font.pixelSize: 11; font.bold: true; color: "#e6edf3" }
            Text { text: "Fri Sep 04 · 2:51 AM"; font.family: Style.font.family; font.pixelSize: 11; color: "#8b949e" }
          }
        }

        // 5. Date Controls Mockup
        Item {
          width: parent.width
          height: 28

          Row {
            anchors.left: parent.left
            spacing: 8
            Rectangle { width: 70; height: 26; radius: 6; color: "#14ffffff"; Text { anchors.centerIn: parent; text: "‹ Prev"; font.family: Style.font.family; font.pixelSize: 11; color: "#e6edf3" } }
            Rectangle { width: 70; height: 26; radius: 6; color: "#40388bfd"; border.color: "#58a6ff"; Text { anchors.centerIn: parent; text: "Today"; font.family: Style.font.family; font.pixelSize: 11; font.bold: true; color: "#e6edf3" } }
            Rectangle { width: 70; height: 26; radius: 6; color: "#14ffffff"; Text { anchors.centerIn: parent; text: "Next ›"; font.family: Style.font.family; font.pixelSize: 11; color: "#e6edf3" } }
          }

          Row {
            anchors.right: parent.right
            spacing: 8
            anchors.verticalCenter: parent.verticalCenter
            Text { text: "🌕"; font.pixelSize: 14 }
            Text { text: "🌑"; font.pixelSize: 14 }
          }
        }

        // 6. Footer
        Item {
          width: parent.width
          height: 24

          Text {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: "Updated just now"
            font.family: Style.font.family
            font.pixelSize: 10
            color: "#8b949e"
          }
          Rectangle {
            anchors.right: parent.right
            width: 84
            height: 22
            radius: 4
            color: "#14ffffff"
            Text { anchors.centerIn: parent; text: "📍 Location"; font.family: Style.font.family; font.pixelSize: 10; color: "#e6edf3" }
          }
        }
      }
    }
  }

  Timer {
    id: renderTimer
    interval: 500
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
