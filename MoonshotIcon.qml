import QtQuick

Item {
  id: root

  property string name: ""
  property real size: 18
  property color color: "white"
  property real strokeWidth: 1.7

  implicitWidth: size
  implicitHeight: size

  onNameChanged: canvas.requestPaint()
  onColorChanged: canvas.requestPaint()
  onStrokeWidthChanged: canvas.requestPaint()
  onWidthChanged: canvas.requestPaint()
  onHeightChanged: canvas.requestPaint()

  Canvas {
    id: canvas
    anchors.fill: parent
    antialiasing: true
    renderTarget: Canvas.FramebufferObject

    onPaint: {
      var ctx = getContext("2d")
      ctx.reset()
      if (width <= 0 || height <= 0) return

      var scale = Math.min(width, height) / 24.0
      ctx.save()
      ctx.translate((width - 24 * scale) / 2, (height - 24 * scale) / 2)
      ctx.scale(scale, scale)
      ctx.strokeStyle = root.color
      ctx.fillStyle = root.color
      ctx.lineWidth = root.strokeWidth
      ctx.lineCap = "round"
      ctx.lineJoin = "round"

      if (root.name === "chevron-left" || root.name === "chevron-right") {
        var flip = root.name === "chevron-right" ? -1 : 1
        ctx.translate(root.name === "chevron-right" ? 24 : 0, 0)
        ctx.scale(flip, 1)
        ctx.beginPath()
        ctx.moveTo(14.5, 5.5)
        ctx.lineTo(8.0, 12.0)
        ctx.lineTo(14.5, 18.5)
        ctx.stroke()
      } else if (root.name === "refresh") {
        ctx.beginPath()
        ctx.arc(12, 12, 7.2, -0.35, 4.85, false)
        ctx.stroke()
        ctx.beginPath()
        ctx.moveTo(17.8, 5.2)
        ctx.lineTo(18.9, 9.2)
        ctx.lineTo(14.8, 8.2)
        ctx.stroke()
      } else if (root.name === "location") {
        ctx.beginPath()
        ctx.moveTo(12, 21)
        ctx.bezierCurveTo(12, 21, 5.5, 14.2, 5.5, 9.5)
        ctx.bezierCurveTo(5.5, 5.7, 8.4, 3, 12, 3)
        ctx.bezierCurveTo(15.6, 3, 18.5, 5.7, 18.5, 9.5)
        ctx.bezierCurveTo(18.5, 14.2, 12, 21, 12, 21)
        ctx.stroke()
        ctx.beginPath()
        ctx.arc(12, 9.5, 2.2, 0, Math.PI * 2)
        ctx.stroke()
      } else if (root.name === "rise" || root.name === "set") {
        ctx.beginPath()
        ctx.moveTo(4, 18.5)
        ctx.lineTo(20, 18.5)
        ctx.stroke()
        ctx.beginPath()
        ctx.arc(12, 18.5, 5.5, Math.PI, Math.PI * 2)
        ctx.stroke()
        ctx.beginPath()
        if (root.name === "rise") {
          ctx.moveTo(12, 14)
          ctx.lineTo(12, 4)
          ctx.moveTo(8.5, 7.5)
          ctx.lineTo(12, 4)
          ctx.lineTo(15.5, 7.5)
        } else {
          ctx.moveTo(12, 4)
          ctx.lineTo(12, 14)
          ctx.moveTo(8.5, 10.5)
          ctx.lineTo(12, 14)
          ctx.lineTo(15.5, 10.5)
        }
        ctx.stroke()
      } else if (root.name === "horizon") {
        ctx.beginPath()
        ctx.arc(12, 16.5, 6.5, Math.PI, Math.PI * 2)
        ctx.stroke()
        ctx.beginPath()
        ctx.moveTo(3, 18.5)
        ctx.lineTo(21, 18.5)
        ctx.stroke()
      } else if (root.name === "full-moon") {
        ctx.beginPath()
        ctx.arc(12, 12, 7.2, 0, Math.PI * 2)
        ctx.fill()
      } else if (root.name === "new-moon") {
        ctx.beginPath()
        ctx.arc(12, 12, 7.2, 0, Math.PI * 2)
        ctx.stroke()
      } else if (root.name === "calendar") {
        ctx.beginPath()
        ctx.rect(4, 5, 16, 15)
        ctx.stroke()
        ctx.beginPath()
        ctx.moveTo(4, 9)
        ctx.lineTo(20, 9)
        ctx.moveTo(8, 3.5)
        ctx.lineTo(8, 6.5)
        ctx.moveTo(16, 3.5)
        ctx.lineTo(16, 6.5)
        ctx.stroke()
        ctx.beginPath()
        ctx.arc(8, 13, 1, 0, Math.PI * 2)
        ctx.arc(12, 13, 1, 0, Math.PI * 2)
        ctx.arc(16, 13, 1, 0, Math.PI * 2)
        ctx.arc(8, 17, 1, 0, Math.PI * 2)
        ctx.arc(12, 17, 1, 0, Math.PI * 2)
        ctx.fill()
      } else if (root.name === "timeline") {
        ctx.beginPath()
        ctx.moveTo(3.5, 12)
        ctx.lineTo(20.5, 12)
        ctx.stroke()
        for (var marker = 0; marker < 4; marker++) {
          ctx.beginPath()
          ctx.arc(4 + marker * 5.3, 12, marker === 2 ? 2.4 : 1.7, 0, Math.PI * 2)
          marker === 2 ? ctx.fill() : ctx.stroke()
        }
      } else if (root.name === "eclipse-lunar") {
        ctx.beginPath()
        ctx.arc(11, 12, 7.2, 0, Math.PI * 2)
        ctx.stroke()
        ctx.beginPath()
        ctx.arc(15.5, 12, 7.2, Math.PI * 0.58, Math.PI * 1.42)
        ctx.stroke()
      } else if (root.name === "eclipse-solar") {
        ctx.beginPath()
        ctx.arc(12, 12, 5.5, 0, Math.PI * 2)
        ctx.stroke()
        for (var ray = 0; ray < 8; ray++) {
          var rayAngle = ray * Math.PI / 4
          ctx.moveTo(12 + Math.cos(rayAngle) * 8, 12 + Math.sin(rayAngle) * 8)
          ctx.lineTo(12 + Math.cos(rayAngle) * 10, 12 + Math.sin(rayAngle) * 10)
        }
        ctx.stroke()
        ctx.beginPath()
        ctx.arc(10.5, 12, 3.4, 0, Math.PI * 2)
        ctx.fill()
      } else if (root.name === "close") {
        ctx.beginPath()
        ctx.moveTo(6, 6)
        ctx.lineTo(18, 18)
        ctx.moveTo(18, 6)
        ctx.lineTo(6, 18)
        ctx.stroke()
      }
      ctx.restore()
    }
  }
}
