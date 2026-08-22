import QtQuick
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "io.github.rodrix2000.moonshot"

  function injectPanel() {
    var target = panelLoader.item
    if (!target) return
    if ("bar" in target) target.bar = root.bar
    if ("settings" in target) target.settings = root.settings
    if ("anchorItem" in target) target.anchorItem = button
    if ("hostWidget" in target) target.hostWidget = root
  }

  function refresh() {
    if (panelLoader.item && panelLoader.item.refresh) panelLoader.item.refresh()
  }

  function togglePanel() {
    if (panelLoader.item && panelLoader.item.toggle) panelLoader.item.toggle()
  }

  readonly property bool opened: panelLoader.item ? panelLoader.item.opened === true : false

  function open() {
    if (panelLoader.item && panelLoader.item.openFromHotkey) panelLoader.item.openFromHotkey()
  }

  function close() {
    if (panelLoader.item && panelLoader.item.close) panelLoader.item.close()
  }

  readonly property bool popoutSwitchClosing: panelLoader.item ? panelLoader.item.popoutSwitchClosing === true : false

  function closeForPopoutSwitch() {
    if (panelLoader.item) panelLoader.item.closeForPopoutSwitch()
  }

  readonly property var moonModel: panelLoader.item ? panelLoader.item.model : null
  readonly property string displayMode: root.setting("displayMode", "disk")

  readonly property string barText: {
    if (!moonModel) return ""
    if (root.displayMode === "illumination") {
      return Math.round(moonModel.illuminationPercent) + "%"
    }
    if (root.displayMode === "phase") {
      return moonModel.phaseName
    }
    if (root.displayMode === "next-full") {
      return "Full soon"
    }
    if (root.displayMode === "moonrise") {
      if (moonModel.riseEvent && moonModel.riseEvent.localDateTime) {
        return moonModel.riseEvent.localDateTime.split("T")[1].substring(0, 5)
      }
    }
    return ""
  }

  readonly property string barTooltip: {
    if (!moonModel) return "Moonshot"
    return moonModel.phaseName + " (" + Math.round(moonModel.illuminationPercent) + "% illuminated)"
  }

  visible: true
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  onBarChanged: injectPanel()
  onSettingsChanged: injectPanel()

  Loader {
    id: panelLoader
    active: true
    source: Qt.resolvedUrl("Panel.qml")
    visible: false
    onLoaded: {
      root.injectPanel()
      Qt.callLater(root.injectPanel)
    }
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    tooltipText: root.barTooltip
    labelVisible: false
    hasVisualContent: true

    fixedWidth: root.vertical ? root.barSize : (contentRow.implicitWidth + (root.barText !== "" ? Style.spacing.controlPaddingX * 2 : Style.spacing.md * 2))
    fixedHeight: root.barSize

    onPressed: function(buttonCode) {
      if (buttonCode === Qt.MiddleButton) {
        root.refresh()
      } else {
        root.togglePanel()
      }
    }

    Row {
      id: contentRow
      anchors.centerIn: parent
      spacing: root.barText !== "" ? Style.spacing.controlGap : 0

      MoonDisk {
        anchors.verticalCenter: parent.verticalCenter
        size: Style.space(16)
        phaseAngleDeg: root.moonModel ? root.moonModel.phaseAngleDeg : 0.0
        illumination: root.moonModel ? root.moonModel.illuminationFraction : 0.0
        direction: root.moonModel ? root.moonModel.direction : "waxing"
        hero: false
        renderMode: root.setting("renderMode", "realistic")
        reducedMotion: root.setting("reducedMotion", false)
      }

      Text {
        visible: root.barText !== ""
        anchors.verticalCenter: parent.verticalCenter
        text: root.barText
        font.family: Style.font.family
        font.pixelSize: Style.font.body
        font.bold: true
        color: root.bar ? root.bar.barForeground : Color.foreground
      }
    }
  }
}
