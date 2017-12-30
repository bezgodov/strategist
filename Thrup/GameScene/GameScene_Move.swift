import Foundation
import SpriteKit

extension GameScene {
    func worldMove() {
        move += 1
        
        for object in movingObjects {
            let previousObjectPoint = object.getPoint()
            
            object.setPoint()
            
            let movingObjectDirection = self.getObjectDirection(from: previousObjectPoint, to: object.getPoint())
            
            if movingObjectDirection == RotationDirection.left {
                object.run(SKAction.scaleX(to: 1, duration: 0.25))
            }
            
            if movingObjectDirection == RotationDirection.right {
                object.run(SKAction.scaleX(to: -1, duration: 0.25))
            }
            
            object.run(SKAction.move(to: pointFor(column: object.getPoint().column, row: object.getPoint().row), duration: 0.5), completion: {
                
                var characterMove = self.move
                
                if self.move >= self.character.moves.count {
                    characterMove = self.character.moves.count - 1
                }
                
                if object.moves[object.move] == self.character.moves[characterMove] {
                    self.loseLevel()
                }
                
                if self.move > 0 {
                    if object.moves[object.move] == self.character.moves[characterMove - 1] &&
                        previousObjectPoint == self.character.moves[characterMove] {
                        self.loseLevel()
                    }
                }
                
                if object.type == ObjectType.electric {
                    for point in self.getPointsAround(object.moves[object.move]) {
                        if point == self.character.moves[self.move] {
                            self.loseLevel()
                        }
                    }
                }
            })
        }
        
        if move < character.moves.count {
            for object in staticObjects {
                
                if object.type == ObjectType.bridge {
                    object.run(SKAction.rotate(toAngle: object.zRotation - CGFloat(90 * Double.pi / 180), duration: 0.5))
                    object.rotate = object.rotate.nextPoint()
                }
                
                if object.type == ObjectType.rotatorPointer {
                    object.run(SKAction.rotate(toAngle: object.zRotation - CGFloat(90 * Double.pi / 180), duration: 0.5))
                    object.rotate = object.rotate.nextPoint()
                    
                    if character.moves[move] == object.point {
                        
                    }
                }
                
                if object.type == ObjectType.rotator {
                    object.run(SKAction.rotate(toAngle: object.zRotation - CGFloat(90 * Double.pi / 180), duration: 0.5))
                    
                    object.rotate = RotationDirection.right
                }
            }
            
            let characterDirectionWalks = getObjectDirection(from: character.moves[move - 1], to: character.moves[move])
            
            if characterDirectionWalks == RotationDirection.top {
                character.removeAction(forKey: "playerWalking")
                character.run(SKAction.repeatForever(SKAction.animate(with: [SKTexture(imageNamed: "PlayerPinkClimbs_1"), SKTexture(imageNamed: "PlayerPinkClimbs_2")], timePerFrame: 0.1, resize: false, restore: true)), withKey: "playerClimbing")
            }
            else {
                if character.action(forKey: "playerWalking") == nil {
                    character.removeAction(forKey: "playerClimbing")
                    character.run(SKAction.repeatForever(SKAction.animate(with: playerWalkingFrames, timePerFrame: 0.05, resize: false, restore: true)), withKey: "playerWalking")
                }
                
                if characterDirectionWalks == RotationDirection.right {
                    character.run(SKAction.scaleX(to: 1, duration: 0.25))
                }
                
                if characterDirectionWalks == RotationDirection.left {
                    character.run(SKAction.scaleX(to: -1, duration: 0.25))
                }
            }
            
            //            character.run(SKAction.rotate(toAngle: CGFloat(Double(characterDirectionWalks.rawValue * 90) * Double.pi / 180), duration: 0.3, shortestUnitArc: true))
            
            character.run(SKAction.move(to: self.pointFor(column: self.character.moves[self.move].column, row: self.character.moves[self.move].row), duration: 0.5), completion: {
                
                for object in self.staticObjects {
                    
                    var characterMove = self.move
                    
                    if self.move >= self.character.moves.count {
                        characterMove = self.character.moves.count - 1
                    }
                    
                    if object.point == self.character.moves[characterMove] {
                        if object.type != ObjectType.stopper && object.type != ObjectType.accelerator && object.type != ObjectType.bridge && object.type != ObjectType.star && object.type != ObjectType.rotator {
                            self.loseLevel()
                        }
                    }
                    
                    if object.type == ObjectType.bomb {
                        
                        object.movesToExplode = object.movesToExplode - 1
                        
                        let movesToExplodeLable = object.childNode(withName: "movesToExplode") as? SKLabelNode
                        movesToExplodeLable?.text = String(object.movesToExplode)
                        
                        if object.movesToExplode == 0 {
                            object.removeChildren(in: [object.childNode(withName: "movesToExplode")!])
                            let points = self.getPointsAround(object.point)
                            
                            for point in points {
                                
                                let bombFragment = SKSpriteNode(imageNamed: "Bomb")
                                bombFragment.position = self.pointFor(column: point.column, row: point.row)
                                bombFragment.zPosition = 6
                                self.objectsLayer.addChild(bombFragment)
                                bombFragment.run(SKAction.sequence([SKAction.wait(forDuration: 0.5), SKAction.removeFromParent()]))
                                
                                if point == self.character.moves[self.move] {
                                    self.loseLevel()
                                }
                            }
                            
                            self.staticObjects.remove(object)
                            object.run(SKAction.sequence([SKAction.wait(forDuration: 0.5), SKAction.removeFromParent()]))
                        }
                    }
                    
                    if object.type == ObjectType.stopper && self.character.moves[self.move] == object.point && object.active == true {
                        self.character.moves.insert(self.character.moves[self.move], at: self.move)
                        
                        object.active = false
                    }
                    
                    if self.move < self.character.moves.count - 1 {
                        if self.character.moves[self.move + 1] != self.character.moves.last! {
                            if object.type == ObjectType.accelerator && self.character.moves[self.move + 1] == object.point {
                                self.character.moves.remove(at: self.move + 1)
                            }
                        }
                    }
                    
                    if object.type == ObjectType.bridge && self.character.moves[self.move] == object.point {
                        let characterDirection = self.getObjectDirection(from: self.character.moves[self.move - 1], to: self.character.moves[self.move])
                        
                        if self.checkForSameDirection(firstDirection: characterDirection, secondDirection: object.rotate, directions: [RotationDirection.right, RotationDirection.left]) || self.checkForSameDirection(firstDirection: characterDirection, secondDirection: object.rotate, directions: [RotationDirection.top, RotationDirection.bottom]) {
                            print("ok")
                        }
                        else {
                            self.loseLevel()
                        }
                    }
                    
                    if object.type == ObjectType.star && self.character.moves[self.move] == object.point {
                        self.stars -= 1
                        object.removeFromParent()
                    }
                    
                    /*
                    if object.type == ObjectType.rotator && self.character.moves[self.move] == object.point {
                        self.setExtraPath(direction: object.rotate, from: self.character.moves[self.move], to: self.character.moves[self.move + 1])
                    }
                    */
                }
                
            })
            
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
}
