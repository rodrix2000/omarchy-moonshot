import QtQuick
import "../../"

Item {
  id: root
  width: 380
  height: 560

  MoonshotModel {
    id: model
    onDataUpdated: {
      console.log("LifecycleSmoke: MoonshotModel received snapshot OK:", model.phaseName)
      Qt.quit()
    }
  }

  Timer {
    interval: 3000
    running: true
    onTriggered: {
      console.log("LifecycleSmoke: Timed out waiting for snapshot")
      Qt.quit()
    }
  }
}
