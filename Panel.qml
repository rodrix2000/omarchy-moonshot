import QtQuick
import QtQuick.Controls as Controls
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

Panel {
  id: root
  moduleName: "io.github.rodrix2000.moonshot"
  ipcTarget: "io.github.rodrix2000.moonshot"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  readonly property var barIdentity: hostWidget || root
  property bool openedFromHotkey: false

  property bool editingLocation: false

  MoonshotModel {
    id: moonModel
    settings: root.settings
  }

  readonly property alias model: moonModel

  function open() {
    openedFromHotkey = false
    setCenterHoverRevealSuppressed(false)
    root.controller.show()
    moonModel.refresh()
  }

  function openFromHotkey() {
    openedFromHotkey = true
    root.controller.show()
    moonModel.refresh()
    Qt.callLater(function() {
      if (root.opened) setCenterHoverRevealSuppressed(true)
    })
  }

  function close() {
    setCenterHoverRevealSuppressed(false)
    if (editingLocation) editingLocation = false
    root.controller.hide()
  }

  function toggle() {
    if (root.opened) root.close()
    else root.openFromHotkey()
  }

  function refresh() {
    moonModel.refresh()
  }

  function setCenterHoverRevealSuppressed(value) {
    if (root.bar && "centerHoverRevealSuppressed" in root.bar) {
      root.bar.centerHoverRevealSuppressed = value
    }
  }

  KeyboardPanel {
    id: popup
    open: root.opened
    anchorItem: root.anchorItem
    bar: root.bar
    owner: root.hostWidget || root
    contentWidth: Style.space(380)
    contentHeight: Math.min(Style.space(560), Screen.height - Style.space(80))
    focusTarget: keyCatcher

    onOpenChanged: {
      if (!open && root.editingLocation) {
        root.editingLocation = false
      }
    }

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      blocked: root.editingLocation

      onCloseRequested: {
        if (root.editingLocation) root.editingLocation = false
        else root.close()
      }

      onMoveRequested: function(dx, dy) {
        if (dx !== 0) moonModel.stepDate(dx)
      }

      onTextKey: function(t) {
        var k = t.toLowerCase()
        if (k === "t") moonModel.jumpToToday()
        else if (k === "f") moonModel.jumpToPhase(2)
        else if (k === "n") moonModel.jumpToPhase(0)
        else if (k === "r") moonModel.refresh()
        else if (k === "l") root.editingLocation = !root.editingLocation
      }

      Column {
        anchors.fill: parent
        spacing: Style.spacing.rowGap

        LocationEditor {
          width: parent.width
          height: parent.height
          visible: root.editingLocation
          model: moonModel
          onClosed: { root.editingLocation = false }
        }

        Column {
          width: parent.width
          visible: !root.editingLocation
          spacing: Style.spacing.rowGap

          // 1. Top Header
          Item {
            width: parent.width
            height: headerLeft.implicitHeight

            Column {
              id: headerLeft
              anchors.left: parent.left
              spacing: 2
              Text {
                text: "MOONSHOT"
                font.family: Style.font.family
                font.pixelSize: Style.font.caption
                font.bold: true
                color: Color.accent
              }
              Text {
                text: moonModel.observation ? moonModel.observation.selectedLocalDate : "Today"
                font.family: Style.font.family
                font.pixelSize: Style.font.bodySmall
                color: Color.foreground
              }
            }

            Column {
              anchors.right: parent.right
              spacing: 2
              Text {
                anchors.right: parent.right
                text: moonModel.locationConfigured ? moonModel.locationLabel : "No location set"
                font.family: Style.font.family
                font.pixelSize: Style.font.caption
                color: Color.foreground
              }
              Text {
                anchors.right: parent.right
                text: "north-up chart"
                font.family: Style.font.family
                font.pixelSize: Style.font.caption
                color: Color.muted
              }
            }
          }

          // 2. Hero Moon Disk & Core Metrics
          Column {
            width: parent.width
            spacing: Style.spacing.controlGap

            MoonDisk {
              anchors.horizontalCenter: parent.horizontalCenter
              size: Style.space(130)
              phaseAngleDeg: moonModel.phaseAngleDeg
              illumination: moonModel.illuminationFraction
              direction: moonModel.direction
              hero: true
              renderMode: root.setting("renderMode", "realistic")
              reducedMotion: root.setting("reducedMotion", false)
            }

            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: moonModel.phaseName + " · " + Math.round(moonModel.illuminationPercent) + "%"
              font.family: Style.font.family
              font.pixelSize: Style.font.heading
              font.bold: true
              color: Color.foreground
            }

            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: (moonModel.direction === "waxing" ? "Waxing" : (moonModel.direction === "waning" ? "Waning" : "Exact Quarter"))
                    + " · " + moonModel.ageDays.toFixed(1) + " days old"
              font.family: Style.font.family
              font.pixelSize: Style.font.bodySmall
              color: Color.muted
            }
          }

          // 3. Observer Rise / Set Card
          BorderSurface {
            width: parent.width
            height: riseSetBox.implicitHeight + Style.spacing.popupPadding * 2
            padding: Style.spacing.popupPadding
            radius: Style.cornerRadius
            color: Color.popups.background

            Column {
              id: riseSetBox
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.top: parent.top
              anchors.margins: Style.spacing.popupPadding
              spacing: Style.spacing.controlGap

              Row {
                width: parent.width

                Column {
                  width: (parent.width - Style.spacing.controlGap) / 2
                  spacing: 2
                  Text {
                    text: "Moonrise"
                    font.family: Style.font.family
                    font.pixelSize: Style.font.caption
                    color: Color.muted
                  }
                  Text {
                    text: {
                      if (!moonModel.locationConfigured) return "Set location"
                      if (moonModel.riseEvent.status === "event" && moonModel.riseEvent.localDateTime) {
                        return moonModel.riseEvent.localDateTime.split("T")[1].substring(0, 5)
                      }
                      if (moonModel.riseEvent.status === "always-above") return "Always above"
                      if (moonModel.riseEvent.status === "always-below") return "Always below"
                      return "None in day"
                    }
                    font.family: Style.font.family
                    font.pixelSize: Style.font.body
                    font.bold: true
                    color: Color.foreground
                  }
                }

                Column {
                  width: (parent.width - Style.spacing.controlGap) / 2
                  spacing: 2
                  Text {
                    text: "Moonset"
                    font.family: Style.font.family
                    font.pixelSize: Style.font.caption
                    color: Color.muted
                  }
                  Text {
                    text: {
                      if (!moonModel.locationConfigured) return "Set location"
                      if (moonModel.setEvent.status === "event" && moonModel.setEvent.localDateTime) {
                        return moonModel.setEvent.localDateTime.split("T")[1].substring(0, 5)
                      }
                      if (moonModel.setEvent.status === "always-above") return "Always above"
                      if (moonModel.setEvent.status === "always-below") return "Always below"
                      return "None in day"
                    }
                    font.family: Style.font.family
                    font.pixelSize: Style.font.body
                    font.bold: true
                    color: Color.foreground
                  }
                }
              }

              Text {
                visible: moonModel.locationConfigured
                text: (moonModel.aboveHorizon ? "▲ Above horizon" : "▼ Below horizon") + " · Alt " + moonModel.altitudeDeg.toFixed(1) + "°"
                font.family: Style.font.family
                font.pixelSize: Style.font.caption
                color: moonModel.aboveHorizon ? Color.accent : Color.muted
              }
            }
          }

          // 4. Upcoming Major Phases
          Column {
            width: parent.width
            spacing: Style.spacing.controlGap
            visible: moonModel.nextMajorPhases.length > 0

            Text {
              text: "UPCOMING PHASES"
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
              font.bold: true
              color: Color.muted
            }

            Repeater {
              model: moonModel.nextMajorPhases.slice(0, 3)
              delegate: Row {
                required property var modelData
                width: parent.width

                Text {
                  width: Style.space(120)
                  text: modelData.name
                  font.family: Style.font.family
                  font.pixelSize: Style.font.caption
                  font.bold: true
                  color: Color.foreground
                }

                Text {
                  text: modelData.localDateTime ? modelData.localDateTime.replace("T", " · ").substring(0, 18) : ""
                  font.family: Style.font.family
                  font.pixelSize: Style.font.caption
                  color: Color.muted
                }
              }
            }
          }

          // 5. Date Navigation Controls
          Item {
            width: parent.width
            height: dateNavLeft.implicitHeight

            Row {
              id: dateNavLeft
              anchors.left: parent.left
              spacing: Style.spacing.controlGap

              Button {
                text: "‹ Previous"
                tooltipText: "Previous day (Left Arrow)"
                onClicked: { moonModel.stepDate(-1) }
              }

              Button {
                text: moonModel.isToday ? "Today" : "Jump to Today"
                selected: moonModel.isToday
                tooltipText: "Return to Today (T)"
                onClicked: { moonModel.jumpToToday() }
              }

              Button {
                text: "Next ›"
                tooltipText: "Next day (Right Arrow)"
                onClicked: { moonModel.stepDate(1) }
              }
            }

            Row {
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
              spacing: Style.spacing.controlGap

              Button {
                text: "🌕"
                tooltipText: "Jump to next Full Moon (F)"
                onClicked: { moonModel.jumpToPhase(2) }
              }

              Button {
                text: "🌑"
                tooltipText: "Jump to next New Moon (N)"
                onClicked: { moonModel.jumpToPhase(0) }
              }
            }
          }

          // 6. Bottom Footer & Location Button
          Item {
            width: parent.width
            height: footerButtons.implicitHeight

            Text {
              anchors.left: parent.left
              anchors.verticalCenter: parent.verticalCenter
              text: moonModel.loading ? "Calculating..." : (moonModel.stale ? "⚠️ Stale data" : "Updated just now")
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
              color: moonModel.stale ? Color.urgent : Color.muted
            }

            Row {
              id: footerButtons
              anchors.right: parent.right
              spacing: Style.spacing.controlGap

              Button {
                text: "📍 Location"
                tooltipText: "Configure Location (L)"
                onClicked: { root.editingLocation = true }
              }

              Button {
                text: "⟳"
                tooltipText: "Refresh (R)"
                onClicked: { moonModel.refresh() }
              }
            }
          }
        }
      }
    }
  }
}
