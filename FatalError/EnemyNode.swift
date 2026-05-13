import SpriteKit

final class EnemyNode: SKShapeNode {

    static let radius: CGFloat = 18

    var health: CGFloat

    init(health: CGFloat) {
        self.health = health
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

        fillColor = .systemGreen
        strokeColor = .white
        lineWidth = 2
        zPosition = 9
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func takeDamage(_ amount: CGFloat) -> Bool {
        health -= amount

        if health <= 0 {
            return true
        }

        flashDamage()
        return false
    }

    private func flashDamage() {
        let oldColor = fillColor
        fillColor = .white

        run(.sequence([
            .wait(forDuration: 0.08),
            .run { [weak self] in
                self?.fillColor = oldColor
            }
        ]))
    }
}
