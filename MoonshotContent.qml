pragma ComponentBehavior: Bound

import QtQuick
import qs.Commons
import qs.Ui as Ui

Item {
  id: root

  required property var model
  property var settings: ({})
  property string activeView: "tonight"

  signal previousRequested()
  signal todayRequested()
  signal nextRequested()
  signal phaseRequested(int quarter)
  signal dateRequested(string isoDate)
  signal previousMonthRequested()
  signal nextMonthRequested()
  signal eventRequested(string instantUtc, string localDateTime)
  signal locationRequested()
  signal refreshRequested()
  signal closeRequested()

  implicitWidth: Style.space(390)
  implicitHeight: contentColumn.implicitHeight

  Accessible.role: Accessible.Pane
  Accessible.name: "Moonshot lunar details"

  function setting(name, fallback) {
    var value = root.settings ? root.settings[name] : undefined
    return value === undefined || value === null ? fallback : value
  }

  function selectView(viewName) {
    if (["tonight", "calendar", "timeline", "eclipses"].indexOf(viewName) < 0) return
    root.activeView = viewName
  }

  function parsedDate(value) {
    // The helper's localDateTime is a wall-clock value for the selected
    // IANA zone. Construct from its components so a remote location is not
    // silently converted into the computer's own time zone by Date parsing.
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

  function formatTime(isoValue) {
    var date = root.parsedDate(isoValue)
    return date ? Qt.formatTime(date, root.timePattern()) : "—"
  }

  function formatLongDate(isoValue) {
    var date = root.parsedDate(isoValue)
    return date ? date.toLocaleDateString(Qt.locale(), "dddd, MMMM d") : "Today"
  }

  function formatEventDate(isoValue) {
    var date = root.parsedDate(isoValue)
    if (!date) return "Time unavailable"
    return date.toLocaleDateString(Qt.locale(), "ddd, MMM d")
      + " · " + Qt.formatTime(date, root.timePattern())
  }

  function headerDate() {
    if (!root.model.observation) return "Calculating tonight’s moon"
    var mode = root.model.observation.mode
    var dateLabel = root.formatLongDate(root.model.observation.localDateTime)
    if (mode === "now") return "Tonight · " + dateLabel
    if (mode === "event") return root.model.phaseName + " · " + dateLabel
    return dateLabel + " · 9:00 PM local"
  }

  function directionLabel() {
    if (root.model.direction === "waxing") return "Waxing"
    if (root.model.direction === "waning") return "Waning"
    return "Exact quarter"
  }

  function eventValue(event, kind) {
    if (!root.model.locationConfigured) return "Set location"
    if (!event) return "Unavailable"
    if (event.status === "event") return root.formatTime(event.localDateTime)
    if (event.status === "always-above") return "Always above"
    if (event.status === "always-below") return "Always below"
    if (event.status === "indeterminate") return "Unresolved"
    return kind === "rise" ? "No rise today" : "No set today"
  }

  function phaseAngleForQuarter(quarter) {
    return Number(quarter || 0) * 90
  }

  function phaseIlluminationForQuarter(quarter) {
    return quarter === 0 ? 0 : (quarter === 2 ? 1 : 0.5)
  }

  function statusText() {
    if (root.model.loading && !root.model.snapshot) return "Calculating lunar data…"
    if (root.model.loading) return "Updating lunar data…"
    if (root.model.lastError && !root.model.snapshot) return root.model.lastError.message
    if (root.model.stale) return "Showing last-good data · " + root.model.lastError.message
    return "Updated just now"
  }

  Column {
    id: contentColumn
    width: Math.min(parent.width, Style.space(620))
    anchors.horizontalCenter: parent.horizontalCenter
    spacing: Style.spacing.rowGap

    Item {
      width: parent.width
      height: Math.max(headerLeft.implicitHeight, headerRight.implicitHeight)

      Column {
        id: headerLeft
        anchors.left: parent.left
        anchors.right: headerRight.left
        anchors.rightMargin: Style.spacing.panelGap
        spacing: Style.space(2)

        Text {
          text: "Moonshot"
          color: Color.popups.text
          font.family: Style.font.family
          font.pixelSize: Style.font.title
          font.bold: true
        }

        Text {
          width: parent.width
          text: root.headerDate()
          color: Color.popups.text
          font.family: Style.font.family
          font.pixelSize: Style.font.bodySmall
          elide: Text.ElideRight
        }
      }

      MoonshotButton {
        id: closeButton
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: Style.spacing.controlHeight
        height: Style.spacing.controlHeight
        iconName: "close"
        tooltipText: "Close Moonshot (Escape)"
        onClicked: root.closeRequested()
      }

      Column {
        id: headerRight
        width: parent.width * 0.38
        anchors.right: closeButton.left
        anchors.rightMargin: Style.spacing.controlGap
        spacing: Style.space(2)

        Text {
          anchors.right: parent.right
          text: root.model.locationConfigured ? root.model.locationLabel : "Location not set"
          color: root.model.locationConfigured ? Color.accent : Color.muted
          font.family: Style.font.family
          font.pixelSize: Style.font.bodySmall
          elide: Text.ElideRight
          width: parent.width
          horizontalAlignment: Text.AlignRight
        }

        Text {
          anchors.right: parent.right
          text: "North-up"
          color: Color.muted
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
        }
      }
    }

    Row {
      id: viewTabs
      width: parent.width
      spacing: Style.spacing.controlGap

      Repeater {
        model: [
          { id: "tonight", label: "Tonight", icon: "full-moon", shortcut: "1" },
          { id: "calendar", label: "Calendar", icon: "calendar", shortcut: "2" },
          { id: "timeline", label: "Cycle", icon: "timeline", shortcut: "3" },
          { id: "eclipses", label: "Eclipses", icon: "eclipse-lunar", shortcut: "4" }
        ]

        delegate: MoonshotButton {
          id: viewButton
          required property var modelData
          width: (viewTabs.width - viewTabs.spacing * 3) / 4
          iconName: modelData.icon
          iconSize: Style.space(15)
          text: modelData.label
          fontSize: Style.font.caption
          selected: root.activeView === modelData.id
          tooltipText: modelData.label + " view (" + modelData.shortcut + ")"
          onClicked: root.selectView(modelData.id)
        }
      }
    }

    LunarCalendar {
      width: parent.width
      visible: root.activeView === "calendar"
      model: root.model
      settings: root.settings
      onDateRequested: function(isoDate) { root.dateRequested(isoDate) }
      onPreviousMonthRequested: root.previousMonthRequested()
      onNextMonthRequested: root.nextMonthRequested()
    }

    LunarTimeline {
      width: parent.width
      visible: root.activeView === "timeline"
      model: root.model
      settings: root.settings
      onEventRequested: function(instantUtc, localDateTime) {
        root.eventRequested(instantUtc, localDateTime)
      }
    }

    EclipseTracking {
      width: parent.width
      visible: root.activeView === "eclipses"
      model: root.model
      settings: root.settings
      onEventRequested: function(instantUtc, localDateTime) {
        root.eventRequested(instantUtc, localDateTime)
      }
      onLocationRequested: root.locationRequested()
    }

    Item {
      id: hero
      width: parent.width
      height: Style.space(244)
      visible: root.activeView === "tonight"

      Item {
        id: orbitField
        width: Style.space(196)
        height: width
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter

        Repeater {
          model: [1.0, 0.84, 0.68]
          delegate: Rectangle {
            required property real modelData
            width: orbitField.width * modelData
            height: width
            anchors.centerIn: parent
            radius: width / 2
            color: "transparent"
            border.width: 1
            border.color: Util.alpha(Color.popups.text, modelData === 1.0 ? 0.045 : 0.03)
          }
        }

        MoonDisk {
          anchors.centerIn: parent
          size: Style.space(168)
          phaseAngleDeg: root.model.phaseAngleDeg
          illumination: root.model.illuminationFraction
          direction: root.model.direction
          hero: true
          renderMode: root.setting("renderMode", "realistic")
          reducedMotion: root.setting("reducedMotion", false)
          surfaceColor: Color.popups.background
          accessibleDescription: "Moon: " + root.model.phaseName + ", "
            + Math.round(root.model.illuminationPercent) + " percent illuminated, "
            + root.model.ageDays.toFixed(1) + " days since new moon. North-up rendering."
        }
      }

      Column {
        anchors.top: orbitField.bottom
        anchors.topMargin: Style.space(-4)
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: Style.space(2)

        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          text: root.model.phaseName
          color: Color.popups.text
          font.family: Style.font.family
          font.pixelSize: Style.font.heading
          font.bold: true
        }

        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          text: Math.round(root.model.illuminationPercent) + "% illuminated"
          color: Color.popups.text
          font.family: Style.font.family
          font.pixelSize: Style.font.body
        }

        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          text: root.directionLabel() + " · " + root.model.ageDays.toFixed(1) + " days old"
          color: Color.muted
          font.family: Style.font.family
          font.pixelSize: Style.font.bodySmall
        }
      }
    }

    Rectangle {
      id: observerBand
      width: parent.width
      height: Style.space(88)
      visible: root.activeView === "tonight"
      radius: Style.cornerRadius
      color: Util.alpha(Color.popups.text, 0.035)

      Rectangle {
        anchors.top: parent.top
        width: parent.width
        height: 1
        color: Util.alpha(Color.popups.text, 0.10)
      }
      Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: 1
        color: Util.alpha(Color.popups.text, 0.10)
      }

      Row {
        anchors.fill: parent
        anchors.margins: Style.space(10)

        Repeater {
          model: [
            { icon: "rise", label: "Moonrise", value: root.eventValue(root.model.riseEvent, "rise") },
            { icon: "set", label: "Moonset", value: root.eventValue(root.model.setEvent, "set") },
            { icon: "horizon", label: root.model.locationConfigured ? "Horizon" : "Local timing",
              value: root.model.locationConfigured
                ? ((root.model.aboveHorizon ? "Above" : "Below") + " · " + root.model.altitudeDeg.toFixed(0) + "°")
                : "Add location" }
          ]

          delegate: Item {
            id: observerMetric
            required property var modelData
            required property int index
            width: parent.width / 3
            height: parent.height

            Rectangle {
              visible: observerMetric.index > 0
              anchors.left: parent.left
              anchors.verticalCenter: parent.verticalCenter
              width: 1
              height: parent.height * 0.72
              color: Util.alpha(Color.popups.text, 0.10)
            }

            Column {
              anchors.centerIn: parent
              spacing: Style.space(2)

              MoonshotIcon {
                anchors.horizontalCenter: parent.horizontalCenter
                name: observerMetric.modelData.icon
                size: Style.space(18)
                color: Color.accent
              }
              Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: observerMetric.modelData.label
                color: Color.muted
                font.family: Style.font.family
                font.pixelSize: Style.font.caption
              }
              Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: observerMetric.modelData.value
                color: Color.popups.text
                font.family: Style.font.family
                font.pixelSize: Style.font.bodySmall
                font.bold: true
              }
            }
          }
        }
      }
    }

    Column {
      width: parent.width
      spacing: Style.space(4)
      visible: root.activeView === "tonight" && root.model.nextMajorPhases.length > 0

      Ui.PanelSectionHeader {
        text: "Upcoming"
        foreground: Color.popups.text
      }

      Repeater {
        model: root.model.nextMajorPhases.slice(0, 2)
        delegate: Item {
          id: phaseEvent
          required property var modelData
          width: parent.width
          height: Style.space(34)

          MoonDisk {
            id: phaseIcon
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            size: Style.space(22)
            phaseAngleDeg: root.phaseAngleForQuarter(phaseEvent.modelData.quarter)
            illumination: root.phaseIlluminationForQuarter(phaseEvent.modelData.quarter)
            direction: phaseEvent.modelData.quarter < 2 ? "waxing" : "waning"
            hero: false
            renderMode: root.setting("renderMode", "realistic")
            surfaceColor: Color.popups.background
          }

          Text {
            anchors.left: phaseIcon.right
            anchors.leftMargin: Style.space(10)
            anchors.verticalCenter: parent.verticalCenter
            text: phaseEvent.modelData.name
            color: Color.popups.text
            font.family: Style.font.family
            font.pixelSize: Style.font.bodySmall
            font.bold: true
          }

          Text {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: root.formatEventDate(phaseEvent.modelData.localDateTime)
            color: Color.muted
            font.family: Style.font.family
            font.pixelSize: Style.font.bodySmall
          }
        }
      }
    }

    Ui.PanelSeparator {
      visible: root.activeView === "tonight"
      foreground: Color.popups.text
    }

    Item {
      width: parent.width
      height: Style.spacing.controlHeight
      visible: root.activeView === "tonight"

      MoonshotButton {
        id: previousButton
        anchors.left: parent.left
        width: Style.space(42)
        height: parent.height
        iconName: "chevron-left"
        tooltipText: "Previous local date (Left Arrow)"
        onClicked: root.previousRequested()
      }

      MoonshotButton {
        anchors.left: previousButton.right
        anchors.leftMargin: Style.spacing.controlGap
        anchors.right: nextButton.left
        anchors.rightMargin: Style.spacing.controlGap
        height: parent.height
        text: root.model.isToday ? "Today" : "Return to Today"
        selected: root.model.isToday
        tooltipText: "Return to the current instant (T)"
        onClicked: root.todayRequested()
      }

      MoonshotButton {
        id: nextButton
        anchors.right: parent.right
        width: Style.space(42)
        height: parent.height
        iconName: "chevron-right"
        tooltipText: "Next local date (Right Arrow)"
        onClicked: root.nextRequested()
      }
    }

    Row {
      width: parent.width
      spacing: Style.spacing.controlGap
      visible: root.activeView === "tonight"

      MoonshotButton {
        width: (parent.width - parent.spacing * 3) / 4
        iconName: "full-moon"
        text: "Full moon"
        fontSize: Style.font.caption
        onClicked: root.phaseRequested(2)
      }
      MoonshotButton {
        width: (parent.width - parent.spacing * 3) / 4
        iconName: "new-moon"
        text: "New moon"
        fontSize: Style.font.caption
        onClicked: root.phaseRequested(0)
      }
      MoonshotButton {
        width: (parent.width - parent.spacing * 3) / 4
        iconName: "location"
        text: "Location"
        fontSize: Style.font.caption
        tooltipText: "Configure location (Shift+L)"
        onClicked: root.locationRequested()
      }
      MoonshotButton {
        width: (parent.width - parent.spacing * 3) / 4
        iconName: "refresh"
        text: "Refresh"
        fontSize: Style.font.caption
        onClicked: root.refreshRequested()
      }
    }

    Text {
      width: parent.width
      visible: root.activeView === "tonight"
      text: root.statusText()
      wrapMode: Text.WordWrap
      horizontalAlignment: Text.AlignHCenter
      color: root.model.lastError ? Color.urgent : Color.muted
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
      Accessible.role: root.model.lastError ? Accessible.AlertMessage : Accessible.StaticText
    }
  }
}
