pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as Controls
import Quickshell
import qs.Commons
import qs.Ui as Ui

Item {
  id: root

  property string omarchyPath: ""
  property var shell: null
  property var manifest: null
  property var service: null
  property bool closingFromHost: false
  property bool editingLocation: false
  property size preferredWindowSize: Qt.size(480, 790)

  readonly property string pluginId: manifest && manifest.id
    ? String(manifest.id) : "io.github.rodrix2000.moonshot"
  readonly property bool opened: moonWindow.visible
  readonly property var model: service
  readonly property var settings: service && service.settings ? service.settings : ({})
  readonly property real mainViewportHeight: mainFlick.height
  readonly property real mainContentHeight: mainFlick.contentHeight

  function open(_payloadJson) {
    root.closingFromHost = false
    root.editingLocation = false
    moonWindow.visible = true
    if (root.model && typeof root.model.refresh === "function") root.model.refresh()
    Qt.callLater(function() {
      if (moonWindow.visible) keyCatcher.forceActiveFocus()
    })
  }

  function close() {
    root.closingFromHost = true
    root.editingLocation = false
    keyCatcher.focus = false
    focusScope.focus = false
    moonWindow.visible = false
    root.closingFromHost = false
  }

  function requestClose() {
    if (root.shell && typeof root.shell.hide === "function") root.shell.hide(root.pluginId)
    else root.close()
  }

  function showLocationEditor() {
    root.editingLocation = true
    locationFlick.contentY = 0
  }

  function hideLocationEditor() {
    if (!root.editingLocation) return
    root.editingLocation = false
    Qt.callLater(function() {
      if (root.opened) keyCatcher.forceActiveFocus()
    })
  }

  function setPanelSizeForTesting(width, height) {
    moonWindow.implicitWidth = width
    moonWindow.implicitHeight = height
  }

  FloatingWindow {
    id: moonWindow
    title: "Moonshot"
    implicitWidth: Math.max(440, root.preferredWindowSize.width)
    implicitHeight: Math.max(700, root.preferredWindowSize.height)
    minimumSize: Qt.size(420, 620)
    visible: false
    color: Color.popups.background

    onVisibleChanged: {
      if (!visible && !root.closingFromHost) root.requestClose()
    }

    FocusScope {
      id: focusScope
      anchors.fill: parent
      focus: moonWindow.visible

      Rectangle {
        anchors.fill: parent
        color: Color.popups.background

        Ui.PanelKeyCatcher {
          id: keyCatcher
          anchors.fill: parent
          anchors.margins: Style.spacing.popupPadding
          blocked: root.editingLocation

          onCloseRequested: {
            if (root.editingLocation) root.hideLocationEditor()
            else root.requestClose()
          }

          onMoveRequested: function(dx, dy) {
            if (dx !== 0 && root.model) root.model.stepDate(dx)
          }

          onTextKey: function(text) {
            if (!root.model) return
            var key = text.toLowerCase()
            if (key === "t") root.model.jumpToToday()
            else if (key === "f") root.model.jumpToPhase(2)
            else if (key === "n") root.model.jumpToPhase(0)
            else if (key === "r") root.model.refresh()
            // Lowercase l is reserved by PanelKeyCatcher for Vim-style Right.
            else if (text === "L") root.showLocationEditor()
          }

          Flickable {
            id: mainFlick
            anchors.fill: parent
            visible: !root.editingLocation
            clip: true
            contentWidth: width
            contentHeight: moonContentLoader.item ? moonContentLoader.item.implicitHeight : 0
            boundsBehavior: Flickable.StopAtBounds
            flickableDirection: Flickable.VerticalFlick
            interactive: contentHeight > height

            Controls.ScrollBar.vertical: Controls.ScrollBar {
              policy: mainFlick.contentHeight > mainFlick.height
                ? Controls.ScrollBar.AlwaysOn : Controls.ScrollBar.AlwaysOff
            }

            Loader {
              id: moonContentLoader
              width: mainFlick.width
              active: root.model !== null

              sourceComponent: MoonshotContent {
                width: mainFlick.width
                model: root.model
                settings: root.settings
                onPreviousRequested: root.model.stepDate(-1)
                onTodayRequested: root.model.jumpToToday()
                onNextRequested: root.model.stepDate(1)
                onPhaseRequested: function(quarter) { root.model.jumpToPhase(quarter) }
                onLocationRequested: root.showLocationEditor()
                onRefreshRequested: root.model.refresh()
                onCloseRequested: root.requestClose()
              }
            }
          }

          Flickable {
            id: locationFlick
            anchors.fill: parent
            visible: root.editingLocation
            clip: true
            contentWidth: width
            contentHeight: locationEditorLoader.item ? locationEditorLoader.item.implicitHeight : 0
            boundsBehavior: Flickable.StopAtBounds
            flickableDirection: Flickable.VerticalFlick
            interactive: contentHeight > height

            Controls.ScrollBar.vertical: Controls.ScrollBar {
              policy: locationFlick.contentHeight > locationFlick.height
                ? Controls.ScrollBar.AlwaysOn : Controls.ScrollBar.AlwaysOff
            }

            Loader {
              id: locationEditorLoader
              width: locationFlick.width
              active: root.model !== null
              visible: root.editingLocation

              sourceComponent: LocationEditor {
                width: locationFlick.width
                visible: root.editingLocation
                model: root.model
                onClosed: root.hideLocationEditor()
              }
            }
          }
        }
      }
    }
  }
}
