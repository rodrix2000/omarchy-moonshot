pragma ComponentBehavior: Bound

import QtQuick
import qs.Commons
import "../../"

Item {
  id: root
  width: Style.space(420)
  height: Style.space(620)

  property int attempts: 0
  property int caseIndex: 0
  property var views: ["tonight", "calendar", "timeline", "eclipses"]

  MoonshotModel {
    id: model
    settings: ({ renderMode: "minimal", reducedMotion: true })
  }

  MoonshotContent {
    id: content
    width: root.width
    visible: false
    model: model
    settings: model.settings
  }

  Timer {
    interval: 25
    repeat: true
    running: true

    onTriggered: {
      root.attempts++
      if (root.attempts > 240) {
        console.error("PanelSmoke: timed out", root.caseIndex,
          content.activeView, content.implicitHeight)
        Qt.exit(4)
        return
      }

      if (model.snapshot === null) return

      var viewName = root.views[root.caseIndex]
      if (content.activeView !== viewName) {
        content.selectView(viewName)
        return
      }
      if (content.implicitHeight <= 0) return
      if (content.implicitHeight > root.height) {
        console.error("PanelSmoke: popup view exceeds compact content height",
          viewName, content.implicitHeight, root.height)
        Qt.exit(2)
        return
      }

      root.caseIndex++
      if (root.caseIndex === root.views.length) {
        console.log("PanelSmoke: compact popup planning views OK")
        Qt.quit()
      }
    }
  }
}
