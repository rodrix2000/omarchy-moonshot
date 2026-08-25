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

  readonly property alias model: moonModel
  readonly property real mainViewportHeight: mainFlick.height
  readonly property real mainContentHeight: mainFlick.contentHeight
  readonly property string activeView: moonContent.activeView
  readonly property string presentationMode: "anchored-popup"

  MoonshotModel {
    id: moonModel
    settings: root.settings
  }

  function open() {
    root.openedFromHotkey = false
    root.setCenterHoverRevealSuppressed(false)
    root.controller.show()
    root.model.refresh()
    Qt.callLater(function() {
      if (!root.opened) return
      root.showView("tonight")
      keyCatcher.forceActiveFocus()
    })
  }

  function openFromHotkey() {
    root.openedFromHotkey = true
    root.controller.show()
    root.model.refresh()
    Qt.callLater(function() {
      if (!root.opened) return
      root.showView("tonight")
      root.setCenterHoverRevealSuppressed(true)
      keyCatcher.forceActiveFocus()
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
    root.model.refresh()
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

  function showView(viewName) {
    moonContent.selectView(viewName)
    mainFlick.contentY = 0
  }

  Ui.KeyboardPanel {
    id: popup
    open: root.opened
    anchorItem: root.anchorItem
    bar: root.bar
    owner: root.barIdentity
    contentWidth: fittedContentWidth(Style.space(420), Style.space(440))
    contentHeight: fittedContentHeight(
      root.editingLocation ? locationEditor.implicitHeight : moonContent.implicitHeight,
      Style.space(660))
    focusTarget: keyCatcher

    onOpenChanged: {
      if (!open) root.editingLocation = false
      mainFlick.contentY = 0
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
        if (dx !== 0) root.model.stepDate(dx)
      }

      onTabRequested: function(direction) {
        root.switchPanel(direction)
      }

      onTextKey: function(text) {
        var key = text.toLowerCase()
        if (key === "t") root.model.jumpToToday()
        else if (key === "f") root.model.jumpToPhase(2)
        else if (key === "n") root.model.jumpToPhase(0)
        else if (key === "r") root.model.refresh()
        else if (key === "1") root.showView("tonight")
        else if (key === "2") root.showView("calendar")
        else if (key === "3") root.showView("timeline")
        else if (key === "4") root.showView("eclipses")
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
        interactive: contentHeight > height

        Controls.ScrollBar.vertical: Controls.ScrollBar {
          policy: mainFlick.contentHeight > mainFlick.height
            ? Controls.ScrollBar.AlwaysOn : Controls.ScrollBar.AlwaysOff
        }

        MoonshotContent {
          id: moonContent
          width: mainFlick.width
          model: root.model
          settings: root.settings
          onPreviousRequested: root.model.stepDate(-1)
          onTodayRequested: root.model.jumpToToday()
          onNextRequested: root.model.stepDate(1)
          onPhaseRequested: function(quarter) { root.model.jumpToPhase(quarter) }
          onDateRequested: function(isoDate) { root.model.selectDate(isoDate) }
          onPreviousMonthRequested: root.model.stepMonth(-1)
          onNextMonthRequested: root.model.stepMonth(1)
          onEventRequested: function(instantUtc, localDateTime) {
            root.model.jumpToEvent(instantUtc, localDateTime)
          }
          onLocationRequested: root.showLocationEditor()
          onRefreshRequested: root.model.refresh()
          onCloseRequested: root.close()
          onActiveViewChanged: mainFlick.contentY = 0
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
        interactive: contentHeight > height

        Controls.ScrollBar.vertical: Controls.ScrollBar {
          policy: locationFlick.contentHeight > locationFlick.height
            ? Controls.ScrollBar.AlwaysOn : Controls.ScrollBar.AlwaysOff
        }

        LocationEditor {
          id: locationEditor
          width: locationFlick.width
          visible: root.editingLocation
          model: root.model
          onClosed: root.hideLocationEditor()
        }
      }
    }
  }
}
