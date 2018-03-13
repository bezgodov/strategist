import Foundation
import SpriteKit

class BossLevel: NSObject, SKPhysicsContactDelegate {
    
    enum CollisionTypes: UInt32 {
        case enemy = 1
        case character = 2
        case star = 3
    }
    
    /// таймер, который для объектов-врагов
    var timerEnemy: Timer!
    
    /// таймер, который для звёзж
    var timerStar: Timer!
    
    /// Если уровень проигран/выйгран, то запретить любые действия
    var isFinishedLevel = false
    
    /// Текстуры всех объектов
    var textures = [ObjectType: SKTexture]()
    
    var gameScene: GameScene!
    
    /// Количество звёзд, которые должны быть собраны на уровне (задаются в json)
    var countStars = 1
    
    /// Массив, содержащий анимацию движеничя пчелы
    var beeFliesAtlas = [SKTexture]()
    
    /// Скорость всех вражеских объектов (запоминть здесь, ибо нужно будет восстанавливать её после паузы)
    var currentEnemiesSpeed: CGFloat = 1.09
    
    override init() {
        super.init()
        
        gameScene = Model.sharedInstance.gameScene
        gameScene.physicsWorld.contactDelegate = self
        
        gameScene.addChild(gameScene.bossEnemies)
        
        if Model.sharedInstance.gameViewControllerConnect.isHighScoreBonusLevel {
            countStars = 0
        }
        else {
            countStars = gameScene.moves
        }
        
        setCountStars(countStars)
        
        Model.sharedInstance.gameViewControllerConnect.buyLevelButton.isHidden = true
        Model.sharedInstance.gameViewControllerConnect.startRightEdgeOutlet.constant = -35
        Model.sharedInstance.gameViewControllerConnect.startLevel.isHidden = true
        
        texturesSettings()
        
        characterSettings()
        
        bgSettings()
        
        // Добавляем свайпы
        let directions: [UISwipeGestureRecognizerDirection] = [.right, .left, .up, .down]
        for direction in directions {
            let gesture = UISwipeGestureRecognizer(target: self, action: #selector(self.respondToSwipeGesture))
            gesture.direction = direction
            gameScene.view!.addGestureRecognizer(gesture)
        }
        
        if Model.sharedInstance.gameViewControllerConnect.isHighScoreBonusLevel && Model.sharedInstance.isCompletedTurorialBonusLevel == false {
            isFinishedLevel = true
            gameScene.isPaused = true
        }
        else {
            if (Model.sharedInstance.currentLevel != Model.sharedInstance.distanceBetweenSections) || (Model.sharedInstance.currentLevel == Model.sharedInstance.distanceBetweenSections && (Model.sharedInstance.isCompletedLevel(Model.sharedInstance.currentLevel) || Model.sharedInstance.getLevelLives(Model.sharedInstance.currentLevel) < 5)) {
                prepareBossLevel()
            }
            else {
                isFinishedLevel = true
                gameScene.isPaused = true
            }
        }
        
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func prepareBossLevel() {
        Model.sharedInstance.gameViewControllerConnect.goToMenuButton.isEnabled = false
        isFinishedLevel = true
        
        let labelTimeToStart = UILabel(frame: CGRect(x: gameScene.view!.frame.midX - 75, y: gameScene.view!.frame.midY - 75, width: 150, height: 150))
        labelTimeToStart.backgroundColor = UIColor.clear
        labelTimeToStart.font = UIFont(name: "AvenirNext-Bold", size: 48)
        labelTimeToStart.textAlignment = NSTextAlignment.center
        labelTimeToStart.textColor = UIColor.white
        labelTimeToStart.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        gameScene.view!.addSubview(labelTimeToStart)
        
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { (_) in
            self.showCountdown(timeToStart: 3, labelTimeToStart: labelTimeToStart)
        }
    }
    
    func showCountdown(timeToStart: Int, labelTimeToStart: UILabel) {
        
        var koefForScale: CGFloat = 3
        
        if timeToStart == 0 {
            labelTimeToStart.text = "GO"
            koefForScale = 2
        }
        else {
            labelTimeToStart.text = String(timeToStart)
        }
        
        SKTAudio.sharedInstance().playSoundEffect(filename: "Voice_\(labelTimeToStart.text!).wav")
        
        UIView.animate(withDuration: 0.3, animations: {
            labelTimeToStart.transform = CGAffineTransform(scaleX: koefForScale, y: koefForScale)
        }, completion: { (_) in
            Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false, block: { (_) in
                UIView.animate(withDuration: 0.3, animations: {
                    labelTimeToStart.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
                }, completion: { (_) in
                    
                    if timeToStart == 0 {
                        labelTimeToStart.removeFromSuperview()
                        self.timersSettings()
                    }
                    else {
                        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false, block: { (_) in
                            self.showCountdown(timeToStart: timeToStart - 1, labelTimeToStart: labelTimeToStart)
                        })
                    }
                })
            })
        })
    }
    
    /// Функция, которая инициализирует таймеры для генерации объектов
    func timersSettings() {
        gameScene.isPaused = false
        gameScene.objectsLayer.speed = 1
        
        gameScene.bossEnemies.position = gameScene.objectsLayer.position
        gameScene.bossEnemies.zPosition = gameScene.bossEnemies.zPosition
        
        Model.sharedInstance.gameViewControllerConnect.goToMenuButton.isEnabled = true
        isFinishedLevel = false
        
        if Model.sharedInstance.isActivatedBgMusic() {
            SKTAudio.sharedInstance().playBackgroundMusic(filename: "BossBgMusic.mp3")
        }
        
        let timerKoef = Double(Double(Model.sharedInstance.currentLevel / Model.sharedInstance.distanceBetweenSections) / 10)
        
        gameScene.bossEnemies.speed = CGFloat(timerKoef) + 1
        
        if Model.sharedInstance.gameViewControllerConnect.isHighScoreBonusLevel {
            gameScene.bossEnemies.speed = currentEnemiesSpeed
        }
        
        timerEnemy = Timer.scheduledTimer(withTimeInterval: 0.745 - (timerKoef * 1.5), repeats: true) { (_) in
            self.newObject()
        }
        
        timerStar = Timer.scheduledTimer(withTimeInterval: 4.183 - (timerKoef * 1.5), repeats: true) { (_) in
            self.newStar()
        }
    }
    
    func texturesSettings() {
        let objectsTypes = [ObjectType.bee, ObjectType.spinner, ObjectType.star, ObjectType.snail, ObjectType.spaceAlien]
        for type in objectsTypes {
            let texture = SKTexture(imageNamed: type.spriteName)
            textures[type] = texture
        }
        
        beeFliesAtlas = [SKTexture]()
        
        let beeFliespAnimatedAtlas = SKTextureAtlas(named: "BeeFlies")
        if beeFliesAtlas.isEmpty {
            for i in 1...beeFliespAnimatedAtlas.textureNames.count {
                let beeFliesTextureName = "BeeFlies_\(i)"
                beeFliesAtlas.append(beeFliespAnimatedAtlas.textureNamed(beeFliesTextureName))
            }
        }
    }
    
    func characterSettings() {
        let character = gameScene.character
        character.physicsBody = SKPhysicsBody(texture: textures[ObjectType.spaceAlien]!, size: CGSize(width: character.size.width / 1.1, height: character.size.height / 1.15))
        character.physicsBody?.isDynamic = false
        character.physicsBody?.categoryBitMask = CollisionTypes.character.rawValue
        character.physicsBody?.contactTestBitMask = CollisionTypes.enemy.rawValue | CollisionTypes.star.rawValue
        character.physicsBody?.collisionBitMask = 0
        
        character.run(SKAction.repeatForever(SKAction.animate(with: gameScene.playerWalkingFrames, timePerFrame: 0.05, resize: false, restore: true)), withKey: "playerWalking")
    }
    
    func bgSettings() {
        generateBg(sprite: "TopMenuViewBorderDown", row: gameScene.boardSize.row - 1)
        generateBg(sprite: "TopMenuViewBorderUp", row: 0)
    }
    
    func generateBg(sprite: String, row: Int) {
        for index in 0...2 {
            let topMovingSpikes = SKSpriteNode(imageNamed: sprite)
            
            var position = gameScene.pointFor(column: 0, row: row)
            position.x = CGFloat(index) * topMovingSpikes.size.width
            
            if row == 0 {
                position.y -= TileHeight / 2 - topMovingSpikes.size.height / 2
            }
            else {
                position.y += TileHeight / 2 - topMovingSpikes.size.height / 2
            }
            
            topMovingSpikes.position = position
            topMovingSpikes.zPosition = 2
            
            gameScene.objectsLayer.addChild(topMovingSpikes)
            
            topMovingSpikes.run(SKAction.repeatForever(SKAction.sequence([SKAction.moveBy(x: -topMovingSpikes.size.width, y: 0, duration: TimeInterval(5)), SKAction.moveBy(x: topMovingSpikes.size.width, y: 0, duration: 0)])))
        }
    }
    
    func getSizeKoef(_ type: ObjectType) -> CGFloat {
        switch type {
            case ObjectType.star:
                return 0.5
            case ObjectType.snail:
                return 0.8
            default:
                return 0.65
        }
    }
    
    func newObject() {
        let objectsToMove = [ObjectType.bee, ObjectType.spinner, ObjectType.snail]
        let randomObject = objectsToMove[Int(arc4random_uniform(UInt32(objectsToMove.count)))]
        createObject(type: randomObject)
        
    }
    
    func newStar() {
        createObject(type: ObjectType.star)
    }
    
    func createObject(type: ObjectType) {
        let randomPos = Point(column: gameScene.boardSize.column + 3, row: Int(arc4random_uniform(UInt32(gameScene.boardSize.row))))
        
        let sizeKoef: CGFloat = getSizeKoef(type)
        
        let object = SKSpriteNode(imageNamed: type.spriteName)
        object.position = gameScene.pointFor(column: randomPos.column, row: randomPos.row)
        object.zPosition = 4
        object.size = CGSize(width: TileWidth * sizeKoef, height: object.size.height / (object.size.width / (TileWidth * sizeKoef)))
        
        object.physicsBody = SKPhysicsBody(texture: textures[type]!, size: CGSize(width: object.size.width / 1.1, height: object.size.height / 1.15))
        object.physicsBody?.affectedByGravity = false
        object.physicsBody?.collisionBitMask = 0
        object.physicsBody?.contactTestBitMask = CollisionTypes.character.rawValue
        
        gameScene.bossEnemies.addChild(object)
        
        objectExtraParams(type: type, object: object)
        
        let moveToPos = gameScene.pointFor(column: -1, row: randomPos.row)
        let randomSpeed = TimeInterval(CGFloat(arc4random_uniform(3) + 2) + CGFloat(Float(arc4random()) / Float(UINT32_MAX)))
        
        object.run(SKAction.moveTo(x: moveToPos.x, duration: randomSpeed)) {
            object.removeFromParent()
        }
    }
    
    func objectExtraParams(type: ObjectType, object: SKSpriteNode) {
        object.physicsBody?.categoryBitMask = CollisionTypes.enemy.rawValue
        
        if type == ObjectType.spinner {
            object.run(SKAction.repeatForever(SKAction.rotate(byAngle: CGFloat(Double.pi * 2), duration: 1)))
        }
        
        if type == ObjectType.star {
            object.physicsBody?.categoryBitMask = CollisionTypes.star.rawValue
            
            let pulseUp = SKAction.scale(to: 1.225, duration: 1.5)
            let pulseDown = SKAction.scale(to: 1, duration: 1.5)
            let pulse = SKAction.sequence([pulseUp, pulseDown])
            let repeatPulse = SKAction.repeatForever(pulse)
            object.run(repeatPulse)
        }
        
        if type == ObjectType.bee {
            object.run(SKAction.repeatForever(SKAction.animate(with: beeFliesAtlas, timePerFrame: 0.05, resize: false, restore: true)), withKey: "beeFlies")
        }
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        if !isFinishedLevel {
            if contact.bodyA.node?.physicsBody?.categoryBitMask == CollisionTypes.character.rawValue && contact.bodyB.node?.physicsBody?.categoryBitMask == CollisionTypes.star.rawValue {
                if contact.bodyB.node?.parent != nil {
                    pickUpCoin(nodeToRemove: contact.bodyB.node!)
                }
            }
            
            if contact.bodyB.node?.physicsBody?.categoryBitMask == CollisionTypes.character.rawValue && contact.bodyA.node?.physicsBody?.categoryBitMask == CollisionTypes.star.rawValue {
                if contact.bodyA.node?.parent != nil {
                    pickUpCoin(nodeToRemove: contact.bodyA.node!)
                }
            }
            
            if contact.bodyB.node?.physicsBody?.categoryBitMask == CollisionTypes.character.rawValue && contact.bodyA.node?.physicsBody?.categoryBitMask == CollisionTypes.enemy.rawValue {
                loseLevelBoss()
            }
            
            if contact.bodyA.node?.physicsBody?.categoryBitMask == CollisionTypes.character.rawValue && contact.bodyB.node?.physicsBody?.categoryBitMask == CollisionTypes.enemy.rawValue {
                loseLevelBoss()
            }
        }
    }
    
    func pickUpCoin(nodeToRemove: SKNode) {
        nodeToRemove.removeFromParent()
        SKTAudio.sharedInstance().playSoundEffect(filename: "PickUpStar.mp3")
        
        if Model.sharedInstance.gameViewControllerConnect.isHighScoreBonusLevel {
            countStars += 1
        }
        else {
            countStars -= 1
        }
        
        Model.sharedInstance.setCollectedStarsOnBonusLevels()
        
        if Model.sharedInstance.gameViewControllerConnect.isHighScoreBonusLevel {
            increaseEnemiesSpeed()
        }
        
        setCountStars(countStars)
    }
    
    func increaseEnemiesSpeed() {
        currentEnemiesSpeed += 0.01
        gameScene.bossEnemies.speed = currentEnemiesSpeed
    }
    
    func loseLevelBoss() {
        isFinishedLevel = true
        cleanTimers()
        gameScene.loseLevel()
    }
    
    @objc func respondToSwipeGesture(gesture: UIGestureRecognizer) {
        if !isFinishedLevel && !gameScene.isModalWindowOpen {
            if let swipeGesture = gesture as? UISwipeGestureRecognizer {
                var point = gameScene.convertPoint(point: gameScene.character.position)
                
                if swipeGesture.direction == UISwipeGestureRecognizerDirection.right {
                    point.point.column += 1
                }
                if swipeGesture.direction == UISwipeGestureRecognizerDirection.up {
                    point.point.row += 1
                }
                if swipeGesture.direction == UISwipeGestureRecognizerDirection.left {
                    point.point.column -= 1
                }
                if swipeGesture.direction == UISwipeGestureRecognizerDirection.down {
                    point.point.row -= 1
                }
                
                if point.point.column >= 0 && point.point.column < gameScene.boardSize.column && point.point.row >= 0 && point.point.row < gameScene.boardSize.row {
                    
                    DispatchQueue.main.async {
                        SKTAudio.sharedInstance().playSoundEffect(filename: "Swish.wav")
                        self.gameScene.character.run(SKAction.move(to: self.gameScene.pointFor(column: point.point.column, row: point.point.row), duration: 0.2))
                    }
                }
                else {
                    gameScene.shakeView(gameScene.view!, repeatCount: 2, amplitude: 3)
                }
            }
        }
    }
    
    func setCountStars(_ amount: Int) {
        Model.sharedInstance.gameViewControllerConnect.movesRemainLabel.text = String(amount)
        
        if Model.sharedInstance.gameViewControllerConnect.isHighScoreBonusLevel == false {
            isWinLevel(amount)
        }
    }
    
    func isWinLevel(_ starsAmount: Int) {
        if starsAmount <= 0 {
            isFinishedLevel = true
            cleanTimers()
            gameScene.winLevel()
        }
    }
    
    func cleanTimers() {
        if timerEnemy != nil {
            timerEnemy.invalidate()
        }
        
        if timerStar != nil {
            timerStar.invalidate()
        }
        gameScene.bossEnemies.speed = 0
        
        if Model.sharedInstance.isActivatedBgMusic() {
            SKTAudio.sharedInstance().playBackgroundMusic(filename: "BgMusic.mp3")
        }
    }
}
