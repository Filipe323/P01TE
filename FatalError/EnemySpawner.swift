import SpriteKit

struct EnemySpawner {

    static func spawnInterval(wave: Int) -> TimeInterval {
        // O intervalo diminui à medida que as waves avançam (aparecem mais rápido)
        max(0.4, 2.5 - Double(wave) * 0.15)
    }

    static func totalEnemiesForWave(wave: Int) -> Int {
        // A dificuldade escala apenas na quantidade de inimigos por ronda
        3 + (wave * 5)
    }

    static func enemyHealth(wave: Int) -> CGFloat {
        // A vida é sempre 1. Morrem sempre com 1 hit (a menos que mudes o dano base do player no futuro)
        return 1.0
    }

    static func spawnPosition(
        cameraPosition: CGPoint,
        sceneSize: CGSize,
        padding: CGFloat = 100
    ) -> CGPoint {
        let side = Int.random(in: 0...3)

        let left = cameraPosition.x - sceneSize.width / 2 - padding
        let right = cameraPosition.x + sceneSize.width / 2 + padding
        let bottom = cameraPosition.y - sceneSize.height / 2 - padding
        let top = cameraPosition.y + sceneSize.height / 2 + padding

        switch side {
        case 0:
            return CGPoint(x: left, y: CGFloat.random(in: bottom...top))
        case 1:
            return CGPoint(x: right, y: CGFloat.random(in: bottom...top))
        case 2:
            return CGPoint(x: CGFloat.random(in: left...right), y: top)
        default:
            return CGPoint(x: CGFloat.random(in: left...right), y: bottom)
        }
    }
}
