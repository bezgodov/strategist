import Foundation
import SpriteKit

extension GameScene {
    /// Проверяем не попал ли ГП на движущийся объект
    func checkMovingObjectPos(object: Object, characterMove: Int, isLoseLevelByDefault: Bool = true) -> Bool {
        
        var isLosed = false
        
        if object.moves[object.move] == character.moves[characterMove] {
            if isLoseLevelByDefault {
                loseLevel()
            }
            isLosed = true
        }
        
        if object.type == ObjectType.electric {
            for point in getPointsAround(object.moves[object.move]) {
                if point == character.moves[move] {
                    if isLoseLevelByDefault {
                        loseLevel()
                    }
                    isLosed = true
                }
            }
        }
        
        return isLosed
    }
    
    /// Проверяем не попал ли ГП на статичный объект
    /// - Returns: возвращает true, если ГП попал на статичный объект
    func checkStatisObjectPos(object: StaticObject) -> Bool {
        var characterMove = move
        
        var isLosed = false
        
        if move >= character.moves.count {
            characterMove = character.moves.count - 1
        }
        
        if object.point == self.character.moves[characterMove] {
            if object.type != ObjectType.stopper && object.type != ObjectType.alarmclock && object.type != ObjectType.bridge && object.type != ObjectType.star && object.type != ObjectType.arrow && object.type != ObjectType.tulip && object.type != ObjectType.cabbage && object.type != ObjectType.lock && object.type != ObjectType.key && object.type != ObjectType.magnet && object.type != ObjectType.button {
                loseLevel()
                isLosed = true
            }
        }
        
        if object.type == ObjectType.bomb {
            
            object.movesToExplode = object.movesToExplode - 1
            
            let movesToExplodeLable = object.childNode(withName: "movesToExplode") as? SKLabelNode
            movesToExplodeLable?.text = String(object.movesToExplode)
            
            if object.movesToExplode == 0 {
                
                SKTAudio.sharedInstance().playSoundEffect(filename: "Explosion.wav")
                
                object.removeFromParent()
                
                var scaleFactorIpad: CGFloat = 1
                
                if Model.sharedInstance.isDeviceIpad() {
                    scaleFactorIpad = 2.5
                }
            
                let bombFragment = SKSpriteNode(imageNamed: "Bomb_explosion")
                let size = CGSize(width: bombFragment.size.width * 0.675 * scaleFactorIpad, height: bombFragment.size.height * 0.675 * scaleFactorIpad)
                bombFragment.size = CGSize(width: 0, height: 0)
                bombFragment.position = object.position
                bombFragment.zPosition = 6
                objectsLayer.addChild(bombFragment)
                
                bombFragment.run(SKAction.resize(toWidth: size.width, height: size.height, duration: 0.3), completion: {
                    let points = self.getPointsAround(object.point)
                    
                    for point in points {
                        if point == self.character.moves[self.move - 1] {
                            self.loseLevel()
                            
                            isLosed = true
                        }
                    }
                })
                
                bombFragment.run(SKAction.sequence([SKAction.wait(forDuration: 0.125), SKAction.fadeAlpha(to: 0, duration: 0.225), SKAction.removeFromParent()]))
                
                staticObjects.remove(object)
            }
        }
        
        if object.type == ObjectType.stopper && character.moves[move] == object.point && object.active == true {
            character.moves.insert(character.moves[move], at: move)
            
            object.active = false
        }
        
        if object.type == ObjectType.bridge && character.moves[move] == object.point {
            let characterDirection = getObjectDirection(from: character.moves[move - 1], to: character.moves[move])
            
            // Если направления не совпадают, то проигрыш
            if !checkForSameDirection(firstDirection: characterDirection, secondDirection: object.rotate, directions: [RotationDirection.right, RotationDirection.left]) && !checkForSameDirection(firstDirection: characterDirection, secondDirection: object.rotate, directions: [RotationDirection.top, RotationDirection.bottom]) {
                loseLevel()
                
                isLosed = true
            }
        }
        
        if object.type == ObjectType.spikes {
            if object.spikesActive {
                
                /// Количество шипов вокруг блока
                let countOfSpikes = 4
                
                for index in 0..<countOfSpikes {
                    let offsetFromParent = getNewPointForSpike(index: index)
                    
                    /// Позиция, куда спрайт шипов будет выпущен
                    let newPointForSpike = Point(column: object.point.column + offsetFromParent.column, row: object.point.row + offsetFromParent.row)
                    
                    // Если ГП находится хотя бы на одном из шипов, то уровень проигран
                    if newPointForSpike == character.moves[move] {
                        loseLevel()
                        
                        isLosed = true
                    }
                }
            }
        }
        
        if object.type == ObjectType.star && character.moves[move] == object.point {
            collectStar(object)
        }
        
        // Если попадаем на замок, то проверяем есть ли ключ подходящего цвета
        if object.type == ObjectType.lock && self.character.moves[self.move] == object.point {
            var isLosedOnLock = true
            
            for key in keysInBag {
                if key == object.lockKeyColor {
                    isLosedOnLock = false
                    
                    SKTAudio.sharedInstance().playSoundEffect(filename: "Unlocked.wav")
                    
                    keysInBag.remove(at: keysInBag.index(of: object.lockKeyColor)!)
                    
                    removeCollectedObject(object.lockKeyColor)
                    
                    staticObjects.remove(object)
                    object.run(SKAction.fadeAlpha(to: 0, duration: 0.25), completion: {
                        object.removeFromParent()
                    })
                    
                    break
                }
            }
            
            if isLosedOnLock {
                loseLevel()
                
                isLosed = true
            }
        }
        
        if object.type == ObjectType.key && self.character.moves[self.move] == object.point {
            keysInBag.append(object.lockKeyColor)
            
            staticObjects.remove(object)
            object.run(SKAction.fadeAlpha(to: 0, duration: 0.25), completion: {
                object.removeFromParent()
            })
            
            getCollectedObject(object)
        }
        
        if object.type == ObjectType.magnet && self.character.moves[self.move] == object.point {
            getCollectedObject(object)
            
            staticObjects.remove(object)
            object.run(SKAction.fadeAlpha(to: 0, duration: 0.25), completion: {
                object.removeFromParent()
            })
        }
        
        if object.type == ObjectType.button && self.character.moves[self.move] == object.point {
            changeButtonsState(object, isTap: false)
        }
        
        return isLosed
    }
    
    /// Функция, которая меняет направление движения ГП
    func checkCharacterDirection(characterAtStopper: Bool = false, characterAtAlarmClock: Bool = false) {
        var characterDirectionWalks = getObjectDirection(from: character.moves[move - 1], to: character.moves[move])
        
        if characterAtAlarmClock {
            characterDirectionWalks = getObjectDirection(from: character.moves[move], to: character.moves[move + 1])
        }
        
        if characterDirectionWalks != RotationDirection.top {
            if character.moves[move - 1] != character.moves[move] {
                if characterDirectionWalks == RotationDirection.right {
                    character.run(SKAction.scaleX(to: 1, duration: 0.25))
                }
                
                if characterDirectionWalks == RotationDirection.left {
                    character.run(SKAction.scaleX(to: -1, duration: 0.25))
                }
            }
        }
    }
    
    func worldMove() {
        move += 1
        absoluteMove += 1
        
        var isLosed = false
        for object in movingObjects {
            
            let previousObjectPoint = object.getPoint()
            
            /// Если пчела попадает на тюльпан, то пчела останавливается на 1 ход
            var isBeeStopped = false
            if object.type == ObjectType.bee {
                for tulip in staticObjects {
                    if tulip.type == ObjectType.tulip && tulip.point == object.moves[object.move] {
                        isBeeStopped = true
                        
                        tulip.run(SKAction.fadeAlpha(to: 0, duration: 0.25), completion: {
                            tulip.removeFromParent()
                            self.staticObjects.remove(tulip)
                        })
                    }
                }
            }
            
            /// Если улитка попадает на капусту, то улитка останавливается на 1 ход (то есть на 2)
            var isSnailStopped = true
            if object.type == ObjectType.snail {
                for cabbage in staticObjects {
                    if cabbage.type == ObjectType.cabbage && cabbage.point == object.moves[object.move] {
                        isSnailStopped = false
                        
                        cabbage.run(SKAction.fadeAlpha(to: 0, duration: 0.25), completion: {
                            cabbage.removeFromParent()
                            self.staticObjects.remove(cabbage)
                        })
                    }
                }
            }
            
            if object.type != ObjectType.snail {
                if !isBeeStopped {
                    object.setPoint()
                }
            }
            else {
                if !isSnailStopped || (absoluteMove % 2 == 0) {
                    object.setPoint()
                }
            }
            
            let movingObjectDirection = getObjectDirection(from: previousObjectPoint, to: object.getPoint())
            
            if !isBeeStopped && isSnailStopped {
                if object.type != ObjectType.snail || (object.type == ObjectType.snail && absoluteMove % 2 == 0) {
                    if movingObjectDirection == RotationDirection.left {
                        object.run(SKAction.scaleX(to: 1, duration: 0.25))
                    }
                    
                    if movingObjectDirection == RotationDirection.right {
                        object.run(SKAction.scaleX(to: -1, duration: 0.25))
                    }
                }
            }
            
            var characterMove = move
            if move >= character.moves.count {
                characterMove = character.moves.count - 1
            }
            
            // Если объект и ГП "поменялись местами", то проигрыш
            if object.moves[object.move] == character.moves[characterMove - 1] &&
                previousObjectPoint == character.moves[characterMove] {
                var moveToPointLose = pointFor(column: object.getPoint().column, row: object.getPoint().row)
                
                moveToPointLose = correctDirectionToHalfTile(pointToLose: moveToPointLose, movingDirection: movingObjectDirection)
                
                object.run(SKAction.move(to: moveToPointLose, duration: 0.25), completion: {
                    if !isLosed {
                        isLosed = true
                        self.loseLevel()
                    }
                })
            }
            else {
                object.run(SKAction.move(to: pointFor(column: object.getPoint().column, row: object.getPoint().row), duration: 0.5), completion: {
                    if !isLosed {
                        if self.checkMovingObjectPos(object: object, characterMove: characterMove) == true {
                            isLosed = true
                        }
                    }
                })
            }
        }
        
        if move < character.moves.count && !isLosed {
            /// Если ГП находится на стопе
            var characterAtStopper = false
            
            /// Если ГП находится на ускорителе
            var characterAtAlarmClock = false
            
            for object in staticObjects {
                
                if object.type == ObjectType.bridge {
                    object.run(SKAction.rotate(toAngle: object.zRotation - CGFloat(90 * Double.pi / 180), duration: 0.3))
                    object.rotate = object.rotate.nextPoint()
                    
                    animateBridgeWall(object: object)
                }
                
                if object.type == ObjectType.bridge && self.character.moves[self.move] == object.point {
                    let characterDirection = self.getObjectDirection(from: self.character.moves[self.move - 1], to: self.character.moves[self.move])
                    
                    if self.checkForSameDirection(firstDirection: characterDirection, secondDirection: object.rotate, directions: [RotationDirection.right, RotationDirection.left]) || self.checkForSameDirection(firstDirection: characterDirection, secondDirection: object.rotate, directions: [RotationDirection.top, RotationDirection.bottom]) {
                        isNextCharacterMoveAtBridgeLose = false
                    }
                    else {
                        isNextCharacterMoveAtBridgeLose = true
                    }
                }
                
                if object.type == ObjectType.arrow && self.character.moves[self.move] == object.point {
                    let characterDirection = self.getObjectDirection(from: self.character.moves[self.move - 1], to: self.character.moves[self.move])
                    
                    if characterDirection == object.rotate {
                        isNextCharacterMoveAtBridgeLose = false
                    }
                    else {
                        isNextCharacterMoveAtBridgeLose = true
                    }
                }
                
                if character.moves[move - 1] == object.point && object.type == ObjectType.stopper {
                    characterAtStopper = true
                }
                
                if character.moves[move] == object.point && object.type == ObjectType.alarmclock {
                    characterAtAlarmClock = true
                }
                
                if object.type == ObjectType.spikes {
                    
                    /// Количество шипов вокруг блока
                    let countOfSpikes = 4
                    
                    /// Позиции на которые необходимо смещать
                    let moveToPosValue = CGPoint(x: TileWidth / 1.65, y: TileHeight / 1.65)
                    
                    // Если шипы выпущены
                    if object.spikesActive {
                        for index in 0..<countOfSpikes {
                            object.childNode(withName: "Spike_\(index)")?.run(SKAction.move(to: CGPoint(x: 0, y: 0), duration: 0.35))
                        }
                        
                        object.spikesActive = false
                    }
                    else {
                        for index in 0..<countOfSpikes {
                            let spikeObject = object.childNode(withName: "Spike_\(index)")
                            
                            // Если спрайт шипов был найден (т.е. не за границами игрового поля)
                            if spikeObject != nil {
                                
                                // Удаляем анимацию пульсирования шипов
                                if move == 1 {
                                    spikeObject?.removeAction(forKey: "preloadSpikesAnimation")
                                }
                                
                                let offsetFromParent = getNewPointForSpike(index: index)
                                
                                /// Позиция, куда спрайт шипов будет выпущен
                                let newPointForSpike = Point(column: object.point.column + offsetFromParent.column, row: object.point.row + offsetFromParent.row)
                                
                                // Если новая позиция спрайта шипов не выходит за границу, то вытаскиваем спрайт шипов
                                if newPointForSpike.column >= 0 && newPointForSpike.column < boardSize.column && newPointForSpike.row >= 0 && newPointForSpike.row < boardSize.row {
                                        spikeObject!.run(SKAction.move(to: CGPoint(x: CGFloat(offsetFromParent.column) * moveToPosValue.x, y: CGFloat(offsetFromParent.row) * moveToPosValue.y), duration: 0.35))
                                }
                            }
                            
                            object.spikesActive = true
                        }
                    }
                }
            }
            
            checkCharacterDirection(characterAtStopper: characterAtStopper)
            
            // Если следующий ход на мост (проигрышная позиция)
            if isNextCharacterMoveAtBridgeLose {
                let movingCharacterDirection = self.getObjectDirection(from: character.moves[move - 1], to: character.moves[move])
                var moveToPointLose = self.pointFor(column: self.character.moves[self.move].column, row: self.character.moves[self.move].row)
                
                moveToPointLose = correctDirectionToHalfTile(pointToLose: moveToPointLose, movingDirection: movingCharacterDirection, downScale: 2.5)
                
                character.run(SKAction.move(to: moveToPointLose, duration: 0.25), completion: {
                    self.loseLevel()
                })
            }
            else {
                character.run(SKAction.move(to: self.pointFor(column: self.character.moves[self.move].column, row: self.character.moves[self.move].row), duration: 0.5), completion: {
                    
                    SKTAudio.sharedInstance().playSoundEffect(filename: "GrassStep.mp3")
                    
                    if !characterAtAlarmClock {
                        
                        if self.isCollectedMagnet() {
                            for object in self.staticObjects {
                                self.collectStarAroundMagnet(object)
                            }
                        }
                        
                        var isLosed = false
                        for object in self.staticObjects {
                            if self.checkStatisObjectPos(object: object) == true {
                                isLosed = true
                                break
                            }
                        }
                        
                        if !isLosed {
                            // Если прошёл один ход, то запускает следующий
                            self.mainTimer(interval: 0.15)
                        }
                    }
                    // Если ГП находится на будильнике, то останавливаем все движущиейся объекты на 1 ход и толкаем ГП на 1 ход вперёд
                    else {
                        _ = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: false) { (_) in
                            
                            if self.character.moves[self.move] != self.character.moves.last! {
                                self.checkCharacterDirection(characterAtAlarmClock: true)
                                
                                // Если ГП находится на будильнике, то проверяем есть ли магнит (если есть, то проверяем есть ли звезды вокруг)
                                if self.isCollectedMagnet() {
                                    for object in self.staticObjects {
                                        self.collectStarAroundMagnet(object)
                                    }
                                }
                                
                                self.move += 1
                                
                                self.character.run(SKAction.move(to: self.pointFor(column: self.character.moves[self.move].column, row: self.character.moves[self.move].row), duration: 0.5), completion: {
                                    
                                    SKTAudio.sharedInstance().playSoundEffect(filename: "GrassStep.mp3")
                                    
                                    if self.move < self.character.moves.count - 1 {
                                        
                                        var isLosed = false
                                    
                                        for object in self.movingObjects {
                                            if self.checkMovingObjectPos(object: object, characterMove: self.move) == true {
                                                isLosed = true
                                                break
                                            }
                                        }
                                    
                                        if !isLosed {
                                            if self.isCollectedMagnet() {
                                                for object in self.staticObjects {
                                                    self.collectStarAroundMagnet(object)
                                                }
                                            }
                                            
                                            for object in self.staticObjects {
                                                if self.checkStatisObjectPos(object: object) == true {
                                                    isLosed = true
                                                    break
                                                }
                                            }
                                        }
                                    
                                        if !isLosed {
                                            self.mainTimer(interval: 0.15)
                                        }
                                        
                                    }
                                    else {
                                        self.checkFinish()
                                    }
                                })
                            }
                            else {
                                self.checkFinish()
                            }
                        }
                    }
                })
            }
            
            if self.character.moves[self.move].column < 0 || self.character.moves[self.move].column >= self.boardSize.column ||
                self.character.moves[self.move].row < 0 || self.character.moves[self.move].row >= self.boardSize.row {
                self.loseLevel()
            }
        }
        if move == character.moves.count {
            checkFinish()
        }
    }
    
    func correctDirectionToHalfTile(pointToLose: CGPoint, movingDirection: RotationDirection, downScale: CGFloat = 2) -> CGPoint {
        var moveToPointLose = pointToLose
        
        if movingDirection == RotationDirection.right {
            moveToPointLose.x -= TileWidth / downScale
        }
        
        if movingDirection == RotationDirection.top {
            moveToPointLose.y -= TileHeight / downScale
        }
        
        if movingDirection == RotationDirection.left {
            moveToPointLose.x += TileWidth / downScale
        }
        
        if movingDirection == RotationDirection.bottom {
            moveToPointLose.y += TileHeight / downScale
        }
        
        return moveToPointLose
    }
    
    /// Подбираем объект, который необходимо положить в "рюкзак"
    func getCollectedObject(_ object: StaticObject, animation: Bool = true) {
        if objectInfoView != nil {
            collectedObjects.append(object)
            
            var sprite = object.type.spriteName
            
            if object.type == ObjectType.key {
                sprite = "Key_\(object.lockKeyColor!)"
            }
            
            let objectInBagWidth: CGFloat = 35
            let objectInBagView = UIImageView(image: UIImage(named: sprite))
            objectInBagView.restorationIdentifier = "itemInBag"
            objectInBagView.frame.size = CGSize(width: objectInBagWidth, height: objectInBagView.frame.height / (objectInBagView.frame.width / objectInBagWidth))
            
            objectInBagView.alpha = 0
            
            var pointConvertedForBoard = pointFor(column: object.point.column, row: object.point.row)
            pointConvertedForBoard.x += objectsLayer.position.x
            pointConvertedForBoard.y += objectsLayer.position.y
            
            var pointForBoard = Model.sharedInstance.gameScene.convertPoint(toView: pointConvertedForBoard)
            
            pointForBoard.y -= objectInfoView!.frame.midY
            pointForBoard.y += objectInBagView.frame.height / 2
            pointForBoard.x -= objectInBagView.frame.width / 2
            
            if animation {
                objectInBagView.frame.origin = pointForBoard
            }
            else {
                let xPos = CGFloat(collectedObjects.count - 1) * (objectInBagWidth + 3) + 10 + 60
                objectInBagView.frame.origin = CGPoint(x: xPos, y: objectInfoView!.frame.height / 2 - objectInBagView.frame.height / 2)
                objectInBagView.alpha = 1
            }
            
            objectInfoView!.insertSubview(objectInBagView, at: 0)
            
            if animation {
                let moveToBag = CGPoint(x: 32 - objectInBagView.frame.width / 2, y: objectInfoView!.frame.height / 2 - objectInBagView.frame.height / 2)
                
                let xPosInBag = CGFloat(collectedObjects.count - 1) * (objectInBagWidth + 3) + 10 + 60
                let moveInsideBag = CGPoint(x: xPosInBag, y: objectInfoView!.frame.height / 2 - objectInBagView.frame.height / 2)
                
                UIView.animate(withDuration: 0.105 * Double(boardSize.row + 1), animations: {
                    objectInBagView.frame.origin = moveToBag
                    objectInBagView.alpha = 1
                }, completion: { (_) in
                    SKTAudio.sharedInstance().playSoundEffect(filename: "PickUpItem.wav")
                    
                    UIView.animate(withDuration: TimeInterval(0.105 * CGFloat(self.collectedObjects.count)), animations: {
                        objectInBagView.frame.origin = moveInsideBag
                    })
                })
            }
        }
    }
    
    /// Функция убирает ключ из "рюкзака"
    func removeCollectedObject(_ keyColor: LockKeyColor) {
        for object in collectedObjects {
            if object.lockKeyColor == keyColor {
                collectedObjects.remove(at: collectedObjects.index(of: object)!)
                
                refreshCollectedObjects()
                
                break
            }
        }
    }
    
    /// Функция перерисовывает объекты в "рюкзаке"
    func refreshCollectedObjects() {
        for subview in objectInfoView!.subviews {
            if subview.restorationIdentifier == "itemInBag" {
                subview.removeFromSuperview()
            }
        }
        
        let collectedObjectsVal = collectedObjects
        collectedObjects.removeAll()
        for object in collectedObjectsVal {
            getCollectedObject(object, animation: false)
        }
    }
    
    /// Подобрал ли ГП магнит
    func isCollectedMagnet() -> Bool {
        for object in collectedObjects {
            if object.type == ObjectType.magnet {
                return true
            }
        }
        
        return false
    }
    
    func collectStar(_ object: StaticObject, fadeAnimation: Bool = true) {
        stars -= 1
        staticObjects.remove(object)
        
        SKTAudio.sharedInstance().playSoundEffect(filename: "PickUpStar.mp3")
        
        if fadeAnimation {
            object.run(SKAction.fadeAlpha(to: 0, duration: 0.25), completion: {
                object.removeFromParent()
            })
        }
        else {
            object.removeFromParent()
        }
    }
    
    /// Если подобрали магнит, то проверяем нет ли в радиусе одной клетки звёзд, чтобы их подобрать
    func collectStarAroundMagnet(_ object: StaticObject) {
        if isCollectedMagnet() {
            if object.type == ObjectType.star {
                let pointsAround = getPointsAround(character.moves[move])
            
                for point in pointsAround {
                    if object.point == point {
                        
                        let moveTo = pointFor(column: character.moves[move].column, row: character.moves[move].row)
                        
                        let actionMove = SKAction.move(to: moveTo, duration: 0.25)
                        let actionAlpha = SKAction.fadeAlpha(to: 0, duration: 0.25)
                        
                        object.run(SKAction.group([actionMove, actionAlpha]), completion: {
                            self.collectStar(object, fadeAnimation: false)
                        })
                        
                        break
                    }
                }
            }
        }
    }
    
    func checkFinish() {
        if character.moves.last! == finish && stars == 0 && countButtonsOnLevel(isPressed: true) == buttonsOnLevel {
            winLevel()
        }
        else {
            loseLevel()
        }
    }
    
    /// Функция изменяет состояние всех кнопок
    func changeButtonsState(_ object: StaticObject, isTap: Bool = true) {
        if !object.active {
            SKTAudio.sharedInstance().playSoundEffect(filename: "ClickButton.wav")
            
            for button in staticObjects {
                if button.type == ObjectType.button {
                    if isTap || (object == button && !isTap) {
                        button.active = !button.active
                    }
                    
                    let isPressed = button.active ? "_pressed" : ""
                    
                    let color = button.lockKeyColor!
                    button.setTexture(spriteName: "Button_\(color)\(isPressed)", size: nil)
                }
            }
        }
    }
    
    /// Функция подсчитывает кол-во кнопок на уровне
    ///
    /// - Parameter isPressed: если true, то будет считать только кнопки, которые были нажаты (pressed [object.active = true])
    func countButtonsOnLevel(isPressed: Bool = false) -> Int {
        var count = 0
        for object in staticObjects {
            if object.type == ObjectType.button {
                if (object.active && isPressed) || !isPressed {
                    count += 1
                }
            }
        }
        
        return count
    }
}
