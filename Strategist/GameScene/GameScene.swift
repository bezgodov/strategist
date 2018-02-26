import GoogleMobileAds
import Flurry_iOS_SDK
import Foundation
import SpriteKit

var TileWidth: CGFloat!
var TileHeight: CGFloat!

class GameScene: SKScene {
    
    /// Массив перемещающихся объектов
    var movingObjects = Set<Object>()
    
    /// Массив статичных объектов
    var staticObjects = Set<StaticObject>()
    
    /// Текущий ход (для всего мира)
    var move: Int = 0
    
    /// Текущий ход, который не изменяется и только увеличивается на 1 за один ход
    var absoluteMove: Int = 0
    
    /// Доступное количество ходов
    var moves: Int = 0
    
    /// Количество драгоценных камней, которые можно получить за уровень
    var gemsForLevel: Int = 1
    
    /// Обязательно ли использовать все ходы на уровне?
    var isNecessaryUseAllMoves: Bool = false
    
    /// Координаты финишного блока
    var finish: Point = Point(column: 0, row: 0)
    
    /// Спрайт для финиша (драг. камень)
    var finishSprite: SKSpriteNode!
    
    /// Координаты начальной позиции ГП
    var characterStart: Point = Point(column: 0, row: 0)
    
    /// Размеры игрового поля
    var boardSize: Point = Point(column: 0, row: 0)
   
    /// Главный персонаж (ГП)
    var character: Character = Character()
    
    /// Вспомогательная переменная для выбора траектории с помощью TouchedMoved
    var checkChoosingPath: Point = Point(column: 0, row: 0)
    
    /// Вспомогательная переменная для выбора траектории с помощью TouchedMoved
    var checkChoosingPathArray: [Point] = []
    
    /// Вспомогательная переменная для выбора траектории с помощью TouchedMoved
    var addedLastPointByMove: Bool = false
    
    /// Вспомогательная переменная для, которая определяет был ли последний блок удалён с помощью TouchedMoved
    var removedLastPointByMove: Bool = false
    
    /// Количество звёзд на уровне, которые необходимо собрать
    var stars: Int = 0
    
    /// Основной таймер игрового поля
    var gameTimer = Timer()
    
    /// Таймер для предпросмотра сцены
    var previewTimer = Timer()
    
    /// Слой, на который добавляются все остальные Nodes
    var gameLayer = SKSpriteNode()
    
    /// Слой, на который добавляются все объекты
    let objectsLayer = SKNode()
    
    /// Нод, на который добавляются все враги на босс-уровне
    let bossEnemies = SKNode()
    
    /// Слой, на который добавляются спрайты ячеек
    let tilesLayer = SKNode()
    
    /// View для кнопок (жизней)
    var heartsStackView: UIStackView = UIStackView()
    
    /// Переменная, которая запоминает последнюю кнопку (жизней) для дальнейшего её удаления
    var lastHeartButton: UIButton!
    
    /// View, который выводит информацию об объекте
    var objectInfoView: UIView?
    
    /// Последний выбранный объект
    var objectTypeClickedLast: ObjectType?
    
    /// Полсдений клик, который был сделан на игровом поле
    var lastClickOnGameBoard = Point(column: -1, row: -1)
    
    /// Если последний там был сделан долгим зажатием
    var isLastTapLongPress = false
    
    /// Флаг, указывающий на начало раунда
    var gameBegan = false
    
    /// Если ГП перемещается на мост (проигрышная позиция)
    var isNextCharacterMoveAtBridgeLose = false
    
    /// Если вначале уровня необходимо показать обучение
    var isLevelWithTutorial = false
    
    /// Выйгрышная траекторая, подсказка (из json)
    var winningPath = [Point]()
    
    /// Label, который хранит текущее кол-во драг. камней
    var countGemsModalWindowLabel: UILabel!
    
    /// Переменные для модального окна
    var mainBgTutorial, modalWindowBg, modalWindow: UIView!
    
    /// Переменная для спрайта, который отображает крестик на последней точке выбранного пути
    var lastPathStepSprite: SKSpriteNode!
    
    /// Уровень, который находится в конце секции
    var bossLevel: BossLevel?
    
    /// Показывается ли сейчас предпросмотр
    var isPreviewing = false
    
    /// Проигран ли уровень
    var isLosedLevel = false
    
    /// Ключи, которые были собраны на сцене
    var keysInBag = [LockKeyColor]()
    
    /// Объекты, которые были собраны на сцене
    var collectedObjects = [StaticObject]()
    
    /// Количество кнопок на уровне
    var buttonsOnLevel = 0
    
    /// true, если модальное окно открыто
    var isModalWindowOpen = false
    
    /// Переменная, которая содержит все текстуры для анимации ГП
    var playerWalkingFrames = [SKTexture]()
    
    /// Баннер, который всплывает после каждого 5-го проигранного уровня
    var interstitial: GADInterstitial!
    
    override func didMove(to view: SKView) {
        
        self.backgroundColor = UIColor.white
        
        sceneSettings()
        
        createLevel()
        
        // Если началось обучение
        if isLevelWithTutorial && !Model.sharedInstance.isCompletedLevel(Model.sharedInstance.currentLevel) {
            alphaBlackLayerPresent(alpha: 0.35)
        }
    }
    
    /* Настройка сцены */
    func sceneSettings() {
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressed))
        longPressRecognizer.minimumPressDuration = 0.65
        longPressRecognizer.allowableMovement = 15
        
        self.view?.addGestureRecognizer(longPressRecognizer)
    
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
    }
    
    /// Функция, которая генерирует задний фон
    func createBg() {
        let bgNode = SKNode()
        // Отображаем слой с объектами по центру экрана
        bgNode.position = CGPoint(x: -self.size.width, y: -self.size.height / 2)
        addTilesBg(toNode: bgNode)
        
        bgNode.zRotation = CGFloat(-25 * Double.pi / 180)
        
        // На босс-уровне убираем ГП на заднем фоне
        if Model.sharedInstance.currentLevel % Model.sharedInstance.distanceBetweenSections != 0 {
            _ = Timer.scheduledTimer(withTimeInterval: 15, repeats: true, block: { (_) in
                let characterBg = SKSpriteNode(texture: self.playerWalkingFrames[1])
                characterBg.zPosition = 4
                characterBg.alpha = 0.125
                characterBg.position = self.pointFor(column: -1, row: 0)
                characterBg.size = CGSize(width: TileWidth * 0.5, height: (characterBg.texture?.size().height)! / ((characterBg.texture?.size().width)! / (TileWidth * 0.5)))
                characterBg.run(SKAction.repeatForever(SKAction.animate(with: self.playerWalkingFrames, timePerFrame: 0.05, resize: false, restore: true)), withKey: "playerWalking")
                bgNode.addChild(characterBg)
                
                var moves = [Point]()
                for row in -2...self.boardSize.row + 5 {
                    
                    let randLimit = self.boardSize.row + 1
                    let rand = arc4random_uniform(UInt32(randLimit))
                    
                    if moves.count > 0 {
                        while moves.last?.column != Int(rand) {
                            let newRowValue = moves.last!.column + ((moves.last!.column < Int(rand)) ? 1 : -1)
                            moves.append(Point(column: newRowValue, row: moves.last!.row))
                        }
                    }
                    moves.append(Point(column: Int(rand), row: row))
                }
                
                var move = 0
                _ = Timer.scheduledTimer(withTimeInterval: 0.65, repeats: true, block: { (timer) in
                    if move < moves.count {
                        
                        if move > 0 {
                            let characterDirectionWalks = self.getObjectDirection(from: moves[move - 1], to: moves[move])
                            
                            if characterDirectionWalks == RotationDirection.right {
                                characterBg.run(SKAction.scaleX(to: 1, duration: 0.25))
                            }
                            
                            if characterDirectionWalks == RotationDirection.left {
                                characterBg.run(SKAction.scaleX(to: -1, duration: 0.25))
                            }
                        }
                        
                        characterBg.run(SKAction.move(to: self.pointFor(column: moves[move].column, row: moves[move].row), duration: 0.5), completion: {
                            move += 1
                            
                            if move == moves.count {
                                characterBg.removeFromParent()
                                timer.invalidate()
                            }
                        })
                    }
                })
            })
        }
        
        bgNode.zPosition = -5
        gameLayer.addChild(bgNode)
    }
    
    func createLevel() {
        if (Model.sharedInstance.getLevelLives(Model.sharedInstance.currentLevel) > 0) || (Model.sharedInstance.currentLevel % Model.sharedInstance.distanceBetweenSections == 0) {
            
            goToLevel(Model.sharedInstance.currentLevel)
            
            createBg()
        
            let playerAnimatedAtlas = SKTextureAtlas(named: "PlayerWalks")
            var walkFrames = [SKTexture]()
        
            /// Задаём анимацию для ГП
            let numImages = playerAnimatedAtlas.textureNames.count
            for i in 1...numImages {
                let playerTextureName = "PlayerWalks_\(i)"
                walkFrames.append(playerAnimatedAtlas.textureNamed(playerTextureName))
            }
            
            playerWalkingFrames = walkFrames
            
            // Инициализируем ГП
            character = Character(imageNamed: "PlayerStaysFront")
            character.zPosition = 8
            character.position = pointFor(column: characterStart.column, row: characterStart.row)
            character.size = CGSize(width: TileWidth * 0.5, height: (character.texture?.size().height)! / ((character.texture?.size().width)! / (TileWidth * 0.5)))
            character.moves.append(characterStart)
            objectsLayer.addChild(character)
        
            /// Флаг, чтобы Spinner крутились в разные стороны
            var lastDirectionSpinnerLeft: CGFloat = 1
            var lastAngleMovesToExplodeLabel: CGFloat = arc4random_uniform(2) == 1 ? 0 : -60
            // Инициализируем статичные объекты
            for object in staticObjects {
                object.position = pointFor(column: object.point.column, row: object.point.row)
                objectsLayer.addChild(object)
                
                // Инициализируем Label для объекта "бомба"
                if object.type == ObjectType.bomb {
                    let movesToExplodeLabel = SKLabelNode(text: String(object.movesToExplode))
                    movesToExplodeLabel.name = "movesToExplode"
                    movesToExplodeLabel.zPosition = 1
                    movesToExplodeLabel.fontColor = UIColor.init(red: 250 / 255, green: 153 / 255, blue: 137 / 255, alpha: 1)
                    movesToExplodeLabel.fontSize = 32
                    
                    if Model.sharedInstance.isDeviceIpad() {
                            movesToExplodeLabel.fontSize *= 2.5
                    }
                    
                    movesToExplodeLabel.fontName = "AvenirNext-Bold"
                    movesToExplodeLabel.horizontalAlignmentMode = .center
                    movesToExplodeLabel.verticalAlignmentMode = .center
                    movesToExplodeLabel.position.y -= 2
                    movesToExplodeLabel.position.x += 1
                    
                    if lastAngleMovesToExplodeLabel == 0 {
                        movesToExplodeLabel.zRotation = CGFloat(Double(35) * Double.pi / 180)
                    }
                    else {
                        movesToExplodeLabel.zRotation += CGFloat(Double(25) * Double.pi / 180)
                    }
                    
                    object.zRotation = CGFloat(Double(lastAngleMovesToExplodeLabel) * Double.pi / 180)
                    object.addChild(movesToExplodeLabel)
                    
                    lastAngleMovesToExplodeLabel = (lastAngleMovesToExplodeLabel + 60) * -1
                }
                
                if object.type == ObjectType.spinner {
                    object.run(SKAction.repeatForever(SKAction.rotate(byAngle: lastDirectionSpinnerLeft * CGFloat(Double.pi * 2), duration: 1)))
                    lastDirectionSpinnerLeft *= -1
                }
                
                if object.type == ObjectType.star {
                    let pulseUp = SKAction.scale(to: 1.225, duration: 1.5)
                    let pulseDown = SKAction.scale(to: 1, duration: 1.5)
                    let pulse = SKAction.sequence([pulseUp, pulseDown])
                    let repeatPulse = SKAction.repeatForever(pulse)
                    object.run(repeatPulse)
                }
                
                if object.type == ObjectType.bridge {
                    // Поворачиваем мост в сторону, которая задана в json
                    object.zRotation += CGFloat(Double(object.rotate.rawValue - 1) * 90 * Double.pi / 180)
                    
                    /// Переменная, которая определяет на сколько нужно уменьшить размер стен
                    let downScale: CGFloat = 2.5
                    
                    // Коэффициенты, которые определяют в какую сторону от блока сместить стену
                    let xPositions = [1, -1, -1, 1]
                    var yPositions = [-1, 1, 1, -1]
                    
                    var scaleFactorForIpad: CGFloat = 1
                    
                    if Model.sharedInstance.isDeviceIpad() {
                        scaleFactorForIpad = 2.5
                    }
                    
                    /// Размер стен (если вертикаль стоит по умолчанию, то стены справа и слева)
                    var defaultSize = [CGSize(width: 5, height: TileHeight / (downScale / 2)), CGSize(width: 0, height: 5)]
                    
                    var defaultAnchorPoint = [CGPoint(x: 1, y: 0), CGPoint(x: 0, y: 1), CGPoint(x: 0, y: 1), CGPoint(x: 1, y: 0)]
                    
                    
                    // Если у моста установлена вертикаль по умолчанию, то подстраиваем коэффициенты
                    if object.rotate.rawValue == 0 || object.rotate.rawValue == 2 {
                        defaultSize = [CGSize(width: 5 * scaleFactorForIpad, height: 0), CGSize(width: TileWidth / (downScale / 2), height: 5 * scaleFactorForIpad)]
                        defaultAnchorPoint = [CGPoint(x: 1, y: 1), CGPoint(x: 0, y: 0), CGPoint(x: 0, y: 0), CGPoint(x: 1, y: 1)]
                        yPositions = [1, -1, -1, 1]
                    }
                    
                    /// Координаты блока (моста)
                    let bridgeTilePos = pointFor(column: object.point.column, row: object.point.row)
                    
                    /// Кол-во стен вокруг блока (две скрытых)
                    let countOfWalls = 4
                    
                    for index in 0..<countOfWalls {
                        let bridgeWall = SKSpriteNode(color: UIColor(red: 32/255, green: 149/255, blue: 242/255, alpha: 1), size: defaultSize[index % defaultSize.count])
                        
                        bridgeWall.position = CGPoint(x: bridgeTilePos.x + (TileWidth / downScale) * CGFloat(xPositions[index]), y: bridgeTilePos.y + (TileHeight / downScale) * CGFloat(yPositions[index]))
                        bridgeWall.anchorPoint = defaultAnchorPoint[index]
                        
                        bridgeWall.zPosition = 4
                        // Имя c hash, т.к. на сцене может быть больше одного моста, прикрепить к самому мосту не получается, ибо он каждый ход крутится и, соответственно, всё вокруг
                        bridgeWall.name = "BridgeWall_\(index)-Object_\(object.hash)"
                        objectsLayer.addChild(bridgeWall)
                    }
                }
                
                if object.type == ObjectType.arrow {
                    // Поворачиваем стрелку в сторону, которая задана в json
                    object.zRotation += CGFloat(Double(object.rotate.rawValue - 1) * 90 * Double.pi / 180)
                    
                    if object.rotate == RotationDirection.right {
                        object.position.x = object.position.x - TileWidth / 2 + object.size.width / 2
                    }
                    
                    if object.rotate == RotationDirection.top {
                        object.position.y = object.position.y - TileHeight / 2 + object.size.height / 2
                    }
                    
                    if object.rotate == RotationDirection.left {
                        object.position.x += TileWidth / 2 - object.size.width / 2
                    }
                    
                    if object.rotate == RotationDirection.bottom {
                        object.position.y += TileHeight / 2 - object.size.height / 2
                    }
                }
                
                if object.type == ObjectType.spikes {
                    
                    /// Количество шипов вокруг блока
                    let countOfSpikes = 4
                    
                    /// Позиции на которые необходимо смещать
                    let moveToPosValue = CGPoint(x: TileWidth / 1.65, y: TileHeight / 1.65)
                    
                    for index in 0..<countOfSpikes {
                        
                        let offsetFromParent = getNewPointForSpike(index: index)
                        
                        /// Позиция, куда спрайт шипов будет выпущен
                        let newPointForSpike = Point(column: object.point.column + offsetFromParent.column, row: object.point.row + offsetFromParent.row)
                        
                        // Если шип не будет выходить за границы игрового поля, то добавляем его
                        if newPointForSpike.column >= 0 && newPointForSpike.column < boardSize.column && newPointForSpike.row >= 0 && newPointForSpike.row < boardSize.row {
                            let spikesSprite = SKSpriteNode(imageNamed: "Spikes")
                            spikesSprite.size = CGSize(width: object.size.width - 20, height: object.size.height - 10)
                            spikesSprite.zRotation = CGFloat(Double((index - 1) * 90) * Double.pi / 180)
                            
                            // Если по умолчанию стоит, что шипы уже выпущены, то отрисовываем их выпущенными
                            if object.spikesActive {
                                spikesSprite.position = CGPoint(x: CGFloat(offsetFromParent.column) * moveToPosValue.x, y: CGFloat(offsetFromParent.row) * moveToPosValue.y)
                            }
                            else {
                                spikesSprite.run(SKAction.repeatForever(SKAction.sequence([
                                    SKAction.move(to: CGPoint(x: CGFloat(offsetFromParent.column) * 25, y: CGFloat(offsetFromParent.row) * 25), duration: 0.75),
                                    SKAction.move(to: CGPoint(x: 0, y: 0), duration: 0.75)
                                    ])), withKey: "preloadSpikesAnimation")
                            }
                            
                            // = -1 that's because parent's node has zPosition = 3 (3 - 1) > tile's zPosition. It means that spikes are above tiles but behind parent's node
                            spikesSprite.zPosition = -1
                            spikesSprite.name = "Spike_\(index)"
                            object.addChild(spikesSprite)
                        }
                    }
                }
            }
        
            // Инициализируем перемещающиеся объекты
            for object in movingObjects {
                object.position = pointFor(column: object.moves[0].column, row: object.moves[0].row)
                
                if object.moves.count > 1 {
                    let direction = getObjectDirection(from: object.moves[0], to: object.moves[1])
                    
                    if direction == RotationDirection.left || direction == RotationDirection.right {
                        object.xScale = direction.rawValue == 0 ? -1 : 1
                    }
                }
                
                objectsLayer.addChild(object)
            }
        
            // Отображаем слой с объектами по центру экрана
            objectsLayer.position = CGPoint(x: -TileWidth * CGFloat(boardSize.column) / 2, y: -TileHeight * CGFloat(boardSize.row) / 2)
            tilesLayer.position = objectsLayer.position
        
            gameLayer.addChild(objectsLayer)
            gameLayer.addChild(tilesLayer)
            
            // Инициализируем финишный блок
            finishSprite = SKSpriteNode(imageNamed: "Gem_blue")
            finishSprite.position = pointFor(column: finish.column, row: finish.row)
            finishSprite.zPosition = 5
            finishSprite.size = CGSize(width: TileWidth * 0.4, height: (finishSprite.texture?.size().height)! / ((finishSprite.texture?.size().width)! / (TileWidth * 0.4)))
            objectsLayer.addChild(finishSprite)
        
            self.addChild(gameLayer)
        
            // Добавляем ячейки игрового поля
            addTiles(toNode: tilesLayer)
            
            drawHearts()
        
            Model.sharedInstance.gameViewControllerConnect.startLevel.isEnabled = true
            Model.sharedInstance.gameViewControllerConnect.movesRemainLabel.isHidden = false
            
            // Если уровень необходимо пройти за определённое количество ходов, то выделяет кол-во ходов красным цветом
            if isNecessaryUseAllMoves {
                Model.sharedInstance.gameViewControllerConnect.moveRemainCircleBg.image = UIImage(named: "Menu_circle-red")
            }
            
            // Т.к. в обучении на 1-ом уровне есть проигрыш, то флаг сбрасывается
            if Model.sharedInstance.currentLevel != 1 {
                // Проверяем пройден ли уровень, если пройден, то убирает обучение
                if Model.sharedInstance.getLevelLives(Model.sharedInstance.currentLevel) < 5 || Model.sharedInstance.isCompletedLevel(Model.sharedInstance.currentLevel) {
                    isLevelWithTutorial = false
                }
            }
            else {
                if Model.sharedInstance.isCompletedLevel(Model.sharedInstance.currentLevel) {
                    isLevelWithTutorial = false
                }
            }
            
            lastPathStepSprite = SKSpriteNode(imageNamed: "ErasePath")
            lastPathStepSprite.size = CGSize(width: TileWidth / 4, height: TileHeight / 4)
            lastPathStepSprite.position = pointFor(column: -5, row: -5)
            lastPathStepSprite.alpha = 0
            lastPathStepSprite.zPosition = 4
            objectsLayer.addChild(lastPathStepSprite)
            
            // Если финальный уровень в секции
            if Model.sharedInstance.currentLevel % Model.sharedInstance.distanceBetweenSections == 0 {
                bossLevel = BossLevel()
            }
            
            buttonsOnLevel = countButtonsOnLevel()
            
            if Model.sharedInstance.shouldPresentAd() {
                loadAd()
            }
        }
    }
    
    /// Функция, которая запускает основной цикл игры
    func startLevel() {
        if Model.sharedInstance.getLevelLives(Model.sharedInstance.currentLevel) > 0 {
            
            // Если траектория ГП состоит более, чем 1 хода
            if character.moves.count > 1 {
                // Если уровень не был начат
                if move == 0 {
                    gameBegan = true
                    
                    mainTimer(interval: 0.25)
                    
                    // Если уровень больше, чем 26, то показываем рюкзак (так как до 26 нет объектов, которые можно положить в рюкзак)
                    if Model.sharedInstance.currentLevel > 26 && checkForCollectibleObjects() {
                        presentObjectInfoView(spriteName: "Bag", description: "", infoViewHeight: 65)
                    }
                    
                    lastPathStepSprite.alpha = 0
                    
                    DispatchQueue.main.async {
                        self.character.pathNode.run(SKAction.fadeAlpha(to: 0, duration: 0.25), completion: {
                            self.character.pathNode.removeFromParent()
                        })
                        
                        for object in self.movingObjects {
                            object.pathLayer.run(SKAction.fadeAlpha(to: 0, duration: 0.25), completion: {
                                object.pathLayer.removeFromParent()
                            })
                        }
                    }
                    
                    Model.sharedInstance.gameViewControllerConnect.startLevel.isEnabled = false
                    Model.sharedInstance.gameViewControllerConnect.buyLevelButton.isEnabled = false
                    Model.sharedInstance.gameViewControllerConnect.goToMenuButton.isEnabled = false
                }
            }
            else {
                // Если режим предпросмотра был куплен или сейчас 3-ий уровень, так как там обучение с этим происходит
                if Model.sharedInstance.isPaidPreviewMode() || Model.sharedInstance.currentLevel == 3 {
                    presentPreview()
                }
                else {
                    SKTAudio.sharedInstance().playSoundEffect(filename: "Click.wav")
                    
                    buyPreviewOnGameBoard()
                }
            }
        }
    }
    
    func mainTimer(interval: TimeInterval = 0.65) {
        gameTimer.invalidate()
        gameTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { (_) in
            if self.move == 0 {
                self.character.run(SKAction.repeatForever(SKAction.animate(with: self.playerWalkingFrames, timePerFrame: 0.05, resize: false, restore: true)), withKey: "playerWalking")
                
                var beeFliesAtlas = [SKTexture]()
                for object in self.movingObjects {
                    // Анимация для пчелы
                    if object.type == ObjectType.bee {
                        
                        let beeFliespAnimatedAtlas = SKTextureAtlas(named: "BeeFlies")
                        
                        if beeFliesAtlas.isEmpty {
                            for i in 1...beeFliespAnimatedAtlas.textureNames.count {
                                let beeFliesTextureName = "BeeFlies_\(i)"
                                beeFliesAtlas.append(beeFliespAnimatedAtlas.textureNamed(beeFliesTextureName))
                            }
                        }
                        
                        object.run(SKAction.repeatForever(SKAction.animate(with: beeFliesAtlas, timePerFrame: 0.05, resize: false, restore: true)), withKey: "beeFlies")
                    }
                }
            }
            self.worldMove()
        }
    }

    /// Функция, которая увеличивает/уменьшает текущий ход на N и выводит в Label
    ///
    /// - Parameter count: количество ходов, на которое нужно изменить кол-во ходов (использовать отрицательные значения, чтобы отнять)
    func updateMoves(_ count: Int) {
        moves = moves + count
        Model.sharedInstance.gameViewControllerConnect.movesRemainLabel.text = String(moves)
    }
    
    /// Функция проверяет существование позиции в наборе позиций
    ///
    /// - Parameters:
    ///   - points: массив позиций [Point]
    ///   - point: позиция, которую необходимо проверить
    /// - Returns: возвращает true, если позиция найдена в массиве
    func pointExists(points: [Point], point: Point) -> Bool {
        for pointItem in points {
            if pointItem == point {
                return true
            }
        }
        
        return false
    }
    
    /// Функция получает все доступные позиции вокруг одной нужной позиции
    ///
    /// - Parameters:
    ///   - point: позиция, вокруг которой необходимо искать
    ///   - range: радиус нахождения
    /// - Returns: возвращает массив позиций, которые находятся вокруг нужной позиции (которые не выходят за пределы игрового поля)
    func getPointsAround(_ point: Point, range: Int = 1) -> [Point] {
        var set = [Point]()

        for row in point.row - range...point.row + range {
            for column in point.column - range...point.column + range {
                if point != Point(column: column, row: row) {
                    if row >= 0 && row < boardSize.row {
                        if column >= 0 && column < boardSize.column {
                            set.append(Point(column: column, row: row))
                        }
                    }
                }
            }
        }
        return set
    }
    
    /// Функция получает направление блока по его текущей позиции и следующей
    func getObjectDirection(from: Point, to: Point) -> RotationDirection {
        if from.row == to.row {
            return (from.column < to.column) ? RotationDirection.right : RotationDirection.left
        }
        else {
            return (from.row < to.row) ? RotationDirection.top : RotationDirection.bottom
        }
    }
    
    /// Функция проверяет направление движения двух объектов (учитываются два направления: горизонтальное и вертикальное)
    func checkForSameDirection(firstDirection: RotationDirection, secondDirection: RotationDirection, directions: [RotationDirection]) -> Bool {
        return (firstDirection == directions[0] || firstDirection == directions[1]) && (secondDirection == directions[0] || secondDirection == directions[1])
    }
    
    /// Функция получает индекс позиции в массиве позиций
    func getMoveIndex(move: Point, moves: [Point]) -> Int {
        var index = 0
        for step in moves {
            if step == move {
                return index
            }
            
            index += 1
        }
        
        return -1
    }
    
    /// Получаем новую координату для очередного спрайта шипа
    func getNewPointForSpike(index: Int) -> Point {
        var offsetFromParent = Point(column: 1, row: 0)
        
        // Если верхний или нижний, то меняем Y-координату
        if index == 1 || index == 3 {
            offsetFromParent.row = 1
            offsetFromParent.column = 0
        }
        
        // Если левый или нижний, то координаты должны быть отрицательными
        if index == 2  || index == 3 {
            offsetFromParent.column *= -1
            offsetFromParent.row *= -1
        }
        
        return offsetFromParent
    }
    
    override func didSimulatePhysics() {
    }
    
    /// Функция, отрисовывающая количество оставшихся жизней на уровне
    func drawHearts() {
        let completedLabelRectWidth = 120
        let completedLabelRect = CGRect(x: Int(self.view!.frame.midX - CGFloat(completedLabelRectWidth / 2)), y: 13, width: completedLabelRectWidth, height: 35)
        
        let completedLabel = UILabel(frame: completedLabelRect)
        completedLabel.backgroundColor = UIColor.init(red: 0 / 255, green: 109 / 255, blue: 240 / 255, alpha: 1)
        completedLabel.textColor = UIColor.white
        
        completedLabel.textAlignment = NSTextAlignment.center
        completedLabel.layer.masksToBounds = true
        completedLabel.layer.cornerRadius = 15
        
        if !Model.sharedInstance.isCompletedLevel(Model.sharedInstance.currentLevel) {
            // Если обычный урвоень (не босс), то выводим сердечки (жизни)
            if Model.sharedInstance.currentLevel % Model.sharedInstance.distanceBetweenSections != 0 {
                Model.sharedInstance.gameViewControllerConnect.viewTopMenu.addSubview(completedLabel)
                
                let livesOnLevel = Model.sharedInstance.getLevelLives(Model.sharedInstance.currentLevel)
                let allLivesPerLevel = 5
                
                var heartTexture = SKTexture(imageNamed: "Heart")
                let heartSize = CGSize(width: heartTexture.size().width / 2.1, height: heartTexture.size().height / 2.1)
                
                if livesOnLevel > 0 {
                    let eachHeartXpos = (CGFloat(heartSize.width + 1) * CGFloat(allLivesPerLevel)) / 2
                    let xKoefForHeartStack = eachHeartXpos + CGFloat((allLivesPerLevel - 1) / 2) - 2
                    heartsStackView = UIStackView(frame: CGRect(x: (Model.sharedInstance.gameScene.view?.bounds.midX)! - xKoefForHeartStack, y: 13 + 35 / 2 - heartSize.height / 2, width: heartSize.width * CGFloat(livesOnLevel), height: heartSize.height))
                    
                    for index in 0...allLivesPerLevel - 1 {
                        heartTexture = allLivesPerLevel - 1 - index < livesOnLevel ? SKTexture(imageNamed: "Heart") : SKTexture(imageNamed: "Heart_empty")
                        let heartImageView = UIButton(frame: CGRect(x: CGFloat((heartSize.width + 1) * CGFloat(index)), y: 0, width: heartSize.width, height: heartSize.height))
                        heartImageView.setBackgroundImage(UIImage(cgImage: heartTexture.cgImage()), for: UIControlState.normal)
                        heartImageView.isUserInteractionEnabled = false
                        heartImageView.tag = index + 1
                        
                        if allLivesPerLevel - livesOnLevel == index {
                            lastHeartButton = heartImageView
                            
                            // Добавляем пустое сердце под последнее непустое сердце (если проигрывает, то скрываем непустое и убедт анимация)
                            let losesButton = UIButton(frame: CGRect(x: CGFloat((heartSize.width + 1) * CGFloat(index)), y: 0, width: heartSize.width, height: heartSize.height))
                            losesButton.setBackgroundImage(UIImage(named: "Heart_empty"), for: UIControlState.normal)
                            heartsStackView.addSubview(losesButton)
                        }
                        
                        heartsStackView.addSubview(heartImageView)
                    }
                    Model.sharedInstance.gameViewControllerConnect.viewTopMenu.addSubview(heartsStackView)
                }
                
                completedLabel.frame.size.width = heartSize.width * CGFloat(allLivesPerLevel) + 20
                completedLabel.frame.origin.x = self.view!.frame.midX - completedLabel.frame.width / 2
            }
        }
        else {
            completedLabel.font = UIFont(name: "AvenirNext-Medium", size: 18)
            completedLabel.text = NSLocalizedString("Completed", comment: "")
            
            Model.sharedInstance.gameViewControllerConnect.viewTopMenu.addSubview(completedLabel)
        }
    }
    
    /// Уровень не пройден
    func loseLevel() {
        if !isLosedLevel {
            if Model.sharedInstance.currentLevel != 1 {
                if Model.sharedInstance.emptySavedLevelsLives() == false {
                    if !Model.sharedInstance.isCompletedLevel(Model.sharedInstance.currentLevel) {
                        Model.sharedInstance.setLevelLives(level: Model.sharedInstance.currentLevel, newValue: Model.sharedInstance.getLevelLives(Model.sharedInstance.currentLevel) - 1)
                    }
                    
                    if Model.sharedInstance.currentLevel % Model.sharedInstance.distanceBetweenSections == 0 {
                        if bossLevel != nil {
                            let eventParams = ["level": Model.sharedInstance.currentLevel, "isCompletedLevel": Model.sharedInstance.isCompletedLevel(Model.sharedInstance.currentLevel), "countAttemps": abs(Model.sharedInstance.getLevelLives(Model.sharedInstance.currentLevel) - 5), "countStars": bossLevel!.countStars] as [String : Any]
                            
                            Flurry.logEvent("Lose_boss_level", withParameters: eventParams)
                        }
                    }
                    else {
                        let eventParams = ["level": Model.sharedInstance.currentLevel, "isCompletedLevel": Model.sharedInstance.isCompletedLevel(Model.sharedInstance.currentLevel), "countLives": Model.sharedInstance.getLevelLives(Model.sharedInstance.currentLevel)] as [String : Any]
                        
                        Flurry.logEvent("Lose_level", withParameters: eventParams)
                    }
                }
            }
            
            // Если обычный уровень (не босс) и жизней = 0, то окно nolives (если босс, то всегда выводить lose)
            if Model.sharedInstance.getLevelLives(Model.sharedInstance.currentLevel) <= 0 && Model.sharedInstance.currentLevel % Model.sharedInstance.distanceBetweenSections != 0 {
                modalWindowPresent(type: modalWindowType.nolives)
            }
            else {
                modalWindowPresent(type: modalWindowType.lose)
            }
            
            // Если рекламы не отключена
            if Model.sharedInstance.isDisabledAd() == false {
                // Если проигранный уровень % 8 == 0
                if Model.sharedInstance.shouldPresentAd() {
                    if interstitial.isReady {
                        SKTAudio.sharedInstance().pauseBackgroundMusic()
                        interstitial.present(fromRootViewController: Model.sharedInstance.gameViewControllerConnect)
                    }
                    else {
                        Flurry.logEvent("Ad_wasnt_ready")
                    }
                }
                
                Model.sharedInstance.setCountLoseLevel()
            }
            
            // Если обычный уровень (не босс), то скрываем одно сердечко
            if Model.sharedInstance.currentLevel % Model.sharedInstance.distanceBetweenSections != 0 {
                if !Model.sharedInstance.isCompletedLevel(Model.sharedInstance.currentLevel) {
                    let btnFadeOutAnim = CABasicAnimation(keyPath: "opacity")
                    btnFadeOutAnim.toValue = 0
                    btnFadeOutAnim.duration = 0.35
                    btnFadeOutAnim.fillMode = kCAFillModeForwards
                    btnFadeOutAnim.isRemovedOnCompletion = false
                    
                    lastHeartButton.layer.add(btnFadeOutAnim, forKey: "fadeOut")
                }
            }
            
            SKTAudio.sharedInstance().playSoundEffect(filename: "Lose.mp3")
            
            gameTimer.invalidate()
            self.isPaused = true
            
            isLosedLevel = true
        }
    }
    
    /// Уровень пройден
    func winLevel() {
        if Model.sharedInstance.currentLevel > Model.sharedInstance.getCountCompletedLevels() {
            Model.sharedInstance.setCountCompletedLevels(Model.sharedInstance.currentLevel)
            
            // Так как ГП начнёт перемещаться автоматически, то в нил переменную, которая выстанавливает последнее положение
            Model.sharedInstance.lastYpositionLevels = nil
        }
        
        modalWindowPresent(type: modalWindowType.win)
        
        // Убираем финишный драг. камень
        finishSprite.removeFromParent()
        
        SKTAudio.sharedInstance().playSoundEffect(filename: "Win.wav")
        
        gameTimer.invalidate()
        isPaused = true
        
        if Model.sharedInstance.currentLevel % Model.sharedInstance.distanceBetweenSections == 0 {
            if bossLevel != nil {
                let eventParams = ["level": Model.sharedInstance.currentLevel, "isCompletedLevel": Model.sharedInstance.isCompletedLevel(Model.sharedInstance.currentLevel), "countAttemps": abs(Model.sharedInstance.getLevelLives(Model.sharedInstance.currentLevel) - 5), "countStars": bossLevel!.countStars] as [String : Any]
                
                Flurry.logEvent("Win_boss_level", withParameters: eventParams)
            }
        }
        else {
            let eventParams = ["level": Model.sharedInstance.currentLevel, "isCompletedLevel": Model.sharedInstance.isCompletedLevel(Model.sharedInstance.currentLevel), "countLives": Model.sharedInstance.getLevelLives(Model.sharedInstance.currentLevel), "isCompletedWithHelp": Model.sharedInstance.isLevelsCompletedWithHelp(Model.sharedInstance.currentLevel)] as [String : Any]
            
            Flurry.logEvent("Win_level", withParameters: eventParams)
        }
        
        // Если уровень не был пройден, то обновляем кол-во драг. камней
        if Model.sharedInstance.isCompletedLevel(Model.sharedInstance.currentLevel) == false {
            Model.sharedInstance.setCountGems(amountGems: gemsForLevel)
            
            for index in 1...gemsForLevel {
                let gem = UIImageView(image: UIImage(named: "Gem_blue"))
                
                gem.frame.origin = CGPoint(x: self.view!.frame.width + 200, y: self.view!.frame.height + 200)
                gem.frame.size = CGSize(width: gem.frame.width * 5, height: gem.frame.height * 5)
                self.view!.addSubview(gem)
                
                DispatchQueue.main.async {
                    UIView.animate(withDuration: TimeInterval(0.5 + CGFloat(index) * 0.425), animations: {
                        gem.frame.origin = CGPoint(x: self.view!.frame.width / 2 + 110 - 55, y: self.view!.frame.height / 2 - 78)
                        gem.frame.size = CGSize(width: gem.frame.width / 5 * 0.75, height: gem.frame.height / 5 * 0.75)
                    }, completion: { (_) in
                        
                        SKTAudio.sharedInstance().playSoundEffect(filename: "PickUpCoin.mp3")
                        
                        self.countGemsModalWindowLabel.text = "X\(Model.sharedInstance.getCountGems() - self.gemsForLevel + index)"
                        gem.removeFromSuperview()
                    })
                }
            }
            
            Model.sharedInstance.setCompletedLevel(Model.sharedInstance.currentLevel)
        }
    }
    
    func loadAd() {
        interstitial = GADInterstitial(adUnitID: "ca-app-pub-3811728185284523/9724040842")
        let request = GADRequest()
        interstitial.load(request)
    }
    
    /// Очистка уровня
    func cleanLevel() {
        movingObjects.removeAll()
        staticObjects.removeAll()
        move = 0
        absoluteMove = 0
        moves = 0
        finish = Point(column: 0, row: 0)
        characterStart = Point(column: 0, row: 0)
        boardSize = Point(column: 0, row: 0)
        checkChoosingPath = Point(column: 0, row: 0)
        checkChoosingPathArray.removeAll()
        addedLastPointByMove = false
        removedLastPointByMove = false
        stars = 0
        gameTimer.invalidate()
        previewTimer.invalidate()
        gameLayer.removeAllChildren()
        gameLayer.removeAllActions()
        gameLayer.removeFromParent()
        objectsLayer.removeAllChildren()
        objectsLayer.removeAllActions()
        objectsLayer.removeFromParent()
        bossEnemies.removeAllChildren()
        bossEnemies.removeAllActions()
        bossEnemies.removeFromParent()
        tilesLayer.removeAllChildren()
        tilesLayer.removeAllActions()
        tilesLayer.removeFromParent()
        heartsStackView.removeFromSuperview()
        objectTypeClickedLast = nil
        isLastTapLongPress = false
        lastClickOnGameBoard = Point(column: -1, row: -1)
        gameBegan = false
        isNextCharacterMoveAtBridgeLose = false
        isNecessaryUseAllMoves = false
        lastPathStepSprite.removeFromParent()
        isPreviewing = false
        isLosedLevel = false
        keysInBag.removeAll()
        collectedObjects.removeAll()
        
        if Model.sharedInstance.currentLevel > 1 {
            removeObjectInfoView()
        }
        
        buttonsOnLevel = 0
        
        Model.sharedInstance.gameViewControllerConnect.startLevel.isEnabled = true
        Model.sharedInstance.gameViewControllerConnect.buyLevelButton.isEnabled = true
        Model.sharedInstance.gameViewControllerConnect.goToMenuButton.isEnabled = true
        Model.sharedInstance.gameViewControllerConnect.viewTopMenu.isHidden = false
        heartsStackView.removeFromSuperview()
        
        self.removeAllChildren()
        self.removeAllActions()
        
        if bossLevel != nil {
            bossLevel?.cleanTimers()
        }
    }
    
    /// Срабатывает при нажатии на кнопку RESTART в меню после проигранного раунда
    func restartLevel() {
        self.isPaused = false
        
        cleanLevel()
        createLevel()
    }
    
    /// Функция добавляет игровые ячейки (создание игрового поля)
    func addTiles(toNode: SKNode) {
        
        var scale = Scale(xScale: 1.0, yScale: 1.0)
        for row in 0..<boardSize.row {
            for column in 0..<boardSize.column {
                var tileSprite: String = "center"
                
                var rotation: Double = 0.0
                scale.xScale = 1.0
                scale.yScale = 1.0
          
                // Если уровень финалный в секции, то оставляем только верхние и нижние
                if Model.sharedInstance.currentLevel % Model.sharedInstance.distanceBetweenSections != 0 {
                    if column == 0 && (row != 0) && (row != boardSize.row - 1) {
                        tileSprite = "top"
                        rotation = (90 * Double.pi / 180)
                    }
                    
                    if column == boardSize.column - 1 && (row != 0) && (row != boardSize.row - 1) {
                        tileSprite = "top"
                        rotation = (-90 * Double.pi / 180)
                    }
                
                    if row == 0 {
                        tileSprite = "top"
                        scale.yScale = -1
                    }
                
                    if row == 0 && column == 0 {
                        tileSprite = "top_left"
                    }
                    
                    if row == 0 && column == boardSize.column - 1 {
                        tileSprite = "top_left"
                        scale.xScale = -1
                    }
                
                    if row == boardSize.row - 1 {
                        tileSprite = "top"
                    }
                
                    if row == boardSize.row - 1 && column == 0 {
                        tileSprite = "top_left"
                    }
                    
                    if row == boardSize.row - 1 && column == boardSize.column - 1 {
                        tileSprite = "top_left"
                        scale.xScale = -1
                    }
                }
                
                let tileNode = SKSpriteNode(imageNamed: "Tile_\(tileSprite)")
                
                tileNode.xScale = scale.xScale
                tileNode.yScale = scale.yScale
                tileNode.zRotation += CGFloat(rotation)
                
                tileNode.size = CGSize(width: TileWidth, height: TileHeight)
                tileNode.position = pointFor(column: column, row: row)
                tileNode.zPosition = 1
                toNode.addChild(tileNode)
            }
        }
    }
    
    func addTilesBg(toNode: SKNode) {
        
        var pointBgTile: CGPoint = pointFor(column: 0, row: 0)
        var row = -3
        
        while pointBgTile.y <= self.size.height + TileHeight * 3 {
            for column in -3..<boardSize.column + 3 {
                let tileSprite: String = "center"
                
                pointBgTile = pointFor(column: column, row: row)
                
                let tileNode = SKSpriteNode(imageNamed: "Tile_\(tileSprite)")
//                let tileNode = SKSpriteNode(color: UIColor(red: 149/255, green: 201/255, blue: 45/255, alpha: 1), size: CGSize(width: TileWidth, height: TileHeight))
                
                tileNode.alpha = 0.125
                tileNode.size = CGSize(width: TileWidth, height: TileHeight)
                tileNode.position = pointBgTile
                tileNode.zPosition = 1
                toNode.addChild(tileNode)
            }
            row += 1
        }
    }
    
    /// Функция конвертирует игровые координаты в CGPoint
    func pointFor(column: Int, row: Int) -> CGPoint {
        return CGPoint(
            x: CGFloat(column) * TileWidth + TileWidth / 2,
            y: CGFloat(row) * TileHeight + TileHeight / 2)
    }
    
    /// Функция конвертирует CGPoint в позицию на игровом поле
    func convertPoint(point: CGPoint) -> (success: Bool, point: Point) {
        
        var isSuccess = false
        
        if point.x >= 0 && point.x < CGFloat(boardSize.column) * TileWidth &&
            point.y >= 0 && point.y < CGFloat(boardSize.row) * TileHeight {
            isSuccess = true
        }
        
        return (isSuccess, Point(column: Int(point.x / TileWidth), row: Int(point.y / TileHeight)))
    }
    
    func showWinningPath() {
        // Если "покупаем" уровень (показать правильный путь)
        if !Model.sharedInstance.isLevelsCompletedWithHelp(Model.sharedInstance.currentLevel) {
            // Устанавливаем в массив, что данный уровень пройден с помощью кнопки "Help"
            Model.sharedInstance.setLevelsCompletedWithHelp(Model.sharedInstance.currentLevel)
            // Отнимаем 25 драг. камней, ибо мы покупаем
            Model.sharedInstance.setCountGems(amountGems: -WINNING_PATH_PRICE)
        }
        
        updateMoves(character.moves.count - 1)
        character.moves.removeAll()
        
        updateMoves(-winningPath.count + 1)
        character.moves = winningPath
        
        if lastPathStepSprite != nil {
            lastPathStepSprite.position = pointFor(column: character.moves.last!.column, row: character.moves.last!.row)
        }
        
        character.path()
    }
    
    func buyLevel() {
        if Model.sharedInstance.isLevelsCompletedWithHelp(Model.sharedInstance.currentLevel) {
            showWinningPath()
        }
        else {
            if Model.sharedInstance.getCountGems() >= WINNING_PATH_PRICE {
                let message = "\(NSLocalizedString("Buying winning path is worth", comment: "")) \(WINNING_PATH_PRICE) \(NSLocalizedString("GEMS", comment: "")) (\(NSLocalizedString("you have", comment: "")) \(Model.sharedInstance.getCountGems()) \(NSLocalizedString("GEMS", comment: "")))"
                let alert = UIAlertController(title: NSLocalizedString("Buying winning path", comment: ""), message: message, preferredStyle: UIAlertControllerStyle.alert)
                
                let actionCancel = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: UIAlertActionStyle.cancel, handler: { (_) in
                    let eventParams = ["level": Model.sharedInstance.currentLevel, "countGems": Model.sharedInstance.getCountGems()]
                    
                    Flurry.logEvent("Cancel_buy_winning_path", withParameters: eventParams)
                })
                
                let actionOk = UIAlertAction(title: NSLocalizedString("Buy", comment: ""), style: UIAlertActionStyle.default, handler: { (_) in
                    let eventParams = ["level": Model.sharedInstance.currentLevel, "countGems": Model.sharedInstance.getCountGems()]
                    
                    Flurry.logEvent("Buy_winning_path", withParameters: eventParams)
                    
                    self.showWinningPath()
                })
                
                alert.addAction(actionOk)
                alert.addAction(actionCancel)
                
                Model.sharedInstance.gameViewControllerConnect.present(alert, animated: true, completion: nil)
            }
            else {
                let message = "\(NSLocalizedString("You do not have enough GEMS to buy winning path", comment: "")). \(NSLocalizedString("You need", comment: "")) \(WINNING_PATH_PRICE) \(NSLocalizedString("GEMS", comment: "")), \(NSLocalizedString("but you only have", comment: "")) \(Model.sharedInstance.getCountGems()) \(NSLocalizedString("GEMS", comment: ""))"
                
                let alert = UIAlertController(title: NSLocalizedString("Not enough GEMS", comment: ""), message: message, preferredStyle: UIAlertControllerStyle.alert)
                
                let actionCancel = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: UIAlertActionStyle.cancel, handler: { (_) in
                    let eventParams = ["level": Model.sharedInstance.currentLevel, "countGems": Model.sharedInstance.getCountGems()]
                    
                    Flurry.logEvent("Cancel_buy_winning_path_not_enough_gems", withParameters: eventParams)
                })
                
                let actionOk = UIAlertAction(title: NSLocalizedString("Buy GEMS", comment: ""), style: UIAlertActionStyle.default, handler: { (_) in
                    Model.sharedInstance.gameViewControllerConnect.presentMenu(dismiss: true)
                    
                    let eventParams = ["level": Model.sharedInstance.currentLevel, "countGems": Model.sharedInstance.getCountGems()]
                    
                    Flurry.logEvent("Buy_gems_winning_path_not_enough_gems", withParameters: eventParams)
                })
                
                alert.addAction(actionOk)
                alert.addAction(actionCancel)
                
                Model.sharedInstance.gameViewControllerConnect.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    func shakeView(_ viewToShake: UIView, repeatCount: Float = 3, amplitude: CGFloat = 5) {
        let animation = CABasicAnimation(keyPath: "position")
        animation.duration = 0.07
        animation.repeatCount = repeatCount
        animation.autoreverses = true
        animation.fromValue = NSValue(cgPoint: CGPoint(x: viewToShake.center.x - amplitude, y: viewToShake.center.y))
        animation.toValue = NSValue(cgPoint: CGPoint(x: viewToShake.center.x + amplitude, y: viewToShake.center.y))
        
        viewToShake.layer.add(animation, forKey: "position")
    }
    
    /// Функция проверяет есть ли объекты, для которых необходимо "открыть рюкзак"
    func checkForCollectibleObjects() -> Bool {
        for object in staticObjects {
            if object.type == ObjectType.key || object.type == ObjectType.magnet {
                return true
            }
        }
        
        return false
    }
    
    override func update(_ currentTime: TimeInterval) {
        
    }
    
    override func didFinishUpdate() {
    }
}
