import SpriteKit

class GameScene: SKScene {

    private let worldNode = SKNode()
    private let cameraNode = SKCameraNode()

    private let gridNode = SKShapeNode()
    private let player = PlayerNode()
    private let controls = TouchControlsNode()
    private let hud = GameHUDNode()

    private var joystickTouch: UITouch?
    private var attackTouch: UITouch?

    private var moveVector = CGVector.zero
    private var enemies: [EnemyNode] = []

    private var xp = 0
    private var nextBuffXP = 100

    private let enemyDamage: CGFloat = 15
    private let enemyHitRadius: CGFloat = 40
    private let hitCooldown: TimeInterval = 0.75
    private var lastHitTime: TimeInterval = 0

    private let playerSpeed: CGFloat = 230
    private let enemySpeed: CGFloat = 90
    private let attackRange: CGFloat = 95
    private let attackAngle: CGFloat = .pi / 2.6

    private var spawnTimer: TimeInterval = 0
    private var survivalTime: TimeInterval = 0
    private var lastUpdateTime: TimeInterval = 0

    private var isGameOver = false
    private var isChoosingBuff = false

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.10, green: 0.12, blue: 0.15, alpha: 1)

        addChild(worldNode)
        addChild(cameraNode)
        camera = cameraNode

        setupGrid()
        worldNode.addChild(player)

        cameraNode.addChild(controls)
        cameraNode.addChild(hud)

        layoutInterface()
        hud.updateHealth(current: player.health, max: player.maxHealth)

        cameraNode.position = player.position
    }

    override func didChangeSize(_ oldSize: CGSize) {
        layoutInterface()
    }

    private func layoutInterface() {
        controls.layout(sceneSize: size)
        hud.layout(sceneSize: size)
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

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: cameraNode)

            if isGameOver {
                if hud.isRestartHit(location) {
                    restartGame()
                }
                continue
            }

            if isChoosingBuff {
                handleBuffTouch(location)
                continue
            }

            if controls.isJoystickHit(location), joystickTouch == nil {
                joystickTouch = touch
                updateJoystick(with: location)
                continue
            }

            if controls.isAttackHit(location), attackTouch == nil {
                attackTouch = touch
                performAttack()
                continue
            }
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isGameOver || isChoosingBuff { return }

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
                controls.resetJoystick()
            }

            if touch == attackTouch {
                attackTouch = nil
            }
        }
    }

    private func updateJoystick(with location: CGPoint) {
        let result = controls.updateJoystick(with: location)
        moveVector = result.move

        if let facing = result.facing {
            player.facingVector = facing
        }
    }

    private func performAttack() {
        let attackEffect = createAttackCone()
        worldNode.addChild(attackEffect)

        attackEffect.run(.sequence([
            .fadeOut(withDuration: 0.16),
            .removeFromParent()
        ]))

        controls.pulseAttackButton()
        damageEnemiesInAttackCone()
    }

    private func createAttackCone() -> SKShapeNode {
        let directionAngle = atan2(player.facingVector.dy, player.facingVector.dx)
        let startAngle = directionAngle - attackAngle / 2
        let endAngle = directionAngle + attackAngle / 2

        let path = CGMutablePath()
        path.move(to: player.position)

        let steps = 16
        for i in 0...steps {
            let progress = CGFloat(i) / CGFloat(steps)
            let angle = startAngle + (endAngle - startAngle) * progress

            path.addLine(to: CGPoint(
                x: player.position.x + cos(angle) * attackRange,
                y: player.position.y + sin(angle) * attackRange
            ))
        }

        path.closeSubpath()

        let cone = SKShapeNode(path: path)
        cone.fillColor = SKColor.systemRed.withAlphaComponent(0.20)
        cone.strokeColor = SKColor.systemRed.withAlphaComponent(0.85)
        cone.lineWidth = 3
        cone.zPosition = 50
        return cone
    }

    private func damageEnemiesInAttackCone() {
        var deadEnemies: [EnemyNode] = []

        for enemy in enemies {
            guard isEnemyInsideAttackCone(enemy) else { continue }

            if enemy.takeDamage(player.damage) {
                deadEnemies.append(enemy)
            }
        }

        for enemy in deadEnemies {
            enemy.removeFromParent()
            enemies.removeAll { $0 == enemy }

            xp += 10
            hud.updateXP(xp)
        }

        checkForBuffChoice()
    }

    private func isEnemyInsideAttackCone(_ enemy: EnemyNode) -> Bool {
        let dx = enemy.position.x - player.position.x
        let dy = enemy.position.y - player.position.y
        let distance = sqrt(dx * dx + dy * dy)

        guard distance <= attackRange, distance > 0 else {
            return false
        }

        let enemyDirection = CGVector(dx: dx / distance, dy: dy / distance)
        let dot = player.facingVector.dx * enemyDirection.dx + player.facingVector.dy * enemyDirection.dy
        let angleToEnemy = acos(max(-1, min(1, dot)))

        return angleToEnemy <= attackAngle / 2
    }

    private func checkForBuffChoice() {
        if xp >= nextBuffXP && !isChoosingBuff {
            isChoosingBuff = true
            moveVector = .zero
            controls.resetJoystick()
            hud.showBuffChoice(sceneSize: size)
        }
    }

    private func handleBuffTouch(_ location: CGPoint) {
        guard let choice = hud.buffChoice(at: location) else { return }

        switch choice {
        case .damage:
            player.damage += 1

        case .health:
            player.healAndIncreaseMaxHealth(25)
            hud.updateHealth(current: player.health, max: player.maxHealth)
        }

        nextBuffXP += 100
        isChoosingBuff = false
        hud.hideBuffChoice()
    }

    private func currentSpawnInterval() -> TimeInterval {
        max(0.55, 3.0 - survivalTime * 0.035)
    }

    private func currentMaxEnemies() -> Int {
        min(45, 5 + Int(survivalTime / 12))
    }

    private func currentEnemyHealth() -> CGFloat {
        CGFloat(1 + Int(survivalTime / 45))
    }

    private func updateSpawning(deltaTime: TimeInterval) {
        spawnTimer += deltaTime

        if spawnTimer >= currentSpawnInterval() {
            spawnTimer = 0

            if enemies.count < currentMaxEnemies() {
                spawnEnemy()
            }
        }
    }

    private func spawnEnemy() {
        let enemy = EnemyNode(health: currentEnemyHealth())
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

                if player.takeDamage(enemyDamage) {
                    gameOver()
                }

                hud.updateHealth(current: player.health, max: player.maxHealth)
                return
            }
        }
    }

    private func gameOver() {
        isGameOver = true
        moveVector = .zero
        controls.resetJoystick()
        hud.showGameOver()
    }

    private func restartGame() {
        for enemy in enemies {
            enemy.removeFromParent()
        }

        enemies.removeAll()

        xp = 0
        nextBuffXP = 100
        spawnTimer = 0
        survivalTime = 0
        lastUpdateTime = 0
        lastHitTime = 0
        isGameOver = false
        isChoosingBuff = false
        moveVector = .zero

        player.reset()
        cameraNode.position = player.position
        controls.resetJoystick()

        hud.reset()
        hud.updateHealth(current: player.health, max: player.maxHealth)
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

        if isGameOver || isChoosingBuff { return }

        survivalTime += deltaTime
        hud.updateTimer(survivalTime)
        updateSpawning(deltaTime: deltaTime)

        player.position.x += moveVector.dx * playerSpeed * CGFloat(deltaTime)
        player.position.y += moveVector.dy * playerSpeed * CGFloat(deltaTime)

        updateCamera()
        updateGrid()
        updateEnemies(deltaTime: deltaTime)
        checkEnemyHits(currentTime: currentTime)
    }
}
