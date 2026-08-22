import QtQuick
import qs.Commons

Item {
  id: root

  property real phaseAngleDeg: 0.0
  property real illumination: 0.0
  property string direction: "neutral"
  property real size: 24
  property string renderMode: "realistic"
  property bool reducedMotion: false
  property bool hero: false
  property string accessibleDescription: ""
  property url textureSource: Qt.resolvedUrl("assets/moon-surface-v2.png")

  // The albedo remains neutral. Theme colors affect the rim, focus context,
  // and optional glow—not the identity of the lunar surface itself.
  property color surfaceColor: Color.popups.background
  property color lightColor: Color.popups.text
  property color rimColor: Util.alpha(Color.popups.text, 0.36)
  property color glowColor: Util.alpha(Color.popups.text, 0.12)
  readonly property real surfaceLuma: root.surfaceColor.r * 0.2126
    + root.surfaceColor.g * 0.7152 + root.surfaceColor.b * 0.0722
  readonly property color shadowColor: root.surfaceLuma > 0.55 ? "#16181b" : "#050607"

  implicitWidth: size
  implicitHeight: size

  Accessible.role: Accessible.Graphic
  Accessible.name: root.accessibleDescription !== ""
    ? root.accessibleDescription : "North-up moon phase rendering"

  onPhaseAngleDegChanged: canvas.requestPaint()
  onIlluminationChanged: canvas.requestPaint()
  onDirectionChanged: canvas.requestPaint()
  onRenderModeChanged: canvas.requestPaint()
  onLightColorChanged: canvas.requestPaint()
  onRimColorChanged: canvas.requestPaint()
  onGlowColorChanged: canvas.requestPaint()
  onSurfaceColorChanged: canvas.requestPaint()
  onWidthChanged: canvas.requestPaint()
  onHeightChanged: canvas.requestPaint()
  onTextureSourceChanged: {
    canvas.loadImage(root.textureSource)
    canvas.requestPaint()
  }

  function traceIlluminatedPath(ctx, cx, cy, r, angle) {
    if (angle <= 0.5 || angle >= 359.5) return false
    if (Math.abs(angle - 180.0) <= 0.5) {
      ctx.beginPath()
      ctx.arc(cx, cy, r, 0, Math.PI * 2)
      ctx.closePath()
      return true
    }

    var waxing = angle < 180.0
    var cosAngle = Math.cos(angle * Math.PI / 180.0)
    var terminatorRadius = (waxing ? cosAngle : -cosAngle) * r
    var kappa = 0.5522847498
    ctx.beginPath()
    ctx.moveTo(cx, cy - r)
    if (waxing) {
      ctx.arc(cx, cy, r, -Math.PI / 2, Math.PI / 2, false)
    } else {
      ctx.arc(cx, cy, r, -Math.PI / 2, Math.PI / 2, true)
    }

    // Return from the bottom limb to the top along the terminator. Two
    // quarter-ellipse Béziers avoid platform differences in Canvas.ellipse
    // sweep handling and preserve the correct crescent/gibbous silhouette.
    ctx.bezierCurveTo(
      cx + kappa * terminatorRadius, cy + r,
      cx + terminatorRadius, cy + kappa * r,
      cx + terminatorRadius, cy)
    ctx.bezierCurveTo(
      cx + terminatorRadius, cy - kappa * r,
      cx + kappa * terminatorRadius, cy - r,
      cx, cy - r)
    ctx.closePath()
    return true
  }

  function drawTexture(ctx, source, x, y, diameter) {
    if (root.renderMode === "realistic" && canvas.isImageLoaded(source)) {
      ctx.drawImage(source, x, y, diameter, diameter)
      return true
    }
    return false
  }

  Canvas {
    id: canvas
    anchors.fill: parent
    antialiasing: true
    renderTarget: Canvas.FramebufferObject

    onImageLoaded: requestPaint()

    Component.onCompleted: loadImage(root.textureSource)

    onPaint: {
      var ctx = getContext("2d")
      ctx.reset()

      var w = width
      var h = height
      if (w <= 0 || h <= 0) return

      var cx = w / 2
      var cy = h / 2
      var pad = root.hero ? Math.max(2, w * 0.028) : 1
      var r = Math.max(2, Math.min(cx, cy) - pad)
      var angle = ((root.phaseAngleDeg % 360) + 360) % 360
      var illum = Math.max(0, Math.min(1, root.illumination))

      if (root.hero && !root.reducedMotion && illum > 0.72) {
        var glowRadius = r * (1.08 + (illum - 0.72) * 0.18)
        var glow = ctx.createRadialGradient(cx, cy, r * 0.82, cx, cy, glowRadius)
        glow.addColorStop(0, root.glowColor)
        glow.addColorStop(1, "rgba(0,0,0,0)")
        ctx.fillStyle = glow
        ctx.beginPath()
        ctx.arc(cx, cy, glowRadius, 0, Math.PI * 2)
        ctx.fill()
      }

      // Unilluminated sphere and a whisper of earthshine keep new moon from
      // becoming an empty slot without inventing a bright crescent.
      ctx.beginPath()
      ctx.arc(cx, cy, r, 0, Math.PI * 2)
      ctx.fillStyle = root.shadowColor
      ctx.fill()

      if (root.renderMode === "realistic" && root.hero && canvas.isImageLoaded(root.textureSource)) {
        ctx.save()
        ctx.beginPath()
        ctx.arc(cx, cy, r, 0, Math.PI * 2)
        ctx.clip()
        ctx.globalAlpha = 0.085
        root.drawTexture(ctx, root.textureSource, cx - r, cy - r, r * 2)
        ctx.restore()
      }

      if (root.traceIlluminatedPath(ctx, cx, cy, r, angle)) {
        ctx.save()
        ctx.clip()
        if (!root.drawTexture(ctx, root.textureSource, cx - r, cy - r, r * 2)) {
          ctx.fillStyle = root.lightColor
          ctx.fillRect(cx - r, cy - r, r * 2, r * 2)
        }

        // Gentle limb falloff gives the texture volume while preserving its
        // neutral albedo and keeps the phase edge crisp.
        if (root.renderMode === "realistic") {
          var limb = ctx.createRadialGradient(cx - r * 0.12, cy - r * 0.12,
            r * 0.18, cx, cy, r * 1.02)
          limb.addColorStop(0, "rgba(255,255,255,0.035)")
          limb.addColorStop(0.72, "rgba(0,0,0,0)")
          limb.addColorStop(1, "rgba(0,0,0,0.32)")
          ctx.fillStyle = limb
          ctx.fillRect(cx - r, cy - r, r * 2, r * 2)
        }
        ctx.restore()
      }

      ctx.beginPath()
      ctx.arc(cx, cy, r, 0, Math.PI * 2)
      ctx.lineWidth = root.hero ? Math.max(1, w * 0.006) : 1
      ctx.strokeStyle = root.rimColor
      ctx.stroke()
    }
  }
}
