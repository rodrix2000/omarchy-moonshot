pragma ComponentBehavior: Bound

import QtQuick
import qs.Commons
import qs.Ui as Ui

Item {
  id: root

  required property var model
  property var settings: ({})

  signal eventRequested(string instantUtc, string localDateTime)
  signal locationRequested()

  implicitHeight: eclipseColumn.implicitHeight

  Accessible.role: Accessible.Pane
  Accessible.name: "Upcoming eclipse tracking"

  readonly property var eclipses: root.model && Array.isArray(root.model.upcomingEclipses)
    ? root.model.upcomingEclipses : []

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

  function formatTime(value) {
    var date = root.parsedDate(value)
    return date ? Qt.formatTime(date, root.timePattern()) : "—"
  }

  function formatDate(value) {
    var date = root.parsedDate(value)
    return date ? date.toLocaleDateString(Qt.locale(), "dddd, MMMM d, yyyy") : "Date unavailable"
  }

  function daysLabel(days) {
    var rounded = Math.ceil(Number(days || 0))
    if (rounded <= 0) return "Today"
    if (rounded === 1) return "Tomorrow"
    return "In " + rounded + " days"
  }

  Column {
    id: eclipseColumn
    width: parent.width
    spacing: Style.spacing.rowGap

    Item {
      width: parent.width
      height: Math.max(eclipseTitle.implicitHeight, engineLabel.implicitHeight)

      Column {
        id: eclipseTitle
        anchors.left: parent.left
        anchors.right: engineLabel.left
        anchors.rightMargin: Style.spacing.panelGap
        spacing: Style.space(2)

        Text {
          text: "Upcoming eclipses"
          color: Color.popups.text
          font.family: Style.font.family
          font.pixelSize: Style.font.heading
          font.bold: true
        }
        Text {
          width: parent.width
          text: root.model.locationConfigured
            ? "Visibility for " + root.model.locationLabel
            : "Global events · add a location for visibility"
          color: Color.muted
          elide: Text.ElideRight
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
        }
      }

      Text {
        id: engineLabel
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        text: "OFFLINE · PRECISE"
        color: Color.accent
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
        font.bold: true
      }
    }

    Repeater {
      model: root.eclipses

      delegate: Ui.BorderSurface {
        id: eclipseCard
        required property var modelData
        width: parent.width
        height: Style.space(146)
        radius: Style.cornerRadius
        activeFocusOnTab: true
        color: eclipsePointer.pressed
          ? Style.pressedFillFor(Color.popups.text, Color.accent)
          : eclipsePointer.containsMouse
            ? Style.hoverFillFor(Color.popups.text, Color.accent)
            : Util.alpha(Color.popups.text, 0.025)
        borderSpec: activeFocus
          ? Border.controlSpec("focus", Color.popups.text, Color.accent)
          : Border.surfaceSpec("popups", "border", Color.popups.border, 1)

        Accessible.role: Accessible.Button
        Accessible.name: modelData.title + ", "
          + root.formatDate(modelData.peakLocalDateTime) + ", "
          + modelData.visibilityLabel

        MoonshotIcon {
          id: eclipseGlyph
          anchors.left: parent.left
          anchors.leftMargin: Style.space(14)
          anchors.top: parent.top
          anchors.topMargin: Style.space(14)
          name: eclipseCard.modelData.type === "lunar" ? "eclipse-lunar" : "eclipse-solar"
          size: Style.space(30)
          color: Color.accent
        }

        Column {
          anchors.left: eclipseGlyph.right
          anchors.leftMargin: Style.space(10)
          anchors.right: countdown.right
          anchors.rightMargin: Style.space(8)
          anchors.top: parent.top
          anchors.topMargin: Style.space(12)
          spacing: Style.space(2)

          Text {
            width: parent.width
            text: eclipseCard.modelData.title
            color: Color.popups.text
            elide: Text.ElideRight
            font.family: Style.font.family
            font.pixelSize: Style.font.body
            font.bold: true
          }
          Text {
            width: parent.width
            text: root.formatDate(eclipseCard.modelData.peakLocalDateTime)
            color: Color.muted
            elide: Text.ElideRight
            font.family: Style.font.family
            font.pixelSize: Style.font.bodySmall
          }
        }

        Text {
          id: countdown
          anchors.right: parent.right
          anchors.rightMargin: Style.space(14)
          anchors.top: parent.top
          anchors.topMargin: Style.space(14)
          text: root.daysLabel(eclipseCard.modelData.daysUntil)
          color: Color.accent
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
          font.bold: true
        }

        Row {
          id: contactRow
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.leftMargin: Style.space(14)
          anchors.rightMargin: Style.space(14)
          anchors.top: parent.top
          anchors.topMargin: Style.space(64)
          height: Style.space(34)

          Repeater {
            model: [
              { label: "Begins", value: root.formatTime(eclipseCard.modelData.startLocalDateTime) },
              { label: "Maximum", value: root.formatTime(eclipseCard.modelData.peakLocalDateTime) },
              { label: "Ends", value: root.formatTime(eclipseCard.modelData.endLocalDateTime) }
            ]

            delegate: Item {
              id: contactCell
              required property var modelData
              width: parent.width / 3
              height: parent.height

              Column {
                anchors.centerIn: parent
                spacing: Style.space(1)
                Text {
                  anchors.horizontalCenter: parent.horizontalCenter
                  text: contactCell.modelData.label
                  color: Color.muted
                  font.family: Style.font.family
                  font.pixelSize: Style.font.caption
                }
                Text {
                  anchors.horizontalCenter: parent.horizontalCenter
                  text: contactCell.modelData.value
                  color: Color.popups.text
                  font.family: Style.font.family
                  font.pixelSize: Style.font.bodySmall
                  font.bold: true
                }
              }
            }
          }
        }

        Rectangle {
          anchors.left: parent.left
          anchors.leftMargin: Style.space(14)
          anchors.bottom: parent.bottom
          anchors.bottomMargin: Style.space(12)
          width: visibilityText.implicitWidth + Style.space(16)
          height: Style.space(24)
          radius: height / 2
          color: eclipseCard.modelData.visibility === "visible"
            ? Util.alpha(Color.accent, 0.16)
            : Util.alpha(Color.popups.text, 0.055)
          border.width: 1
          border.color: eclipseCard.modelData.visibility === "visible"
            ? Util.alpha(Color.accent, 0.55) : Util.alpha(Color.popups.text, 0.14)

          Text {
            id: visibilityText
            anchors.centerIn: parent
            text: eclipseCard.modelData.visibilityLabel
            color: eclipseCard.modelData.visibility === "visible" ? Color.accent : Color.muted
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
            font.bold: eclipseCard.modelData.visibility === "visible"
          }
        }

        Text {
          anchors.right: parent.right
          anchors.rightMargin: Style.space(14)
          anchors.bottom: parent.bottom
          anchors.bottomMargin: Style.space(17)
          text: eclipseCard.modelData.obscurationPercent === null
            ? "Global maximum"
            : Math.round(eclipseCard.modelData.obscurationPercent) + "% obscuration"
          color: Color.muted
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
        }

        MouseArea {
          id: eclipsePointer
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            eclipseCard.forceActiveFocus()
            root.eventRequested(
              eclipseCard.modelData.peakUtc,
              eclipseCard.modelData.peakLocalDateTime)
          }
        }

        Keys.onReturnPressed: root.eventRequested(modelData.peakUtc, modelData.peakLocalDateTime)
        Keys.onEnterPressed: root.eventRequested(modelData.peakUtc, modelData.peakLocalDateTime)
        Keys.onSpacePressed: root.eventRequested(modelData.peakUtc, modelData.peakLocalDateTime)
      }
    }

    MoonshotButton {
      visible: !root.model.locationConfigured
      anchors.horizontalCenter: parent.horizontalCenter
      iconName: "location"
      text: "Set location for local visibility"
      tooltipText: "Configure observer location"
      onClicked: root.locationRequested()
    }

    Text {
      width: parent.width
      text: "Solar times without local visibility are global maximum times."
      visible: root.eclipses.some(function(event) {
        return event.type === "solar" && event.visibility !== "visible"
      })
      color: Color.muted
      horizontalAlignment: Text.AlignHCenter
      wrapMode: Text.WordWrap
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
    }
  }
}
