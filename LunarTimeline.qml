pragma ComponentBehavior: Bound

import QtQuick
import qs.Commons
import qs.Ui as Ui

Item {
  id: root

  required property var model
  property var settings: ({})

  signal eventRequested(string instantUtc, string localDateTime)

  implicitHeight: timelineColumn.implicitHeight

  Accessible.role: Accessible.Pane
  Accessible.name: "Lunar cycle timeline"

  readonly property var cycle: root.model && root.model.lunarCycle
    ? root.model.lunarCycle : null
  readonly property var events: root.cycle && Array.isArray(root.cycle.events)
    ? root.cycle.events : []

  function setting(name, fallback) {
    var value = root.settings ? root.settings[name] : undefined
    return value === undefined || value === null ? fallback : value
  }

  function parsedDate(value) {
    var match = /^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2})(?::(\d{2}))?/.exec(String(value || ""))
    if (!match) return null
    var date = new Date(Number(match[1]), Number(match[2]) - 1, Number(match[3]),
      Number(match[4]), Number(match[5]), Number(match[6] || 0))
    return isNaN(date.getTime()) ? null : date
  }

  function timePattern() {
    var preference = root.setting("timeFormat", "locale")
    if (preference === "24h") return "HH:mm"
    if (preference === "12h") return "h:mm AP"
    return Qt.locale().timeFormat(Locale.ShortFormat)
  }

  function compactDate(value) {
    var date = root.parsedDate(value)
    if (!date) return "Time unavailable"
    return date.toLocaleDateString(Qt.locale(), "MMM d")
      + " · " + Qt.formatTime(date, root.timePattern())
  }

  function phaseAngle(quarter, index) {
    return quarter === 0 && index === root.events.length - 1 ? 360 : quarter * 90
  }

  function illumination(quarter) {
    return quarter === 0 ? 0 : (quarter === 2 ? 1 : 0.5)
  }

  Column {
    id: timelineColumn
    width: parent.width
    spacing: Style.spacing.rowGap

    Item {
      width: parent.width
      height: Math.max(cycleTitle.implicitHeight, cycleSummary.implicitHeight)

      Column {
        id: cycleTitle
        anchors.left: parent.left
        spacing: Style.space(2)

        Text {
          text: "This lunar cycle"
          color: Color.popups.text
          font.family: Style.font.family
          font.pixelSize: Style.font.heading
          font.bold: true
        }
        Text {
          text: "New moon to new moon · exact local times"
          color: Color.muted
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
        }
      }

      Column {
        id: cycleSummary
        anchors.right: parent.right
        spacing: Style.space(2)

        Text {
          anchors.right: parent.right
          text: root.cycle ? root.cycle.ageDays.toFixed(1) + " days" : "—"
          color: Color.accent
          font.family: Style.font.family
          font.pixelSize: Style.font.body
          font.bold: true
        }
        Text {
          anchors.right: parent.right
          text: root.cycle ? "of " + root.cycle.durationDays.toFixed(1) : "Calculating"
          color: Color.muted
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
        }
      }
    }

    Ui.BorderSurface {
      id: timelineSurface
      width: parent.width
      height: Style.space(142)
      radius: Style.cornerRadius
      color: Util.alpha(Color.popups.text, 0.025)
      borderSpec: Border.surfaceSpec("popups", "border", Color.popups.border, 1)

      Item {
        id: track
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: Style.space(20)
        anchors.rightMargin: Style.space(20)
        anchors.top: parent.top
        anchors.topMargin: Style.space(30)
        height: Style.space(92)

        Rectangle {
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.leftMargin: Style.space(27)
          anchors.rightMargin: Style.space(27)
          y: Style.space(29)
          height: Style.space(2)
          radius: height / 2
          color: Util.alpha(Color.popups.text, 0.14)

          Rectangle {
            width: parent.width * (root.cycle ? root.cycle.position : 0)
            height: parent.height
            radius: height / 2
            color: Color.accent
          }
        }

        Repeater {
          model: root.events

          delegate: Item {
            id: phaseMarker
            required property var modelData
            required property int index
            width: Style.space(54)
            height: track.height
            x: Number(modelData.position || 0) * (track.width - width)

            MoonDisk {
              anchors.top: parent.top
              anchors.horizontalCenter: parent.horizontalCenter
              size: Style.space(30)
              phaseAngleDeg: root.phaseAngle(phaseMarker.modelData.quarter, phaseMarker.index)
              illumination: root.illumination(phaseMarker.modelData.quarter)
              direction: phaseMarker.modelData.quarter < 2 ? "waxing" : "waning"
              renderMode: root.setting("renderMode", "realistic")
              surfaceColor: timelineSurface.color
            }

            Text {
              anchors.top: parent.top
              anchors.topMargin: Style.space(38)
              anchors.horizontalCenter: parent.horizontalCenter
              width: parent.width
              text: phaseMarker.modelData.quarter === 1 ? "First"
                : phaseMarker.modelData.quarter === 2 ? "Full"
                  : phaseMarker.modelData.quarter === 3 ? "Last" : "New"
              color: Color.popups.text
              horizontalAlignment: Text.AlignHCenter
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
              font.bold: true
            }

            Text {
              anchors.top: parent.top
              anchors.topMargin: Style.space(56)
              anchors.horizontalCenter: parent.horizontalCenter
              width: parent.width
              text: root.compactDate(phaseMarker.modelData.localDateTime).split(" · ")[0]
              color: Color.muted
              horizontalAlignment: Text.AlignHCenter
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
            }
          }
        }

        Item {
          id: selectedMarker
          width: Style.space(54)
          height: track.height
          x: (root.cycle ? root.cycle.position : 0) * (track.width - width)

          Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            y: Style.space(24)
            width: Style.space(2)
            height: Style.space(48)
            color: Color.accent
          }

          Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            y: Style.space(25)
            width: Style.space(9)
            height: width
            radius: width / 2
            color: Color.accent
            border.width: 2
            border.color: Color.popups.background
          }
        }
      }
    }

    Grid {
      id: eventGrid
      width: parent.width
      columns: width >= Style.space(520) ? 3 : 2
      columnSpacing: Style.spacing.controlGap
      rowSpacing: Style.spacing.controlGap
      readonly property real cellWidth: (width - columnSpacing * (columns - 1)) / columns

      Repeater {
        model: root.events

        delegate: Ui.BorderSurface {
          id: eventCell
          required property var modelData
          width: eventGrid.cellWidth
          height: Style.space(46)
          radius: Style.cornerRadius
          activeFocusOnTab: true
          color: eventPointer.pressed
            ? Style.pressedFillFor(Color.popups.text, Color.accent)
            : eventPointer.containsMouse
              ? Style.hoverFillFor(Color.popups.text, Color.accent) : "transparent"
          borderSpec: activeFocus
            ? Border.controlSpec("focus", Color.popups.text, Color.accent)
            : Border.controlSpec("normal", Color.popups.text, Color.accent)

          Accessible.role: Accessible.Button
          Accessible.name: modelData.name + ", " + root.compactDate(modelData.localDateTime)

          Column {
            anchors.centerIn: parent
            spacing: Style.space(1)
            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: eventCell.modelData.name
              color: Color.popups.text
              font.family: Style.font.family
              font.pixelSize: Style.font.bodySmall
              font.bold: true
            }
            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: root.compactDate(eventCell.modelData.localDateTime)
              color: Color.muted
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
            }
          }

          MouseArea {
            id: eventPointer
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              eventCell.forceActiveFocus()
              root.eventRequested(eventCell.modelData.instantUtc, eventCell.modelData.localDateTime)
            }
          }

          Keys.onReturnPressed: root.eventRequested(modelData.instantUtc, modelData.localDateTime)
          Keys.onEnterPressed: root.eventRequested(modelData.instantUtc, modelData.localDateTime)
          Keys.onSpacePressed: root.eventRequested(modelData.instantUtc, modelData.localDateTime)
        }
      }
    }

    Text {
      width: parent.width
      text: "Select any exact phase event to inspect its full lunar details."
      color: Color.muted
      horizontalAlignment: Text.AlignHCenter
      wrapMode: Text.WordWrap
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
    }
  }
}
