import QtQuick
import qs.Commons

Item {
  id: root

  property real phaseAngleDeg: 0.0
  property real illumination: 0.0
  property string direction: "waxing"
  property real size: 24
  property string renderMode: "realistic"
  property bool reducedMotion: false
  property bool hero: false

  property color lightColor: Color.foreground
  property color darkColor: Color.background
  property color rimColor: Color.muted
  property color glowColor: Color.accent

  implicitWidth: size
  implicitHeight: size

  onPhaseAngleDegChanged: canvas.requestPaint()
  onIlluminationChanged: canvas.requestPaint()
  onDirectionChanged: canvas.requestPaint()
  onRenderModeChanged: canvas.requestPaint()
  onLightColorChanged: canvas.requestPaint()
  onDarkColorChanged: canvas.requestPaint()
  onWidthChanged: canvas.requestPaint()
  onHeightChanged: canvas.requestPaint()

  Canvas {
    id: canvas
    anchors.fill: parent
    antialiasing: true
    renderTarget: Canvas.FramebufferObject

    onPaint: {
      var ctx = canvas.getContext("2d")
      ctx.reset()

      var w = canvas.width
      var h = canvas.height
      if (w <= 0 || h <= 0) return

      var cx = w / 2.0
      var cy = h / 2.0
      var pad = root.hero ? Math.max(2.0, w * 0.04) : 1.0
      var r = Math.max(2.0, Math.min(cx, cy) - pad)

      var angle = ((root.phaseAngleDeg % 360.0) + 360.0) % 360.0
      var illum = Math.max(0.0, Math.min(1.0, root.illumination))

      // 1. Soft atmospheric glow for hero in high illumination
      if (root.hero && !root.reducedMotion && illum > 0.75) {
        var glowRad = r * (1.0 + (illum - 0.75) * 0.4)
        var glowGrad = ctx.createRadialGradient(cx, cy, r * 0.8, cx, cy, glowRad)
        glowGrad.addColorStop(0.0, "rgba(230, 237, 243, 0.12)")
        glowGrad.addColorStop(1.0, "rgba(230, 237, 243, 0.0)")
        ctx.fillStyle = glowGrad
        ctx.beginPath()
        ctx.arc(cx, cy, glowRad, 0, 2 * Math.PI)
        ctx.fill()
      }

      // 2. Base dark sphere
      ctx.beginPath()
      ctx.arc(cx, cy, r, 0, 2 * Math.PI)
      ctx.fillStyle = root.darkColor
      ctx.fill()

      // 3. Faint rim outline for new moon / unilluminated limb
      ctx.lineWidth = root.hero ? Math.max(1.0, w * 0.015) : 1.0
      ctx.strokeStyle = root.rimColor
      ctx.stroke()

      if (illum < 0.005 || angle < 1.0 || angle > 359.0) {
        return
      }

      if (illum > 0.995 || Math.abs(angle - 180.0) < 1.0) {
        ctx.beginPath()
        ctx.arc(cx, cy, r, 0, 2 * Math.PI)
        ctx.fillStyle = root.lightColor
        ctx.fill()
        if (root.renderMode === "realistic" && root.hero) {
          root.drawRealisticCraters(ctx, cx, cy, r)
        }
        return
      }

      // 4. Procedural illuminated shape (North-Up convention)
      ctx.save()
      ctx.beginPath()
      ctx.arc(cx, cy, r, 0, 2 * Math.PI)
      ctx.clip()

      var isWaxing = angle < 180.0
      var cosA = Math.cos(angle * Math.PI / 180.0)

      ctx.beginPath()
      if (isWaxing) {
        ctx.arc(cx, cy, r, -Math.PI / 2.0, Math.PI / 2.0, false)
        ctx.ellipse(cx, cy, Math.abs(r * cosA), r, 0, Math.PI / 2.0, -Math.PI / 2.0, cosA < 0)
      } else {
        ctx.arc(cx, cy, r, Math.PI / 2.0, -Math.PI / 2.0, false)
        ctx.ellipse(cx, cy, Math.abs(r * cosA), r, 0, -Math.PI / 2.0, Math.PI / 2.0, cosA > 0)
      }
      ctx.closePath()
      ctx.fillStyle = root.lightColor
      ctx.fill()

      if (root.renderMode === "realistic" && root.hero) {
        root.drawRealisticCraters(ctx, cx, cy, r)
      }

      ctx.restore()
    }
  }

  function drawRealisticCraters(ctx, cx, cy, r) {
    ctx.save()
    ctx.fillStyle = "rgba(100, 110, 125, 0.18)"

    ctx.beginPath()
    ctx.arc(cx - r * 0.28, cy - r * 0.22, r * 0.26, 0, 2 * Math.PI)
    ctx.fill()

    ctx.beginPath()
    ctx.arc(cx + r * 0.18, cy - r * 0.12, r * 0.19, 0, 2 * Math.PI)
    ctx.fill()

    ctx.beginPath()
    ctx.arc(cx + r * 0.24, cy + r * 0.12, r * 0.20, 0, 2 * Math.PI)
    ctx.fill()

    ctx.beginPath()
    ctx.arc(cx + r * 0.52, cy - r * 0.16, r * 0.11, 0, 2 * Math.PI)
    ctx.fill()

    ctx.beginPath()
    ctx.arc(cx - r * 0.08, cy + r * 0.54, r * 0.07, 0, 2 * Math.PI)
    ctx.fillStyle = "rgba(255, 255, 255, 0.22)"
    ctx.fill()

    ctx.restore()
  }
}
