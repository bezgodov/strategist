import Foundation
import SpriteKit
//import CoreMotion

var TileWidth: CGFloat!
var TileHeight: CGFloat!

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    /// Массив перемещающихся объектов
    var movingObjects = Set<Object>()
    
    /// Массив статичных объектов
    var staticObjects = Set<StaticObject>()
    
    /// Текущий ход (для всего мира)
    var move: Int = 0
    
    /// Доступное количество ходов
    var moves: Int!
    
    /// Координаты финишного блока
    var finish: Point!
    
    /// Координаты начальной позиции ГП
    var characterStart: Point = Point(column: 0, row: 0)
    
    /// Размеры игрового поля
    var boardSize: Point!
   
    /// Главный персонаж (ГП)
    var character: Character!
    
    /// Вспомогательная переменная для выбора траектории с помощью TouchedMoved
    var checkChoosingPath: Point!
    
    /// Вспомогательная переменная для выбора траектории с помощью TouchedMoved
    var checkChoosingPathArray: [Point]!
    
    /// Вспомогательная переменная для выбора траектории с помощью TouchedMoved
    var addedLastPointByMove: Bool = false
    
    /// Количество звёзд на уровне, которые необходимо собрать
    var stars: Int = 0
    
    var gameTimer = Timer()
    
    /// Слой, на который добавляются все остальные Nodes
    let gameLayer = SKNode()
    
    /// Слой, на который добавляются все объекты
    let objectsLayer = SKNode()
    
    /// Слой, на который добавляются спрайты ячеек
    let tilesLayer = SKNode()
    
    /// Текущий уровень
    var currentLevel = 1
    
//    var motionManager: CMMotionManager!
    
    /// Переменная, которая содержит все текстуры для анимации ГП
    var playerWalkingFrames: [SKTexture]!
    
    override func didMove(to view: SKView) {
        
        self.backgroundColor = UIColor.white

        sceneSettings()
        
        let playerAnimatedAtlas = SKTextureAtlas(named: "PlayerWalks")
        var walkFrames = [SKTexture]()
        
        /// Задаём анимацию для ГП
        let numImages = playerAnimatedAtlas.textureNames.count
        for i in 1...numImages {
            let playerTextureName = "PlayerPinkWalks_\(i)"
            walkFrames.append(playerAnimatedAtlas.textureNamed(playerTextureName))
        }
        
        playerWalkingFrames = walkFrames
        
        createLevel()
    }
    
    /* Настройка сцены */
    func sceneSettings() {
        
        /*
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(self.respondToSwipeGesture))
        swipeDown.direction = UISwipeGestureRecognizerDirection.down
        self.view?.addGestureRecognizer(swipeDown)
         */
        
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        
        /*
        // При наклоне девайса наклонять персонажа
         
        motionManager = CMMotionManager()
         
        if motionManager?.isDeviceMotionAvailable == true {
            
            motionManager?.deviceMotionUpdateInterval = 0.1;
            
            let queue = OperationQueue()
            motionManager?.startAccelerometerUpdates(to: queue, withHandler: { (motion, error) -> Void in
                DispatchQueue.main.async() {
                    if let accelerometerData = self.motionManager.accelerometerData {
                        self.physicsWorld.gravity.dx = CGFloat(accelerometerData.acceleration.x * 5)
                    }
                }
            })
        }
        else {
            print("Device motion unavailable");
        }
 
         */
    }
    
    func createLevel() {
        goToLevel(currentLevel)
        
        // Инициализируем ГП
        character = Character(texture: playerWalkingFrames[1])
        character.zPosition = 3
        character.position = pointFor(column: characterStart.column, row: characterStart.row)
        character.size = CGSize(width: TileWidth * 0.5, height: (character.texture?.size().height)! / ((character.texture?.size().width)! / (TileWidth * 0.5)))
        character.moves.append(characterStart)
        objectsLayer.addChild(character)
        
        // Инициализируем статичные объекты
        for object in staticObjects {
            object.position = pointFor(column: object.point.column, row: object.point.row)
            objectsLayer.addChild(object)
            
            // Инициализируем Label для объекта "бомба"
            if object.type == ObjectType.bomb {
                let movesToExplodeLabel = SKLabelNode(text: String(object.movesToExplode))
                movesToExplodeLabel.name = "movesToExplode"
                movesToExplodeLabel.zPosition = 6
                movesToExplodeLabel.color = UIColor.green
                movesToExplodeLabel.fontColor = UIColor.green
                movesToExplodeLabel.fontSize = 65
                movesToExplodeLabel.fontName = "Helvetica Neue"
                movesToExplodeLabel.horizontalAlignmentMode = .center
                movesToExplodeLabel.verticalAlignmentMode = .center
                object.addChild(movesToExplodeLabel)
            }
        }
        
        // Инициализируем перемещающиеся объекты
        for object in self.movingObjects {
            object.position = pointFor(column: object.moves[0].column, row: object.moves[0].row)
            objectsLayer.addChild(object)
        }
        
        // Отображаем слой с объектами по центру экрана
        objectsLayer.position = CGPoint(x: -TileWidth * CGFloat(boardSize.column) / 2, y: -TileHeight * CGFloat(boardSize.row) / 2)
        tilesLayer.position = objectsLayer.position
        
        gameLayer.addChild(objectsLayer)
        gameLayer.addChild(tilesLayer)
        
        // Инициализируем финишный блок
        let finishSprite = SKSpriteNode(imageNamed: "Finish")
        finishSprite.position = pointFor(column: finish.column, row: finish.row)
        finishSprite.zPosition = 2
        finishSprite.size = CGSize(width: TileWidth * 0.75, height: (finishSprite.texture?.size().height)! / ((finishSprite.texture?.size().width)! / (TileWidth * 0.75)))
        objectsLayer.addChild(finishSprite)
        
        self.addChild(gameLayer)
        
        // Добавляем ячейке игрового поля
        addTiles()
        
        Model.sharedInstance.gameViewControllerConnect.stackViewLoseLevel?.isHidden = true
        Model.sharedInstance.gameViewControllerConnect.startLevel.isHidden = false
        Model.sharedInstance.gameViewControllerConnect.movesRemainLabel.isHidden = false
    }
    
    /// Функция, которая запускает основной цикл игры
    func startLevel() {
        // Если уровень не был начат
        if move == 0 {
            // Если траектория ГП состоит более, чем 1 хода
            if character.moves.count > 1 {
                character.run(SKAction.repeatForever(SKAction.animate(with: playerWalkingFrames, timePerFrame: 0.05, resize: false, restore: true)), withKey: "playerWalking")
                
                gameTimer = Timer.scheduledTimer(withTimeInterval: 0.65, repeats: true) { (_) in
                    self.worldMove()
                }
                
                character.pathNode.removeFromParent()
                Model.sharedInstance.gameViewControllerConnect.startLevel.isHidden = true
            }
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
    
    /*
    func setExtraPath(direction: RotationDirection, from: Point, to: Point) {
        var point = from
        var index = move + 1
        
        var rowCoef: Int = (to.row > from.row) ? 1 : -1
        var columnCoef: Int = (to.column > from.column) ? 1 : -1
        
        if rowCoef == 1 {
            point = Point(column: point.column + 1, row: point.row)
        }
        
        character.moves.insert(point, at: index)
        
        while point != to {
            if point.row != to.row {
                point.row += 1
            }
            else {
                if point.column != to.column {
                    point.column -= 1
                }
            }
            
            if point != to {
                index += 1
                character.moves.insert(point, at: index)
            }
        }
    }
     */
    
    
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
    
    override func didSimulatePhysics() {
    }
    
    
    /// Уровень не пройден
    func loseLevel() {
        Model.sharedInstance.gameViewControllerConnect.backgroundBlurEffect.isHidden = false
        Model.sharedInstance.gameViewControllerConnect.stackViewLoseLevel.isHidden = false
        Model.sharedInstance.gameViewControllerConnect.menuButtonTopRight.isHidden = true
        Model.sharedInstance.gameViewControllerConnect.movesRemainLabel.isHidden = true
        
        gameTimer.invalidate()
        
        self.isPaused = true
    }
    
    /// Уровень пройден
    func winLevel() {
        currentLevel += 1
 
        cleanLevel()
        createLevel()
    }
    
    /// Очистка уровня
    func cleanLevel() {
        move = 0
        stars = 0
 
        movingObjects.removeAll()
        staticObjects.removeAll()
        gameLayer.removeAllChildren()
        objectsLayer.removeAllChildren()
        tilesLayer.removeAllChildren()
        
        self.removeAllChildren()
        self.removeAllActions()
        gameTimer.invalidate()
//        timerToLose.invalidate()
//        timeToLose = 30
    }
    
    /// Срабатывает при нажатии на кнопку RESTART в меню после проигранного раунда
    func restartLevel() {
        Model.sharedInstance.gameViewControllerConnect.backgroundBlurEffect.isHidden = true
        Model.sharedInstance.gameViewControllerConnect.menuButtonTopRight.isHidden = false
        
        cleanLevel()
        createLevel()
        
        self.isPaused = false
    }
    
    /*
    func objectAT(column: Int, row: Int) -> Object? {
        assert(column >= 0 && column < boardSize.column)
        assert(row >= 0 && row < boardSize.row)
        return objects[column, row]
    }
     */
    
    /// Функция добавляет игровые ячейки (создание игрового поля)
    func addTiles() {
        var scale = Scale(xScale: 1.0, yScale: 1.0)
        for row in 0..<boardSize.row {
            for column in 0..<boardSize.column {
                //if level.tileAt(column: column, row: row) != nil {
                
                var tileSprite: String = "center"
                var rotation: Double = 0.0
                scale.xScale = 1.0
                scale.yScale = 1.0
          
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
                
                let tileNode = SKSpriteNode(imageNamed: "Tile_\(tileSprite)")
                
                tileNode.xScale = scale.xScale
                tileNode.yScale = scale.yScale
                tileNode.zRotation += CGFloat(rotation)
                
                tileNode.size = CGSize(width: TileWidth, height: TileHeight)
                tileNode.position = pointFor(column: column, row: row)
                tileNode.zPosition = 1
                tilesLayer.addChild(tileNode)
                //}
            }
        }
    }
    
    /// Функция конвертирует игровые координаты в CGPoint
    func pointFor(column: Int, row: Int) -> CGPoint {
        return CGPoint(
            x: CGFloat(column) * TileWidth + TileWidth / 2,
            y: CGFloat(row) * TileHeight + TileHeight / 2)
    }
    
    /// Функция конвертирует CGPoint в позицию на игровом поле, если клик был сделан по игровому полю
    func convertPoint(point: CGPoint) -> (success: Bool, point: Point) {
        if point.x >= 0 && point.x < CGFloat(boardSize.column) * TileWidth &&
            point.y >= 0 && point.y < CGFloat(boardSize.row) * TileHeight {
            return (true, Point(column: Int(point.x / TileWidth), row: Int(point.y / TileHeight)))
        }
        else {
            return (false, Point(column: 0, row: 0))
        }
    }
    
    /// Функиця отображает траектории всех перемещающихся объектов
    func showMoves() {
        if Model.sharedInstance.gameViewControllerConnect.showMoves.titleLabel?.text == "SHOW MOVES" {
            Model.sharedInstance.gameViewControllerConnect.showMoves.setTitle("HIDE MOVES", for: UIControlState.normal)
            
            for object in movingObjects {
                object.path()
            }
            
        }
        else {
            Model.sharedInstance.gameViewControllerConnect.showMoves.setTitle("SHOW MOVES", for: UIControlState.normal)
            
            for object in movingObjects {
                object.path(hide: true)
            }
            
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        
    }
    
    override func didFinishUpdate() {
    }
    
//    @objc func respondToSwipeGesture(gesture: UIGestureRecognizer) {
//        if let swipeGesture = gesture as? UISwipeGestureRecognizer {
//            if swipeGesture.direction == UISwipeGestureRecognizerDirection.down {
//                character.physicsBody?.affectedByGravity = true
//            }
//        }
//    }
}
