import SpriteKit

final class TouchControlsNode: SKNode {

    private let joystickBase = SKShapeNode(circleOfRadius: 55)
    private let joystickKnob = SKShapeNode(circleOfRadius: 25)

    private let attackBase = SKShapeNode(circleOfRadius: 55)
    private let attackKnob = SKShapeNode(circleOfRadius: 25)
    private let attackLabel = SKLabelNode(text: "ATK")

    private var joystickCenter = CGPoint.zero
    private var attackCenter = CGPoint.zero

    override init() {
        super.init()

        setupJoystick()
        setupAttackControl()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupJoystick() {
        joystickBase.fillColor = SKColor.white.withAlphaComponent(0.15)
        joystickBase.strokeColor = SKColor.white.withAlphaComponent(0.35)
        joystickBase.lineWidth = 3
        joystickBase.zPosition = 100
        addChild(joystickBase)

        joystickKnob.fillColor = SKColor.white.withAlphaComponent(0.45)
        joystickKnob.strokeColor = .white
        joystickKnob.lineWidth = 2
        joystickKnob.zPosition = 101
        addChild(joystickKnob)
    }

    private func setupAttackControl() {
        attackBase.fillColor = SKColor.systemRed.withAlphaComponent(0.18)
        attackBase.strokeColor = SKColor.systemRed.withAlphaComponent(0.55)
        attackBase.lineWidth = 3
        attackBase.zPosition = 100
        addChild(attackBase)

        attackKnob.fillColor = SKColor.systemRed.withAlphaComponent(0.72)
        attackKnob.strokeColor = .white
        attackKnob.lineWidth = 2
        attackKnob.zPosition = 101
        addChild(attackKnob)

        attackLabel.fontName = "AvenirNext-Bold"
        attackLabel.fontSize = 14
        attackLabel.fontColor = .white
        attackLabel.verticalAlignmentMode = .center
        attackLabel.zPosition = 102
        addChild(attackLabel)
    }

    func layout(sceneSize: CGSize) {
        let halfWidth = sceneSize.width / 2
        let halfHeight = sceneSize.height / 2

        joystickCenter = CGPoint(x: -halfWidth + 115, y: -halfHeight + 95)
        joystickBase.position = joystickCenter
        joystickKnob.position = joystickCenter

        attackCenter = CGPoint(x: halfWidth - 115, y: -halfHeight + 95)
        attackBase.position = attackCenter
        attackKnob.position = attackCenter
        attackLabel.position = attackCenter
    }

    func isJoystickHit(_ location: CGPoint) -> Bool {
        joystickBase.contains(location)
    }

    func isAttackHit(_ location: CGPoint) -> Bool {
        attackBase.contains(location)
    }

    func updateJoystick(with location: CGPoint) -> (move: CGVector, facing: CGVector?) {
        let result = updateControl(
            location: location,
            center: joystickCenter,
            knob: joystickKnob
        )

        return (result.move, result.facing)
    }

    func updateAttackAim(with location: CGPoint) -> CGVector? {
        let result = updateControl(
            location: location,
            center: attackCenter,
            knob: attackKnob
        )

        return result.facing
    }

    private func updateControl(
        location: CGPoint,
        center: CGPoint,
        knob: SKShapeNode
    ) -> (move: CGVector, facing: CGVector?) {
        let dx = location.x - center.x
        let dy = location.y - center.y

        let distance = sqrt(dx * dx + dy * dy)
        let maxDistance: CGFloat = 45

        guard distance > 0 else {
            return (.zero, nil)
        }

        let clampedDistance = min(distance, maxDistance)
        let angle = atan2(dy, dx)

        knob.position = CGPoint(
            x: center.x + cos(angle) * clampedDistance,
            y: center.y + sin(angle) * clampedDistance
        )

        let move = CGVector(
            dx: cos(angle) * (clampedDistance / maxDistance),
            dy: sin(angle) * (clampedDistance / maxDistance)
        )

        let facing = CGVector(dx: cos(angle), dy: sin(angle))
        return (move, facing)
    }

    func resetJoystick() {
        joystickKnob.position = joystickCenter
    }

    func resetAttackAim() {
        attackKnob.position = attackCenter
        attackLabel.position = attackCenter
    }

    func pulseAttackControl() {
        attackKnob.run(.sequence([
            .scale(to: 0.82, duration: 0.05),
            .scale(to: 1.0, duration: 0.08)
        ]))
    }
}
