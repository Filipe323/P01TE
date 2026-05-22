import SpriteKit

enum BuffChoice {
    case damage
    case health
}

enum PauseChoice {
    case resume
    case quit
}

final class GameHUDNode: SKNode {

    private let xpLabel = SKLabelNode(text: "XP: 0")
    private let timerLabel = SKLabelNode(text: "00:00")

    private let healthBarBackground = SKShapeNode(rectOf: CGSize(width: 220, height: 12), cornerRadius: 6)
    private let healthBarFill = SKSpriteNode(color: .systemGreen, size: CGSize(width: 220, height: 10))
    private let dangerBorder = SKShapeNode()

    // UI da Pausa
    private let pauseButton = SKShapeNode(rectOf: CGSize(width: 44, height: 44), cornerRadius: 8)
    private let pauseIcon = SKLabelNode(text: "II")
    private var pauseOverlay: SKShapeNode?
    private var resumeButton: SKShapeNode?
    private var quitMenuButton: SKShapeNode?

    private var gameOverLabel: SKLabelNode?
    private var restartButton: SKShapeNode?
    private var restartLabel: SKLabelNode?

    private var buffOverlay: SKShapeNode?
    private var buffTitleLabel: SKLabelNode?
    private var damageBuffButton: SKShapeNode?
    private var damageBuffLabel: SKLabelNode?
    private var healthBuffButton: SKShapeNode?
    private var healthBuffLabel: SKLabelNode?

    override init() {
        super.init()

        setupDangerBorder()
        setupLabels()
        setupHealthBar()
        setupPauseButton()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupDangerBorder() {
        dangerBorder.strokeColor = SKColor.systemRed.withAlphaComponent(0.75)
        dangerBorder.fillColor = .clear
        dangerBorder.lineWidth = 14
        dangerBorder.zPosition = 90
        dangerBorder.alpha = 0
        addChild(dangerBorder)
    }

    private func setupLabels() {
        xpLabel.fontName = "AvenirNext-Bold"
        xpLabel.fontSize = 22
        xpLabel.fontColor = .white
        xpLabel.horizontalAlignmentMode = .left
        xpLabel.verticalAlignmentMode = .top
        xpLabel.zPosition = 100
        addChild(xpLabel)

        timerLabel.fontName = "AvenirNext-Bold"
        timerLabel.fontSize = 22
        timerLabel.fontColor = .white
        timerLabel.horizontalAlignmentMode = .right
        timerLabel.verticalAlignmentMode = .top
        timerLabel.zPosition = 100
        addChild(timerLabel)
    }

    private func setupHealthBar() {
        healthBarBackground.fillColor = SKColor.black.withAlphaComponent(0.35)
        healthBarBackground.strokeColor = SKColor.white.withAlphaComponent(0.25)
        healthBarBackground.lineWidth = 1
        healthBarBackground.zPosition = 100
        addChild(healthBarBackground)

        healthBarFill.anchorPoint = CGPoint(x: 0, y: 0.5)
        healthBarFill.zPosition = 101
        addChild(healthBarFill)
    }
    
    private func setupPauseButton() {
        pauseButton.fillColor = SKColor.white.withAlphaComponent(0.15)
        pauseButton.strokeColor = SKColor.white.withAlphaComponent(0.4)
        pauseButton.lineWidth = 1.5
        pauseButton.zPosition = 100
        addChild(pauseButton)
        
        pauseIcon.fontName = "AvenirNext-Bold"
        pauseIcon.fontSize = 18
        pauseIcon.fontColor = .white
        pauseIcon.verticalAlignmentMode = .center
        pauseIcon.zPosition = 101
        addChild(pauseIcon)
    }

    func layout(sceneSize: CGSize) {
        let halfWidth = sceneSize.width / 2
        let halfHeight = sceneSize.height / 2

        xpLabel.position = CGPoint(x: -halfWidth + 25, y: halfHeight - 25)
        timerLabel.position = CGPoint(x: halfWidth - 25, y: halfHeight - 25)

        pauseButton.position = CGPoint(x: 0, y: halfHeight - 35)
        pauseIcon.position = pauseButton.position

        let healthPosition = CGPoint(x: 0, y: -halfHeight + 28)
        healthBarBackground.position = healthPosition
        healthBarFill.position = CGPoint(x: healthPosition.x - 110, y: healthPosition.y)

        let borderInset: CGFloat = 7
        dangerBorder.path = CGPath(
            rect: CGRect(
                x: -halfWidth + borderInset,
                y: -halfHeight + borderInset,
                width: sceneSize.width - borderInset * 2,
                height: sceneSize.height - borderInset * 2
            ),
            transform: nil
        )
    }
    
    func isPauseHit(_ location: CGPoint) -> Bool {
        pauseButton.contains(location)
    }

    func updateXP(_ xp: Int) {
        xpLabel.text = "XP: \(xp)"
    }

    func updateTimer(_ survivalTime: TimeInterval) {
        let totalSeconds = Int(survivalTime)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        timerLabel.text = String(format: "%02d:%02d", minutes, seconds)
    }

    func updateHealth(current: CGFloat, max: CGFloat) {
        let healthPercent = Swift.max(0, current / max)
        healthBarFill.size.width = 220 * healthPercent

        if healthPercent > 0.55 {
            healthBarFill.color = .systemGreen
        } else if healthPercent > 0.25 {
            healthBarFill.color = .systemYellow
        } else {
            healthBarFill.color = .systemRed
        }

        updateDangerBorder(healthPercent: healthPercent)
    }

    private func updateDangerBorder(healthPercent: CGFloat) {
        if healthPercent <= 0.25 && healthPercent > 0 {
            if dangerBorder.action(forKey: "dangerPulse") == nil {
                dangerBorder.run(.repeatForever(.sequence([
                    .fadeAlpha(to: 0.85, duration: 0.35),
                    .fadeAlpha(to: 0.25, duration: 0.45)
                ])), withKey: "dangerPulse")
            }
        } else {
            dangerBorder.removeAction(forKey: "dangerPulse")
            dangerBorder.run(.fadeAlpha(to: 0, duration: 0.18))
        }
    }

    // MARK: - Menus Overlays (Corrigido para limpar tudo via Name)
    
    func showPauseMenu(sceneSize: CGSize) {
        let overlay = SKShapeNode(rectOf: sceneSize)
        overlay.fillColor = SKColor.black.withAlphaComponent(0.75)
        overlay.strokeColor = .clear
        overlay.zPosition = 300
        overlay.position = .zero
        overlay.name = "pauseNode" // Identificador para remoção
        addChild(overlay)
        pauseOverlay = overlay

        let title = SKLabelNode(text: "JOGO EM PAUSA")
        title.fontName = "AvenirNext-Bold"
        title.fontSize = 36
        title.fontColor = .white
        title.verticalAlignmentMode = .center
        title.zPosition = 301
        title.position = CGPoint(x: 0, y: 70)
        title.name = "pauseNode"
        addChild(title)
        
        let resume = SKShapeNode(rectOf: CGSize(width: 220, height: 60), cornerRadius: 12)
        resume.fillColor = SKColor.systemBlue.withAlphaComponent(0.9)
        resume.strokeColor = .white
        resume.lineWidth = 2
        resume.zPosition = 301
        resume.position = CGPoint(x: 0, y: -10)
        resume.name = "pauseNode"
        addChild(resume)
        resumeButton = resume
        
        let resumeLabel = SKLabelNode(text: "CONTINUAR")
        resumeLabel.fontName = "AvenirNext-Bold"
        resumeLabel.fontSize = 20
        resumeLabel.fontColor = .white
        resumeLabel.verticalAlignmentMode = .center
        resumeLabel.zPosition = 302
        resumeLabel.position = resume.position
        resumeLabel.name = "pauseNode"
        addChild(resumeLabel)

        let quit = SKShapeNode(rectOf: CGSize(width: 220, height: 60), cornerRadius: 12)
        quit.fillColor = SKColor.systemRed.withAlphaComponent(0.8)
        quit.strokeColor = .white
        quit.lineWidth = 2
        quit.zPosition = 301
        quit.position = CGPoint(x: 0, y: -85)
        quit.name = "pauseNode"
        addChild(quit)
        quitMenuButton = quit

        let quitLabel = SKLabelNode(text: "SAIR PARA O MENU")
        quitLabel.fontName = "AvenirNext-Bold"
        quitLabel.fontSize = 18
        quitLabel.fontColor = .white
        quitLabel.verticalAlignmentMode = .center
        quitLabel.zPosition = 302
        quitLabel.position = quit.position
        quitLabel.name = "pauseNode"
        addChild(quitLabel)
    }
    
    func hidePauseMenu() {
        // Procura e remove do ecrã absolutamente tudo o que se chama "pauseNode"
        self.enumerateChildNodes(withName: "pauseNode") { node, _ in
            node.removeFromParent()
        }
        
        pauseOverlay = nil
        resumeButton = nil
        quitMenuButton = nil
    }
    
    func pauseChoice(at location: CGPoint) -> PauseChoice? {
        if resumeButton?.contains(location) == true { return .resume }
        if quitMenuButton?.contains(location) == true { return .quit }
        return nil
    }

    func showGameOver() {
        dangerBorder.removeAction(forKey: "dangerPulse")
        dangerBorder.alpha = 0

        let label = SKLabelNode(text: "GAME OVER")
        label.fontName = "AvenirNext-Bold"
        label.fontSize = 42
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.zPosition = 200
        label.position = CGPoint(x: 0, y: 45)
        addChild(label)
        gameOverLabel = label

        let button = SKShapeNode(rectOf: CGSize(width: 210, height: 62), cornerRadius: 14)
        button.fillColor = SKColor.systemBlue.withAlphaComponent(0.9)
        button.strokeColor = .white
        button.lineWidth = 2
        button.zPosition = 200
        button.position = CGPoint(x: 0, y: -35)
        addChild(button)
        restartButton = button

        let buttonLabel = SKLabelNode(text: "REINICIAR")
        buttonLabel.fontName = "AvenirNext-Bold"
        buttonLabel.fontSize = 22
        buttonLabel.fontColor = .white
        buttonLabel.verticalAlignmentMode = .center
        buttonLabel.zPosition = 201
        buttonLabel.position = button.position
        addChild(buttonLabel)
        restartLabel = buttonLabel
    }

    func isRestartHit(_ location: CGPoint) -> Bool {
        restartButton?.contains(location) == true
    }

    func hideGameOver() {
        gameOverLabel?.removeFromParent()
        restartButton?.removeFromParent()
        restartLabel?.removeFromParent()
        gameOverLabel = nil
        restartButton = nil
        restartLabel = nil
    }

    func showBuffChoice(sceneSize: CGSize) {
        let overlay = SKShapeNode(rectOf: sceneSize)
        overlay.fillColor = SKColor.black.withAlphaComponent(0.62)
        overlay.strokeColor = .clear
        overlay.zPosition = 250
        overlay.position = .zero
        addChild(overlay)
        buffOverlay = overlay

        let title = SKLabelNode(text: "Escolhe um buff")
        title.fontName = "AvenirNext-Bold"
        title.fontSize = 32
        title.fontColor = .white
        title.verticalAlignmentMode = .center
        title.zPosition = 251
        title.position = CGPoint(x: 0, y: 85)
        addChild(title)
        buffTitleLabel = title

        let damageButton = SKShapeNode(rectOf: CGSize(width: 250, height: 70), cornerRadius: 12)
        damageButton.fillColor = SKColor.systemRed.withAlphaComponent(0.9)
        damageButton.strokeColor = .white
        damageButton.lineWidth = 2
        damageButton.zPosition = 251
        damageButton.position = CGPoint(x: -145, y: -20)
        addChild(damageButton)
        damageBuffButton = damageButton

        let damageLabel = SKLabelNode(text: "+ Dano/Range")
        damageLabel.fontName = "AvenirNext-Bold"
        damageLabel.fontSize = 22
        damageLabel.fontColor = .white
        damageLabel.verticalAlignmentMode = .center
        damageLabel.zPosition = 252
        damageLabel.position = damageButton.position
        addChild(damageLabel)
        damageBuffLabel = damageLabel

        let healthButton = SKShapeNode(rectOf: CGSize(width: 230, height: 70), cornerRadius: 12)
        healthButton.fillColor = SKColor.systemGreen.withAlphaComponent(0.9)
        healthButton.strokeColor = .white
        healthButton.lineWidth = 2
        healthButton.zPosition = 251
        healthButton.position = CGPoint(x: 145, y: -20)
        addChild(healthButton)
        healthBuffButton = healthButton

        let healthLabel = SKLabelNode(text: "+ Vida")
        healthLabel.fontName = "AvenirNext-Bold"
        healthLabel.fontSize = 24
        healthLabel.fontColor = .white
        healthLabel.verticalAlignmentMode = .center
        healthLabel.zPosition = 252
        healthLabel.position = healthButton.position
        addChild(healthLabel)
        healthBuffLabel = healthLabel
    }

    func buffChoice(at location: CGPoint) -> BuffChoice? {
        if damageBuffButton?.contains(location) == true { return .damage }
        if healthBuffButton?.contains(location) == true { return .health }
        return nil
    }

    func hideBuffChoice() {
        buffOverlay?.removeFromParent()
        buffTitleLabel?.removeFromParent()
        damageBuffButton?.removeFromParent()
        damageBuffLabel?.removeFromParent()
        healthBuffButton?.removeFromParent()
        healthBuffLabel?.removeFromParent()

        buffOverlay = nil
        buffTitleLabel = nil
        damageBuffButton = nil
        damageBuffLabel = nil
        healthBuffButton = nil
        healthBuffLabel = nil
    }

    func reset() {
        hideGameOver()
        hideBuffChoice()
        hidePauseMenu()
        updateXP(0)
        updateTimer(0)
        dangerBorder.removeAction(forKey: "dangerPulse")
        dangerBorder.alpha = 0
    }
}
