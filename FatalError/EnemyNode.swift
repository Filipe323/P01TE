import SpriteKit

final class EnemyNode: SKSpriteNode {

    static let radius: CGFloat = 18

    var health: CGFloat

    init(health: CGFloat) {
        self.health = health

        let texture = SKTexture(imageNamed: "enemy_basic")
        super.init(texture: texture, color: .clear, size: CGSize(width: 44, height: 44))

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
        let oldColor = color
        let oldBlend = colorBlendFactor

        color = .white
        colorBlendFactor = 0.85

        run(.sequence([
            .wait(forDuration: 0.08),
            .run { [weak self] in
                self?.color = oldColor
                self?.colorBlendFactor = oldBlend
            }
        ]))
    }
}

