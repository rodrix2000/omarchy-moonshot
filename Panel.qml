import QtQuick
import QtQuick.Controls as Controls
import qs.Commons
import qs.Ui as Ui

Ui.Panel {
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
    root.openedFromHotkey = false
    root.setCenterHoverRevealSuppressed(false)
    root.controller.show()
    moonModel.refresh()
  }

  function openFromHotkey() {
    root.openedFromHotkey = true
    root.controller.show()
    moonModel.refresh()
    Qt.callLater(function() {
      if (root.opened) root.setCenterHoverRevealSuppressed(true)
    })
  }

  function close() {
    root.setCenterHoverRevealSuppressed(false)
    root.hideLocationEditor()
    root.controller.hide()
  }

  function toggle() {
    if (root.opened) root.close()
    else root.open()
  }

  function refresh() {
    moonModel.refresh()
  }

  function switchPanel(direction) {
    if (root.bar && typeof root.bar.switchPanelFrom === "function")
      return root.bar.switchPanelFrom(root.barIdentity, direction)
    return false
  }

  function setCenterHoverRevealSuppressed(value) {
    if (root.bar && "centerHoverRevealSuppressed" in root.bar)
      root.bar.centerHoverRevealSuppressed = value
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

  Ui.KeyboardPanel {
    id: popup
    open: root.opened
    anchorItem: root.anchorItem
    bar: root.bar
    owner: root.hostWidget || root
    contentWidth: fittedContentWidth(Style.space(420), Style.space(440))
    contentHeight: fittedContentHeight(
      (root.editingLocation ? locationEditor.implicitHeight : moonContent.implicitHeight)
        + Style.spacing.rowGap)
    focusTarget: keyCatcher

    onOpenChanged: {
      if (!open) root.editingLocation = false
      else mainFlick.contentY = 0
    }

    Ui.PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      blocked: root.editingLocation

      onCloseRequested: {
        if (root.editingLocation) root.hideLocationEditor()
        else root.close()
      }

      onMoveRequested: function(dx, dy) {
        if (dx !== 0) moonModel.stepDate(dx)
      }

      onTextKey: function(text) {
        var key = text.toLowerCase()
        if (key === "t") moonModel.jumpToToday()
        else if (key === "f") moonModel.jumpToPhase(2)
        else if (key === "n") moonModel.jumpToPhase(0)
        else if (key === "r") moonModel.refresh()
        // Lowercase l is reserved by PanelKeyCatcher for Vim-style Right.
        else if (text === "L") root.showLocationEditor()
      }

      Flickable {
        id: mainFlick
        anchors.fill: parent
        visible: !root.editingLocation
        clip: true
        contentWidth: width
        contentHeight: moonContent.implicitHeight
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick

        Controls.ScrollBar.vertical: Controls.ScrollBar {
          policy: mainFlick.contentHeight > mainFlick.height
            ? Controls.ScrollBar.AlwaysOn : Controls.ScrollBar.AlwaysOff
        }

        MoonshotContent {
          id: moonContent
          width: mainFlick.width
          model: moonModel
          settings: root.settings
          onPreviousRequested: moonModel.stepDate(-1)
          onTodayRequested: moonModel.jumpToToday()
          onNextRequested: moonModel.stepDate(1)
          onPhaseRequested: function(quarter) { moonModel.jumpToPhase(quarter) }
          onLocationRequested: root.showLocationEditor()
          onRefreshRequested: moonModel.refresh()
        }
      }

      Flickable {
        id: locationFlick
        anchors.fill: parent
        visible: root.editingLocation
        clip: true
        contentWidth: width
        contentHeight: locationEditor.implicitHeight
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick

        Controls.ScrollBar.vertical: Controls.ScrollBar {
          policy: locationFlick.contentHeight > locationFlick.height
            ? Controls.ScrollBar.AlwaysOn : Controls.ScrollBar.AlwaysOff
        }

        LocationEditor {
          id: locationEditor
          width: locationFlick.width
          visible: root.editingLocation
          model: moonModel
          onClosed: root.hideLocationEditor()
        }
      }
    }
  }
}
