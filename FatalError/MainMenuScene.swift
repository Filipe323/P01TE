import SpriteKit

final class MainMenuScene: SKScene {

    private let titleLabel = SKLabelNode(text: "Fatal Error")
    private let bestTimeLabel = SKLabelNode(text: "Melhor Tempo: 00:00")
    
    private let playButton = SKShapeNode(rectOf: CGSize(width: 230, height: 64), cornerRadius: 14)
    private let playLabel = SKLabelNode(text: "JOGAR")

    private let quitButton = SKShapeNode(rectOf: CGSize(width: 230, height: 56), cornerRadius: 14)
    private let quitLabel = SKLabelNode(text: "SAIR")

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.09, green: 0.11, blue: 0.15, alpha: 1)

        setupTitle()
        setupBestTime()
        setupPlayButton()
        setupQuitButton()
        layoutMenu()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        layoutMenu()
    }

    private func setupTitle() {
        titleLabel.fontName = "AvenirNext-Bold"
        titleLabel.fontSize = 42
        titleLabel.fontColor = .white
        titleLabel.verticalAlignmentMode = .center
        titleLabel.zPosition = 10
        addChild(titleLabel)
    }
    
    private func setupBestTime() {
        let bestTime = UserDefaults.standard.double(forKey: "BestSurvivalTime")
        let minutes = Int(bestTime) / 60
        let seconds = Int(bestTime) % 60
        
        bestTimeLabel.text = String(format: "Melhor Tempo: %02d:%02d", minutes, seconds)
        bestTimeLabel.fontName = "AvenirNext-Bold"
        bestTimeLabel.fontSize = 20
        bestTimeLabel.fontColor = .systemYellow
        bestTimeLabel.verticalAlignmentMode = .center
        bestTimeLabel.zPosition = 10
        addChild(bestTimeLabel)
    }

    private func setupPlayButton() {
        playButton.fillColor = SKColor.systemBlue.withAlphaComponent(0.9)
        playButton.strokeColor = .white
        playButton.lineWidth = 2
        playButton.zPosition = 10
        addChild(playButton)

        playLabel.fontName = "AvenirNext-Bold"
        playLabel.fontSize = 24
        playLabel.fontColor = .white
        playLabel.verticalAlignmentMode = .center
        playLabel.zPosition = 11
        addChild(playLabel)
    }

    private func setupQuitButton() {
        quitButton.fillColor = SKColor.black.withAlphaComponent(0.35)
        quitButton.strokeColor = SKColor.white.withAlphaComponent(0.7)
        quitButton.lineWidth = 2
        quitButton.zPosition = 10
        addChild(quitButton)

        quitLabel.fontName = "AvenirNext-Bold"
        quitLabel.fontSize = 22
        quitLabel.fontColor = .white
        quitLabel.verticalAlignmentMode = .center
        quitLabel.zPosition = 11
        addChild(quitLabel)
    }

    private func layoutMenu() {
        titleLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 + 105)
        bestTimeLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 + 60)

        playButton.position = CGPoint(x: size.width / 2, y: size.height / 2 - 10)
        playLabel.position = playButton.position

        quitButton.position = CGPoint(x: size.width / 2, y: size.height / 2 - 92)
        quitLabel.position = quitButton.position
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }

        let location = touch.location(in: self)

        if playButton.contains(location) {
            startGame()
        } else if quitButton.contains(location) {
            exit(0)
        }
    }

    private func startGame() {
        let gameScene = GameScene(size: size)
        gameScene.scaleMode = scaleMode

        let transition = SKTransition.fade(withDuration: 0.25)
        view?.presentScene(gameScene, transition: transition)
    }
}
