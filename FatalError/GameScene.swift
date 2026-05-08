
import SpriteKit

class GameScene: SKScene {

    private let worldNode = SKNode()
    private let cameraNode = SKCameraNode()

    private let gridNode = SKShapeNode()
    private let player = SKShapeNode(circleOfRadius: 22)

    private let joystickBase = SKShapeNode(circleOfRadius: 55)
    private let joystickKnob = SKShapeNode(circleOfRadius: 25)

    private let attackButton = SKShapeNode(circleOfRadius: 45)
    private let attackLabel = SKLabelNode(text: "ATK")

    private let xpLabel = SKLabelNode(text: "XP: 0")

    private let healthBarBackground = SKShapeNode(rectOf: CGSize(width: 220, height: 12), cornerRadius: 6)
    private let healthBarFill = SKShapeNode(rectOf: CGSize(width: 220, height: 12), cornerRadius: 6)

    private var joystickTouch: UITouch?
    private var attackTouch: UITouch?

    private var joystickCenter = CGPoint.zero
    private var moveVector = CGVector.zero

    private var enemies: [SKShapeNode] = []
    private var spawnTimer: TimeInterval = 0
    private var wave = 1
    private var xp = 0

    private var playerHealth: CGFloat = 100
    private let maxPlayerHealth: CGFloat = 100
    private let enemyDamage: CGFloat = 15
    private let enemyHitRadius: CGFloat = 40
    private let hitCooldown: TimeInterval = 0.75
    private var lastHitTime: TimeInterval = 0

    private let playerSpeed: CGFloat = 230
    private let enemySpeed: CGFloat = 90
    private let attackRadius: CGFloat = 70

    private var lastUpdateTime: TimeInterval = 0

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.10, green: 0.12, blue: 0.15, alpha: 1)

        addChild(worldNode)
        addChild(cameraNode)
        camera = cameraNode

        setupGrid()
        setupPlayer()
        setupJoystick()
        setupAttackButton()
        setupHUD()
        setupHealthBar()
        layoutControls()

        cameraNode.position = player.position
    }

    override func didChangeSize(_ oldSize: CGSize) {
        layoutControls()
    }

    private func setupGrid() {
        let path = CGMutablePath()
        let gridSize: CGFloat = 80
        let mapSize: CGFloat = 3200
        let halfSize = mapSize / 2

        var x = -halfSize
        while x <= halfSize {
            path.move(to: CGPoint(x: x, y: -halfSize))
            path.addLine(to: CGPoint(x: x, y: halfSize))
            x += gridSize
        }

        var y = -halfSize
        while y <= halfSize {
            path.move(to: CGPoint(x: -halfSize, y: y))
            path.addLine(to: CGPoint(x: halfSize, y: y))
            y += gridSize
        }

        gridNode.path = path
        gridNode.strokeColor = SKColor.white.withAlphaComponent(0.06)
        gridNode.lineWidth = 1
        gridNode.zPosition = -100
        worldNode.addChild(gridNode)
    }

    private func setupPlayer() {
        player.fillColor = .systemBlue
        player.strokeColor = .white
        player.lineWidth = 3
        player.zPosition = 10
        player.position = .zero
        worldNode.addChild(player)
    }

    private func setupJoystick() {
        joystickBase.fillColor = SKColor.white.withAlphaComponent(0.15)
        joystickBase.strokeColor = SKColor.white.withAlphaComponent(0.35)
        joystickBase.lineWidth = 3
        joystickBase.zPosition = 100
        cameraNode.addChild(joystickBase)

        joystickKnob.fillColor = SKColor.white.withAlphaComponent(0.45)
        joystickKnob.strokeColor = .white
        joystickKnob.lineWidth = 2
        joystickKnob.zPosition = 101
        cameraNode.addChild(joystickKnob)
    }

    private func setupAttackButton() {
        attackButton.fillColor = SKColor.systemRed.withAlphaComponent(0.7)
        attackButton.strokeColor = .white
        attackButton.lineWidth = 3
        attackButton.zPosition = 100
        cameraNode.addChild(attackButton)

        attackLabel.fontName = "AvenirNext-Bold"
        attackLabel.fontSize = 18
        attackLabel.fontColor = .white
        attackLabel.verticalAlignmentMode = .center
        attackLabel.zPosition = 101
        cameraNode.addChild(attackLabel)
    }

    private func setupHUD() {
        xpLabel.fontName = "AvenirNext-Bold"
        xpLabel.fontSize = 22
        xpLabel.fontColor = .white
        xpLabel.horizontalAlignmentMode = .left
        xpLabel.verticalAlignmentMode = .top
        xpLabel.zPosition = 100
        cameraNode.addChild(xpLabel)
    }

    private func setupHealthBar() {
        healthBarBackground.fillColor = SKColor.black.withAlphaComponent(0.35)
        healthBarBackground.strokeColor = SKColor.white.withAlphaComponent(0.25)
        healthBarBackground.lineWidth = 1
        healthBarBackground.zPosition = 100
        cameraNode.addChild(healthBarBackground)

        healthBarFill.fillColor = SKColor.systemGreen.withAlphaComponent(0.85)
        healthBarFill.strokeColor = .clear
        healthBarFill.zPosition = 101
        cameraNode.addChild(healthBarFill)
    }

    private func layoutControls() {
        let halfWidth = size.width / 2
        let halfHeight = size.height / 2

        joystickCenter = CGPoint(x: -halfWidth + 115, y: -halfHeight + 95)
        joystickBase.position = joystickCenter
        joystickKnob.position = joystickCenter

        let attackPosition = CGPoint(x: halfWidth - 115, y: -halfHeight + 95)
        attackButton.position = attackPosition
        attackLabel.position = attackPosition

        xpLabel.position = CGPoint(x: -halfWidth + 25, y: halfHeight - 25)

        let healthPosition = CGPoint(x: 0, y: -halfHeight + 28)
        healthBarBackground.position = healthPosition
        healthBarFill.position = healthPosition
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: cameraNode)

            if joystickBase.contains(location), joystickTouch == nil {
                joystickTouch = touch
                updateJoystick(with: location)
                continue
            }

            if attackButton.contains(location), attackTouch == nil {
                attackTouch = touch
                performAttack()
                continue
            }
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches where touch == joystickTouch {
            updateJoystick(with: touch.location(in: cameraNode))
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        endTouches(touches)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        endTouches(touches)
    }

    private func endTouches(_ touches: Set<UITouch>) {
        for touch in touches {
            if touch == joystickTouch {
                joystickTouch = nil
                moveVector = .zero
                joystickKnob.position = joystickCenter
            }

            if touch == attackTouch {
                attackTouch = nil
            }
        }
    }

    private func updateJoystick(with location: CGPoint) {
        let dx = location.x - joystickCenter.x
        let dy = location.y - joystickCenter.y

        let distance = sqrt(dx * dx + dy * dy)
        let maxDistance: CGFloat = 45

        guard distance > 0 else {
            moveVector = .zero
            return
        }

        let clampedDistance = min(distance, maxDistance)
        let angle = atan2(dy, dx)

        joystickKnob.position = CGPoint(
            x: joystickCenter.x + cos(angle) * clampedDistance,
            y: joystickCenter.y + sin(angle) * clampedDistance
        )

        moveVector = CGVector(
            dx: cos(angle) * (clampedDistance / maxDistance),
            dy: sin(angle) * (clampedDistance / maxDistance)
        )
    }

    private func performAttack() {
        let attackRange = SKShapeNode(circleOfRadius: attackRadius)
        attackRange.position = player.position
        attackRange.strokeColor = .systemRed
        attackRange.fillColor = SKColor.systemRed.withAlphaComponent(0.18)
        attackRange.lineWidth = 4
        attackRange.zPosition = 50
        worldNode.addChild(attackRange)

        attackRange.run(.sequence([
            .scale(to: 1.25, duration: 0.08),
            .fadeOut(withDuration: 0.12),
            .removeFromParent()
        ]))

        attackButton.run(.sequence([
            .scale(to: 0.88, duration: 0.05),
            .scale(to: 1.0, duration: 0.08)
        ]))

        killEnemiesInRange()
    }

    private func spawnWave() {
        let enemyCount = min(3 + wave, 12)

        for _ in 0..<enemyCount {
            spawnEnemy()
        }

        wave += 1
    }

    private func spawnEnemy() {
        let enemy = SKShapeNode(circleOfRadius: 18)
        enemy.fillColor = .systemGreen
        enemy.strokeColor = .white
        enemy.lineWidth = 2
        enemy.zPosition = 9
        enemy.position = randomSpawnPosition()
        worldNode.addChild(enemy)
        enemies.append(enemy)
    }

    private func randomSpawnPosition() -> CGPoint {
        let side = Int.random(in: 0...3)
        let padding: CGFloat = 100

        let cameraX = cameraNode.position.x
        let cameraY = cameraNode.position.y

        let left = cameraX - size.width / 2 - padding
        let right = cameraX + size.width / 2 + padding
        let bottom = cameraY - size.height / 2 - padding
        let top = cameraY + size.height / 2 + padding

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

    private func updateEnemies(deltaTime: TimeInterval) {
        for enemy in enemies {
            let dx = player.position.x - enemy.position.x
            let dy = player.position.y - enemy.position.y
            let distance = sqrt(dx * dx + dy * dy)

            guard distance > 0 else { continue }

            enemy.position.x += (dx / distance) * enemySpeed * CGFloat(deltaTime)
            enemy.position.y += (dy / distance) * enemySpeed * CGFloat(deltaTime)
        }
    }

    private func checkEnemyHits(currentTime: TimeInterval) {
        guard currentTime - lastHitTime >= hitCooldown else {
            return
        }

        for enemy in enemies {
            let dx = enemy.position.x - player.position.x
            let dy = enemy.position.y - player.position.y
            let distance = sqrt(dx * dx + dy * dy)

            if distance <= enemyHitRadius {
                lastHitTime = currentTime
                damagePlayer()
                return
            }
        }
    }

    private func damagePlayer() {
        playerHealth = max(0, playerHealth - enemyDamage)
        updateHealthBar()

        player.run(.sequence([
            .colorize(with: .systemRed, colorBlendFactor: 0.9, duration: 0.06),
            .colorize(withColorBlendFactor: 0, duration: 0.12)
        ]))

        if playerHealth <= 0 {
            gameOver()
        }
    }

    private func updateHealthBar() {
        let healthPercent = max(0, playerHealth / maxPlayerHealth)
        healthBarFill.xScale = healthPercent

        if healthPercent > 0.55 {
            healthBarFill.fillColor = SKColor.systemGreen.withAlphaComponent(0.85)
        } else if healthPercent > 0.25 {
            healthBarFill.fillColor = SKColor.systemYellow.withAlphaComponent(0.9)
        } else {
            healthBarFill.fillColor = SKColor.systemRed.withAlphaComponent(0.9)
        }
    }

    private func gameOver() {
        moveVector = .zero
        joystickKnob.position = joystickCenter

        let gameOverLabel = SKLabelNode(text: "GAME OVER")
        gameOverLabel.fontName = "AvenirNext-Bold"
        gameOverLabel.fontSize = 42
        gameOverLabel.fontColor = .white
        gameOverLabel.verticalAlignmentMode = .center
        gameOverLabel.zPosition = 200
        gameOverLabel.position = .zero
        cameraNode.addChild(gameOverLabel)

        isPaused = true
    }

    private func killEnemiesInRange() {
        var killedEnemies: [SKShapeNode] = []

        for enemy in enemies {
            let dx = enemy.position.x - player.position.x
            let dy = enemy.position.y - player.position.y
            let distance = sqrt(dx * dx + dy * dy)

            if distance <= attackRadius {
                killedEnemies.append(enemy)
            }
        }

        for enemy in killedEnemies {
            enemy.removeFromParent()
            enemies.removeAll { $0 == enemy }

            xp += 10
            xpLabel.text = "XP: \(xp)"
        }
    }

    private func updateCamera() {
        cameraNode.position = player.position
    }

    private func updateGrid() {
        let gridSize: CGFloat = 80

        gridNode.position = CGPoint(
            x: round(player.position.x / gridSize) * gridSize,
            y: round(player.position.y / gridSize) * gridSize
        )
    }

    override func update(_ currentTime: TimeInterval) {
        if lastUpdateTime == 0 {
            lastUpdateTime = currentTime
        }

        let deltaTime = currentTime - lastUpdateTime
        lastUpdateTime = currentTime

        spawnTimer += deltaTime
        if spawnTimer >= 4 {
            spawnTimer = 0
            spawnWave()
        }

        player.position.x += moveVector.dx * playerSpeed * CGFloat(deltaTime)
        player.position.y += moveVector.dy * playerSpeed * CGFloat(deltaTime)

        updateCamera()
        updateGrid()
        updateEnemies(deltaTime: deltaTime)
        checkEnemyHits(currentTime: currentTime)
    }
}
