pragma ComponentBehavior: Bound

import QtQuick
import "../../"

Item {
  id: root
  property int attempts: 0
  property int phase: 0

  MoonshotService {
    id: service
  }

  Panel {
    id: panel
    service: service
    manifest: ({ id: "io.github.rodrix2000.moonshot" })
  }

  Timer {
    interval: 25
    repeat: true
    running: true

    onTriggered: {
      root.attempts++
      if (root.attempts > 240) {
        console.error("PanelSmoke: timed out", root.phase,
          panel.mainContentHeight, panel.mainViewportHeight)
        Qt.exit(4)
        return
      }

      if (root.phase === 0 && service.snapshot !== null) {
        panel.setPanelSizeForTesting(480, 790)
        panel.open("{}")
        root.phase = 1
        return
      }

      if (root.phase === 1 && panel.opened && panel.mainViewportHeight > 0
          && panel.mainContentHeight > 0) {
        if (panel.mainContentHeight > panel.mainViewportHeight) {
          console.error("PanelSmoke: default panel still requires scrolling",
            panel.mainContentHeight, panel.mainViewportHeight)
          Qt.exit(2)
          return
        }
        panel.close()
        if (panel.opened) {
          console.error("PanelSmoke: panel did not close")
          Qt.exit(3)
          return
        }
        console.log("PanelSmoke: floating window lifecycle and no-scroll default OK")
        Qt.quit()
      }
    }
  }
}
