import Foundation
import SpriteKit

extension GameScene {
    /// Проверяем не попал ли ГП на движущийся объект
    func checkMovingObjectPos(object: Object, characterMove: Int) {
        if object.moves[object.move] == character.moves[characterMove] {
            loseLevel()
        }
        
        if object.type == ObjectType.electric {
            for point in getPointsAround(object.moves[object.move]) {
                if point == character.moves[move] {
                    loseLevel()
                }
            }
        }
    }
    
    /// Проверяем не попал ли ГП на статичный объект
    func checkStatisObjectPos(object: StaticObject) {
        var characterMove = move
        if move >= character.moves.count {
            characterMove = character.moves.count - 1
        }
        
        if object.point == self.character.moves[characterMove] {
            if object.type != ObjectType.stopper && object.type != ObjectType.alarmclock && object.type != ObjectType.bridge && object.type != ObjectType.star && object.type != ObjectType.rotator {
                loseLevel()
            }
        }
        
        if object.type == ObjectType.bomb {
            
            object.movesToExplode = object.movesToExplode - 1
            
            let movesToExplodeLable = object.childNode(withName: "movesToExplode") as? SKLabelNode
            movesToExplodeLable?.text = String(object.movesToExplode)
            
            if object.movesToExplode == 0 {
                
                SKTAudio.sharedInstance().playSoundEffect(filename: "Explosion.wav")
                
                object.removeFromParent()
            
                let bombFragment = SKSpriteNode(imageNamed: "Bomb_explosion")
                let size = CGSize(width: bombFragment.size.width * 0.675, height: bombFragment.size.height * 0.675)
                bombFragment.size = CGSize(width: 0, height: 0)
                bombFragment.position = object.position
                bombFragment.zPosition = 6
                objectsLayer.addChild(bombFragment)
                
                bombFragment.run(SKAction.resize(toWidth: size.width, height: size.height, duration: 0.15), completion: {
                    let points = self.getPointsAround(object.point)
                    
                    for point in points {
                        if point == self.character.moves[self.move - 1] {
                            self.loseLevel()
                        }
                    }
                })
                
                bombFragment.run(SKAction.sequence([SKAction.wait(forDuration: 0.05), SKAction.fadeAlpha(to: 0, duration: 0.25), SKAction.removeFromParent()]))
                
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
                    }
                }
            }
        }
        
        if object.type == ObjectType.star && character.moves[move] == object.point {
            stars -= 1
            
            SKTAudio.sharedInstance().playSoundEffect(filename: "PickUpStar.mp3")
            
            object.removeFromParent()
        }
        
        /*
         if object.type == ObjectType.rotator && character.moves[move] == object.point {
         setExtraPath(direction: object.rotate, from: character.moves[move], to: character.moves[move + 1])
         }
         */
    }
    
    /// Функция, которая меняет направление движения ГП
    func checkCharacterDirection(characterAtStopper: Bool = false, characterAtAlarmClock: Bool = false) {
        var characterDirectionWalks = getObjectDirection(from: character.moves[move - 1], to: character.moves[move])
        
        if characterAtAlarmClock {
            characterDirectionWalks = getObjectDirection(from: character.moves[move], to: character.moves[move + 1])
        }
        
        if characterDirectionWalks == RotationDirection.top {
            character.removeAction(forKey: "playerWalking")
            character.run(SKAction.repeatForever(SKAction.animate(with: [SKTexture(imageNamed: "PlayerPinkClimbs_1"), SKTexture(imageNamed: "PlayerPinkClimbs_2")], timePerFrame: 0.1, resize: false, restore: true)), withKey: "playerClimbing")
        }
        else {
            if character.action(forKey: "playerWalking") == nil {
                character.removeAction(forKey: "playerClimbing")
                character.run(SKAction.repeatForever(SKAction.animate(with: playerWalkingFrames, timePerFrame: 0.05, resize: false, restore: true)), withKey: "playerWalking")
            }
            
            if !characterAtStopper {
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
        
        for object in movingObjects {
            
            let previousObjectPoint = object.getPoint()
            
            object.setPoint()
            
            let movingObjectDirection = getObjectDirection(from: previousObjectPoint, to: object.getPoint())
            
            if movingObjectDirection == RotationDirection.left {
                object.run(SKAction.scaleX(to: 1, duration: 0.25))
            }
            
            if movingObjectDirection == RotationDirection.right {
                object.run(SKAction.scaleX(to: -1, duration: 0.25))
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
                    self.loseLevel()
                })
            }
            else {
                object.run(SKAction.move(to: pointFor(column: object.getPoint().column, row: object.getPoint().row), duration: 0.5), completion: {
                    
                    self.checkMovingObjectPos(object: object, characterMove: characterMove)
                })
            }
        }
        
        if move < character.moves.count {
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
                
                if object.type == ObjectType.rotatorPointer {
                    object.run(SKAction.rotate(toAngle: object.zRotation - CGFloat(90 * Double.pi / 180), duration: 0.5))
                    object.rotate = object.rotate.nextPoint()
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
                
                if object.type == ObjectType.rotator {
                    object.run(SKAction.rotate(toAngle: object.zRotation - CGFloat(90 * Double.pi / 180), duration: 0.5))
                    
                    object.rotate = RotationDirection.right
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
                    
                    // Если прошёл один ход, то запускает следующий
                    self.mainTimer(interval: 0.4)
                })
            }
            else {
                character.run(SKAction.move(to: self.pointFor(column: self.character.moves[self.move].column, row: self.character.moves[self.move].row), duration: 0.5), completion: {
                    
                    SKTAudio.sharedInstance().playSoundEffect(filename: "GrassStep.mp3")
                    
                    if !characterAtAlarmClock {
                        for object in self.staticObjects {
                            self.checkStatisObjectPos(object: object)
                        }
                        
                        // Если прошёл один ход, то запускает следующий
                        self.mainTimer(interval: 0.15)
                    }
                    // Если ГП находится на будильнике, то останавливаем все движущиейся объекты на 1 ход и толкаем ГП на 1 ход вперёд
                    else {
                        DispatchQueue.main.async() {
                            self.character.run(SKAction.wait(forDuration: 0.1), completion: {
                                self.checkCharacterDirection(characterAtAlarmClock: true)
                                self.move += 1
                            
                                self.character.run(SKAction.move(to: self.pointFor(column: self.character.moves[self.move].column, row: self.character.moves[self.move].row), duration: 0.5), completion: {
                                    if self.move < self.character.moves.count - 1 {
                                        if self.character.moves[self.move + 1] != self.character.moves.last! {
                                            
                                            for object in self.movingObjects {
                                                self.checkMovingObjectPos(object: object, characterMove: self.move)
                                            }
                                            
                                            for object in self.staticObjects {
                                                self.checkStatisObjectPos(object: object)
                                            }
                                            
                                            self.mainTimer(interval: 0.15)
                                        }
                                    }
                                })
                            })
                            
                            // Если прошёл один ход, то запускает следующий
                            //self.mainTimer()
                        }
                    }
                })
            }
            
            if self.character.moves[self.move].column < 0 || self.character.moves[self.move].column >= self.boardSize.column ||
                self.character.moves[self.move].row < 0 || self.character.moves[self.move].row >= self.boardSize.row {
                self.loseLevel()
            }
        }
        
        if self.move == self.character.moves.count {
            if self.character.moves.last! == self.finish && self.stars == 0 {
                self.winLevel()
            }
            else {
                self.loseLevel()
            }
        }
    }
    
    func checkForWinningPoint() {
        
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
}
