import SpriteKit

final class TouchControlsNode: SKNode {

    private let joystickBase = SKShapeNode(circleOfRadius: 55)
    private let joystickKnob = SKShapeNode(circleOfRadius: 25)

    private let attackButton = SKShapeNode(circleOfRadius: 45)
    private let attackLabel = SKLabelNode(text: "ATK")

    private var joystickCenter = CGPoint.zero

    override init() {
        super.init()

        setupJoystick()
        setupAttackButton()
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

    private func setupAttackButton() {
        attackButton.fillColor = SKColor.systemRed.withAlphaComponent(0.7)
        attackButton.strokeColor = .white
        attackButton.lineWidth = 3
        attackButton.zPosition = 100
        addChild(attackButton)

        attackLabel.fontName = "AvenirNext-Bold"
        attackLabel.fontSize = 18
        attackLabel.fontColor = .white
        attackLabel.verticalAlignmentMode = .center
        attackLabel.zPosition = 101
        addChild(attackLabel)
    }

    func layout(sceneSize: CGSize) {
        let halfWidth = sceneSize.width / 2
        let halfHeight = sceneSize.height / 2

        joystickCenter = CGPoint(x: -halfWidth + 115, y: -halfHeight + 95)
        joystickBase.position = joystickCenter
        joystickKnob.position = joystickCenter

        let attackPosition = CGPoint(x: halfWidth - 115, y: -halfHeight + 95)
        attackButton.position = attackPosition
        attackLabel.position = attackPosition
    }

    func isJoystickHit(_ location: CGPoint) -> Bool {
        joystickBase.contains(location)
    }

    func isAttackHit(_ location: CGPoint) -> Bool {
        attackButton.contains(location)
    }

    func updateJoystick(with location: CGPoint) -> (move: CGVector, facing: CGVector?) {
        let dx = location.x - joystickCenter.x
        let dy = location.y - joystickCenter.y

        let distance = sqrt(dx * dx + dy * dy)
        let maxDistance: CGFloat = 45

        guard distance > 0 else {
            return (.zero, nil)
        }

        let clampedDistance = min(distance, maxDistance)
        let angle = atan2(dy, dx)

        joystickKnob.position = CGPoint(
            x: joystickCenter.x + cos(angle) * clampedDistance,
            y: joystickCenter.y + sin(angle) * clampedDistance
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

    func pulseAttackButton() {
        attackButton.run(.sequence([
            .scale(to: 0.88, duration: 0.05),
            .scale(to: 1.0, duration: 0.08)
        ]))
    }
}
