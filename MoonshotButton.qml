import QtQuick
import qs.Commons
import qs.Ui as Ui

Ui.BorderSurface {
  id: root

  property string text: ""
  property string iconName: ""
  property string tooltipText: ""
  property color foreground: Color.popups.text
  property color accent: Color.accent
  property bool selected: false
  property bool focusable: true
  property bool bordered: true
  property real iconSize: Style.font.icon
  property real fontSize: Style.font.bodySmall
  property real horizontalPadding: Style.spacing.controlPaddingX
  property real verticalPadding: Style.spacing.controlPaddingY

  signal clicked()

  activeFocusOnTab: focusable
  implicitWidth: contentRow.implicitWidth + horizontalPadding * 2 + Style.space(2)
  implicitHeight: Math.max(contentRow.implicitHeight + verticalPadding * 2, Style.spacing.controlHeight)
  radius: Style.cornerRadius

  Accessible.role: Accessible.Button
  Accessible.name: root.text !== "" ? root.text : root.tooltipText

  readonly property bool hot: pointer.containsMouse
  readonly property bool showFocus: root.focusable && root.activeFocus
  readonly property color stateColor: root.selected
    ? Style.selectedStateColor(root.foreground, root.accent) : root.foreground
  readonly property var currentBorder: root.showFocus
    ? Border.controlSpec("focus", root.foreground, root.accent)
    : root.hot
      ? Border.controlSpec("hover-cursor", root.foreground, root.accent)
      : root.selected
        ? Border.controlSpec("selected", root.foreground, root.accent)
        : root.bordered
          ? Border.controlSpec("normal", root.foreground, root.accent)
          : Border.none()

  color: pointer.pressed
    ? Style.pressedFillFor(root.foreground, root.accent)
    : root.showFocus
      ? Style.focusFillFor(root.foreground, root.accent)
      : root.hot
        ? Style.hoverFillFor(root.foreground, root.accent)
        : root.selected
          ? Style.selectedFillFor(root.foreground, root.accent)
          : "transparent"
  borderSpec: root.currentBorder

  Behavior on color { ColorAnimation { duration: 100 } }

  Row {
    id: contentRow
    anchors.centerIn: parent
    spacing: root.text !== "" && root.iconName !== "" ? Style.spacing.controlGap : 0

    MoonshotIcon {
      visible: root.iconName !== ""
      anchors.verticalCenter: parent.verticalCenter
      name: root.iconName
      size: root.iconSize
      color: root.stateColor
    }

    Text {
      visible: root.text !== ""
      anchors.verticalCenter: parent.verticalCenter
      text: root.text
      color: root.stateColor
      font.family: Style.font.family
      font.pixelSize: root.fontSize
      font.bold: root.selected
    }
  }

  MouseArea {
    id: pointer
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: {
      if (root.focusable) root.forceActiveFocus()
      root.clicked()
    }
  }

  Keys.onReturnPressed: if (root.focusable) root.clicked()
  Keys.onEnterPressed: if (root.focusable) root.clicked()
  Keys.onSpacePressed: if (root.focusable) root.clicked()

  Ui.PanelToolTip {
    visible: root.tooltipText !== "" && pointer.containsMouse
    text: root.tooltipText
    fontFamily: Style.font.family
  }
}
