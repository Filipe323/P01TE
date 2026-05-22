
import Foundation

final class WaveManager {
    
    private(set) var currentWave: Int = 1
    private(set) var isRestingBetweenWaves: Bool = false
    
    private var totalEnemiesInCurrentWave: Int = 0
    private var enemiesSpawnedInCurrentWave: Int = 0
    private var activeEnemiesCount: Int = 0
    
    private var spawnTimer: TimeInterval = 0
    private let restDuration: TimeInterval = 3.0 // Tempo de descanso entre rondas
    private var restTimer: TimeInterval = 0
    
    // Callbacks para comunicar com o GameScene
    var onSpawnEnemy: (() -> Void)?
    var onWaveComplete: ((Int) -> Void)?
    var onNewWaveStart: ((Int) -> Void)?
    var onRestTimerUpdate: ((TimeInterval) -> Void)?
    
    init() {
        startWave(1)
    }
    
    func startWave(_ wave: Int) {
        currentWave = wave
        isRestingBetweenWaves = false
        enemiesSpawnedInCurrentWave = 0
        activeEnemiesCount = 0
        spawnTimer = 0
        
        // Determina o total de inimigos para esta ronda usando o EnemySpawner (corrigido aqui!)
        totalEnemiesInCurrentWave = EnemySpawner.totalEnemiesForWave(wave: wave)
        
        onNewWaveStart?(currentWave)
    }
    
    func update(deltaTime: TimeInterval) {
        if isRestingBetweenWaves {
            updateRestTimer(deltaTime: deltaTime)
            return
        }
        
        updateSpawning(deltaTime: deltaTime)
    }
    
    private func updateSpawning(deltaTime: TimeInterval) {
        // Se ainda não gerámos todos os inimigos da ronda atual
        if enemiesSpawnedInCurrentWave < totalEnemiesInCurrentWave {
            spawnTimer += deltaTime
            
            let interval = EnemySpawner.spawnInterval(wave: currentWave)
            if spawnTimer >= interval {
                spawnTimer = 0
                enemiesSpawnedInCurrentWave += 1
                activeEnemiesCount += 1
                
                // Pede ao GameScene para fazer o spawn físico do inimigo
                onSpawnEnemy?()
            }
        }
    }
    
    private func updateRestTimer(deltaTime: TimeInterval) {
        restTimer -= deltaTime
        onRestTimerUpdate?(max(0, restTimer))
        
        if restTimer <= 0 {
            startWave(currentWave + 1)
        }
    }
    
    /// Chamado pelo GameScene quando um inimigo é derrotado ou atinge o jogador
    func reportEnemyRemoved() {
        guard !isRestingBetweenWaves else { return }
        
        activeEnemiesCount = max(0, activeEnemiesCount - 1)
        
        // Condição de vitória da ronda: todos os inimigos gerados e todos os inimigos mortos
        if enemiesSpawnedInCurrentWave >= totalEnemiesInCurrentWave && activeEnemiesCount == 0 {
            endWave()
        }
    }
    
    private func endWave() {
        isRestingBetweenWaves = true
        restTimer = restDuration
        onWaveComplete?(currentWave)
    }
    
    func reset() {
        currentWave = 1
        startWave(1)
    }
}
