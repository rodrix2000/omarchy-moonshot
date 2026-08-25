pragma ComponentBehavior: Bound

import QtQuick
import qs.Commons
import qs.Ui as Ui

Item {
  id: root

  required property var model
  property var settings: ({})

  signal dateRequested(string isoDate)
  signal previousMonthRequested()
  signal nextMonthRequested()

  implicitHeight: calendarColumn.implicitHeight

  Accessible.role: Accessible.Pane
  Accessible.name: "Lunar calendar"

  readonly property var calendar: root.model && root.model.lunarCalendar
    ? root.model.lunarCalendar : null

  function setting(name, fallback) {
    var value = root.settings ? root.settings[name] : undefined
    return value === undefined || value === null ? fallback : value
  }

  function dayForIndex(index) {
    if (!root.calendar || !Array.isArray(root.calendar.days)) return null
    var dayIndex = index - Number(root.calendar.firstWeekday || 0)
    return dayIndex >= 0 && dayIndex < root.calendar.days.length
      ? root.calendar.days[dayIndex] : null
  }

  function monthLabel() {
    if (!root.calendar) return "Lunar calendar"
    var date = new Date(Number(root.calendar.year), Number(root.calendar.month) - 1, 1)
    return date.toLocaleDateString(Qt.locale(), "MMMM yyyy")
  }

  function accessibleDay(day) {
    if (!day) return "Empty calendar cell"
    var major = day.majorPhase ? ", " + day.majorPhase.name : ""
    return day.date + ", " + day.phaseName + ", "
      + Math.round(day.illuminationPercent) + " percent illuminated" + major
  }

  Column {
    id: calendarColumn
    width: parent.width
    spacing: Style.spacing.rowGap

    Item {
      width: parent.width
      height: Style.spacing.controlHeight

      MoonshotButton {
        anchors.left: parent.left
        width: Style.space(42)
        height: parent.height
        iconName: "chevron-left"
        tooltipText: "Previous month"
        onClicked: root.previousMonthRequested()
      }

      Column {
        anchors.centerIn: parent
        spacing: Style.space(1)

        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          text: root.monthLabel()
          color: Color.popups.text
          font.family: Style.font.family
          font.pixelSize: Style.font.heading
          font.bold: true
        }

        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          text: "Phase at 9:00 PM local"
          color: Color.muted
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
        }
      }

      MoonshotButton {
        anchors.right: parent.right
        width: Style.space(42)
        height: parent.height
        iconName: "chevron-right"
        tooltipText: "Next month"
        onClicked: root.nextMonthRequested()
      }
    }

    Row {
      width: parent.width
      height: Style.space(18)

      Repeater {
        model: ["MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"]

        delegate: Text {
          required property string modelData
          width: parent.width / 7
          text: modelData
          color: Color.muted
          horizontalAlignment: Text.AlignHCenter
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
          font.bold: true
        }
      }
    }

    Grid {
      id: dayGrid
      width: parent.width
      columns: 7
      columnSpacing: Style.space(4)
      rowSpacing: Style.space(4)
      readonly property real cellWidth: (width - columnSpacing * 6) / 7

      Repeater {
        model: 42

        delegate: Ui.BorderSurface {
          id: dayCell

          required property int index
          readonly property var dayData: root.dayForIndex(index)
          readonly property bool selected: dayData !== null
            && root.model.selectedLocalDate === dayData.date
          readonly property bool today: dayData !== null && root.calendar
            && root.calendar.todayLocalDate === dayData.date
          readonly property bool hot: dayPointer.containsMouse
          readonly property bool showFocus: activeFocus && dayData !== null

          width: dayGrid.cellWidth
          height: Style.space(52)
          radius: Style.cornerRadius
          activeFocusOnTab: dayData !== null
          color: selected
            ? Style.selectedFillFor(Color.popups.text, Color.accent)
            : hot && dayData !== null
              ? Style.hoverFillFor(Color.popups.text, Color.accent)
              : dayData !== null
                ? Util.alpha(Color.popups.text, 0.025) : "transparent"
          borderSpec: showFocus
            ? Border.controlSpec("focus", Color.popups.text, Color.accent)
            : selected || today
              ? Border.controlSpec("selected", Color.popups.text, Color.accent)
              : dayData !== null
                ? Border.controlSpec("normal", Color.popups.text, Color.accent)
                : Border.none()

          Accessible.role: dayData !== null ? Accessible.Button : Accessible.NoRole
          Accessible.name: root.accessibleDay(dayData)

          Text {
            visible: dayCell.dayData !== null
            anchors.top: parent.top
            anchors.topMargin: Style.space(4)
            anchors.left: parent.left
            anchors.leftMargin: Style.space(5)
            text: dayCell.dayData ? dayCell.dayData.day : ""
            color: dayCell.selected || dayCell.today ? Color.accent : Color.popups.text
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
            font.bold: dayCell.selected || dayCell.today
          }

          MoonDisk {
            visible: dayCell.dayData !== null
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Style.space(4)
            size: Style.space(26)
            phaseAngleDeg: dayCell.dayData ? dayCell.dayData.phaseAngleDeg : 0
            illumination: dayCell.dayData ? dayCell.dayData.illuminationFraction : 0
            direction: dayCell.dayData ? dayCell.dayData.direction : "neutral"
            renderMode: root.setting("renderMode", "realistic")
            surfaceColor: Color.popups.background
          }

          Rectangle {
            visible: dayCell.dayData !== null && dayCell.dayData.majorPhase !== null
            anchors.top: parent.top
            anchors.topMargin: Style.space(5)
            anchors.right: parent.right
            anchors.rightMargin: Style.space(5)
            width: Style.space(5)
            height: width
            radius: width / 2
            color: Color.accent
          }

          MouseArea {
            id: dayPointer
            anchors.fill: parent
            enabled: dayCell.dayData !== null
            hoverEnabled: true
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: {
              dayCell.forceActiveFocus()
              root.dateRequested(dayCell.dayData.date)
            }
          }

          Keys.onReturnPressed: if (dayData !== null) root.dateRequested(dayData.date)
          Keys.onEnterPressed: if (dayData !== null) root.dateRequested(dayData.date)
          Keys.onSpacePressed: if (dayData !== null) root.dateRequested(dayData.date)

          Ui.PanelToolTip {
            visible: dayCell.dayData !== null && dayPointer.containsMouse
            text: dayCell.dayData ? root.accessibleDay(dayCell.dayData) : ""
            fontFamily: Style.font.family
          }
        }
      }
    }

    Row {
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: Style.space(14)

      Row {
        spacing: Style.space(5)
        Rectangle {
          anchors.verticalCenter: parent.verticalCenter
          width: Style.space(6)
          height: width
          radius: width / 2
          color: Color.accent
        }
        Text {
          text: "Major phase"
          color: Color.muted
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
        }
      }

      Text {
        text: "Select a date for full lunar details"
        color: Color.muted
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
      }
    }
  }
}
