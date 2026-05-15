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
    private var attackAimVector: CGVector?
    private var attackPreview: SKShapeNode?

    private var enemies: [EnemyNode] = []

    private var xp = 0
    private var buffLevel = 1
    private var nextBuffXP = 100

    private let enemyDamage: CGFloat = 15
    private let enemyHitRadius: CGFloat = 40

    private let playerSpeed: CGFloat = 230
    private let enemySpeed: CGFloat = 90
    private var attackRange: CGFloat = 95
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
                attackAimVector = player.facingVector
                updateAttackAim(with: location)
                showAttackPreview(direction: attackAimVector ?? player.facingVector)
                continue
            }
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isGameOver || isChoosingBuff { return }

        for touch in touches {
            if touch == joystickTouch {
                updateJoystick(with: touch.location(in: cameraNode))
            }

            if touch == attackTouch {
                updateAttackAim(with: touch.location(in: cameraNode))
                showAttackPreview(direction: attackAimVector ?? player.facingVector)
            }
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
                let direction = attackAimVector ?? player.facingVector
                hideAttackPreview()
                performAttack(direction: direction)

                attackTouch = nil
                attackAimVector = nil
                controls.resetAttackAim()
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

    private func updateAttackAim(with location: CGPoint) {
        if let aim = controls.updateAttackAim(with: location) {
            attackAimVector = aim
        }
    }

    private func showAttackPreview(direction: CGVector) {
        if attackPreview == nil {
            let preview = SKShapeNode()
            preview.fillColor = SKColor.systemRed.withAlphaComponent(0.08)
            preview.strokeColor = SKColor.systemRed.withAlphaComponent(0.35)
            preview.lineWidth = 2
            preview.zPosition = 45
            worldNode.addChild(preview)
            attackPreview = preview
        }

        attackPreview?.path = makeAttackConePath(direction: direction)
    }

    private func hideAttackPreview() {
        attackPreview?.removeFromParent()
        attackPreview = nil
    }

    private func performAttack(direction: CGVector) {
        if isGameOver || isChoosingBuff { return }

        player.facingVector = direction

        let attackEffect = createAttackCone(direction: direction)
        worldNode.addChild(attackEffect)

        attackEffect.run(.sequence([
            .fadeOut(withDuration: 0.16),
            .removeFromParent()
        ]))

        controls.pulseAttackControl()
        damageEnemiesInAttackCone(direction: direction)
    }

    private func makeAttackConePath(direction: CGVector) -> CGPath {
        let directionAngle = atan2(direction.dy, direction.dx)
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
        return path
    }

    private func createAttackCone(direction: CGVector) -> SKShapeNode {
        let cone = SKShapeNode(path: makeAttackConePath(direction: direction))
        cone.fillColor = SKColor.systemRed.withAlphaComponent(0.20)
        cone.strokeColor = SKColor.systemRed.withAlphaComponent(0.85)
        cone.lineWidth = 3
        cone.zPosition = 50
        return cone
    }

    private func damageEnemiesInAttackCone(direction: CGVector) {
        var deadEnemies: [EnemyNode] = []

        for enemy in enemies {
            guard isEnemyInsideAttackCone(enemy, direction: direction) else { continue }

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

    private func isEnemyInsideAttackCone(_ enemy: EnemyNode, direction: CGVector) -> Bool {
        let dx = enemy.position.x - player.position.x
        let dy = enemy.position.y - player.position.y
        let distance = sqrt(dx * dx + dy * dy)

        guard distance > 0 else {
            return false
        }

        let enemyRadius = EnemyNode.radius

        if distance > attackRange + enemyRadius {
            return false
        }

        let enemyDirection = CGVector(dx: dx / distance, dy: dy / distance)
        let dot = direction.dx * enemyDirection.dx + direction.dy * enemyDirection.dy
        let angleToEnemy = acos(max(-1, min(1, dot)))

        let angleMargin = atan2(enemyRadius, distance)
        let allowedAngle = attackAngle / 2 + angleMargin

        return angleToEnemy <= allowedAngle
    }

    private func checkForBuffChoice() {
        if xp >= nextBuffXP && !isChoosingBuff {
            isChoosingBuff = true
            moveVector = .zero
            hideAttackPreview()
            controls.resetJoystick()
            controls.resetAttackAim()
            hud.showBuffChoice(sceneSize: size)
        }
    }

    private func handleBuffTouch(_ location: CGPoint) {
        guard let choice = hud.buffChoice(at: location) else { return }

        switch choice {
        case .damage:
            player.damage += 0.5
            attackRange += 8

        case .health:
            player.applyHealthBuff()
            hud.updateHealth(current: player.health, max: player.maxHealth)
        }

        buffLevel += 1
        nextBuffXP += buffLevel * 100

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

    private func checkEnemyHits() {
        var enemiesThatHitPlayer: [EnemyNode] = []

        for enemy in enemies {
            let dx = enemy.position.x - player.position.x
            let dy = enemy.position.y - player.position.y
            let distance = sqrt(dx * dx + dy * dy)

            if distance <= enemyHitRadius {
                enemiesThatHitPlayer.append(enemy)
            }
        }

        for enemy in enemiesThatHitPlayer {
            enemy.removeFromParent()
            enemies.removeAll { $0 == enemy }

            if player.takeDamage(enemyDamage) {
                gameOver()
                break
            }

            hud.updateHealth(current: player.health, max: player.maxHealth)
        }
    }

    private func gameOver() {
        isGameOver = true
        moveVector = .zero
        attackAimVector = nil
        hideAttackPreview()
        controls.resetJoystick()
        controls.resetAttackAim()
        hud.showGameOver()
    }

    private func restartGame() {
        for enemy in enemies {
            enemy.removeFromParent()
        }

        enemies.removeAll()

        xp = 0
        buffLevel = 1
        nextBuffXP = 100
        attackRange = 95
        spawnTimer = 0
        survivalTime = 0
        lastUpdateTime = 0
        isGameOver = false
        isChoosingBuff = false
        moveVector = .zero
        attackAimVector = nil

        hideAttackPreview()

        player.reset()
        cameraNode.position = player.position
        controls.resetJoystick()
        controls.resetAttackAim()

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

        if let direction = attackAimVector {
            showAttackPreview(direction: direction)
        }

        updateEnemies(deltaTime: deltaTime)
        checkEnemyHits()
    }
}
