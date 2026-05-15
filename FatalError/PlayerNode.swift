import SpriteKit

final class PlayerNode: SKShapeNode {

    static let radius: CGFloat = 22

    var health: CGFloat = 100
    var maxHealth: CGFloat = 100
    var damage: CGFloat = 1
    var facingVector = CGVector(dx: 1, dy: 0)

    override init() {
        super.init()

        path = CGPath(
            ellipseIn: CGRect(
                x: -Self.radius,
                y: -Self.radius,
                width: Self.radius * 2,
                height: Self.radius * 2
            ),
            transform: nil
        )

        fillColor = .systemBlue
        strokeColor = .white
        lineWidth = 3
        zPosition = 10
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func reset() {
        position = .zero
        health = 100
        maxHealth = 100
        damage = 1
        facingVector = CGVector(dx: 1, dy: 0)
        fillColor = .systemBlue
        removeAllActions()
    }

    func takeDamage(_ amount: CGFloat) -> Bool {
        health = max(0, health - amount)
        flashDamage()
        return health <= 0
    }

    func applyHealthBuff() {
        if health >= maxHealth {
            maxHealth += 20
            health = maxHealth
        } else {
            health = min(maxHealth, health + 35)
        }
    }

    private func flashDamage() {
        let oldColor = fillColor
        fillColor = .systemRed

        run(.sequence([
            .wait(forDuration: 0.12),
            .run { [weak self] in
                self?.fillColor = oldColor
            }
        ]))
    }
}
