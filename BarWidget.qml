import QtQuick
import qs.Commons
import qs.Ui as Ui

Ui.BarWidget {
  id: root
  moduleName: "io.github.rodrix2000.moonshot"

  readonly property var hostShell: root.bar && root.bar.shell ? root.bar.shell : null
  readonly property var moonModel: root.hostShell
    && typeof root.hostShell.serviceFor === "function"
    ? root.hostShell.serviceFor(root.moduleName) : null
  property string transientDisplayMode: ""
  readonly property string displayMode: transientDisplayMode !== ""
    ? transientDisplayMode : root.setting("displayMode", "disk")

  function syncServiceSettings() {
    if (root.moonModel) root.moonModel.settings = root.settings || ({})
  }

  function refresh() {
    if (root.moonModel && typeof root.moonModel.refresh === "function") root.moonModel.refresh()
  }

  function togglePanel() {
    if (root.hostShell && typeof root.hostShell.toggle === "function")
      root.hostShell.toggle(root.moduleName, "{}")
  }

  function cycleDisplayMode() {
    var modes = ["disk", "illumination", "phase", "next-full", "moonrise"]
    var index = modes.indexOf(root.displayMode)
    root.transientDisplayMode = modes[(index + 1 + modes.length) % modes.length]
  }

  function localeTime(isoValue) {
    var match = /^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2})(?::(\d{2}))?/.exec(String(isoValue || ""))
    var date = match ? new Date(Number(match[1]), Number(match[2]) - 1, Number(match[3]),
      Number(match[4]), Number(match[5]), Number(match[6] || 0)) : null
    if (!date || isNaN(date.getTime())) return ""
    var preference = root.setting("timeFormat", "locale")
    var pattern = preference === "24h" ? "HH:mm"
      : (preference === "12h" ? "h:mm AP" : Qt.locale().timeFormat(Locale.ShortFormat))
    return Qt.formatTime(date, pattern)
  }

  function daysUntil(isoValue) {
    var date = new Date(String(isoValue || ""))
    if (isNaN(date.getTime())) return "soon"
    var days = Math.max(0, Math.ceil((date.getTime() - Date.now()) / 86400000))
    return days === 0 ? "today" : ("in " + days + "d")
  }

  function nextFullMoon() {
    if (!root.moonModel || !root.moonModel.nextMajorPhases) return null
    for (var i = 0; i < root.moonModel.nextMajorPhases.length; i++)
      if (root.moonModel.nextMajorPhases[i].quarter === 2) return root.moonModel.nextMajorPhases[i]
    return null
  }

  readonly property string barText: {
    if (!root.moonModel || root.vertical) return ""
    if (root.displayMode === "illumination") {
      return Math.round(root.moonModel.illuminationPercent) + "%"
    }
    if (root.displayMode === "phase") {
      return root.moonModel.phaseName
    }
    if (root.displayMode === "next-full") {
      var full = root.nextFullMoon()
      return full ? ("Full " + root.daysUntil(full.instantUtc)) : "Full soon"
    }
    if (root.displayMode === "moonrise") {
      if (root.moonModel.riseEvent && root.moonModel.riseEvent.localDateTime) {
        return root.localeTime(root.moonModel.riseEvent.localDateTime)
      }
    }
    return ""
  }

  readonly property string barTooltip: {
    if (!root.moonModel) return "Moonshot — service loading"
    return root.moonModel.phaseName + " · " + Math.round(root.moonModel.illuminationPercent)
      + "% illuminated" + (root.moonModel.locationConfigured ? " · " + root.moonModel.locationLabel : " · no location")
  }

  visible: true
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  onMoonModelChanged: syncServiceSettings()
  onSettingsChanged: syncServiceSettings()
  Component.onCompleted: syncServiceSettings()

  Ui.WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    tooltipText: root.barTooltip
    labelVisible: false
    hasVisualContent: true
    active: root.hostShell && typeof root.hostShell.isPluginOpen === "function"
      ? root.hostShell.isPluginOpen(root.moduleName) : false

    fixedWidth: root.vertical ? root.barSize : (contentRow.implicitWidth + (root.barText !== "" ? Style.spacing.controlPaddingX * 2 : Style.spacing.md * 2))
    fixedHeight: root.barSize

    onPressed: function(buttonCode) {
      if (buttonCode === Qt.MiddleButton) {
        root.refresh()
      } else if (buttonCode === Qt.RightButton) {
        root.cycleDisplayMode()
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
        size: Style.space(17)
        phaseAngleDeg: root.moonModel ? root.moonModel.phaseAngleDeg : 0.0
        illumination: root.moonModel ? root.moonModel.illuminationFraction : 0.0
        direction: root.moonModel ? root.moonModel.direction : "waxing"
        hero: false
        renderMode: root.setting("renderMode", "realistic")
        reducedMotion: root.setting("reducedMotion", false)
        surfaceColor: Color.bar.background
        accessibleDescription: root.barTooltip
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
