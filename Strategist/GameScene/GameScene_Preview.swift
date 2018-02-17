import Foundation
import SpriteKit

extension GameScene {
    func previewMainTimer() {
        previewTimer.invalidate()
        var move = 0
        previewTimer = Timer.scheduledTimer(withTimeInterval: 0.65, repeats: true) { (previewTimer) in
            move += 1
            self.worldPreview(move: move)
        }
    }
    
    func worldPreview(move: Int) {
        for object in movingObjects {
            
            let previousObjectPoint = object.getPoint()
            
            if object.type != ObjectType.snail {
                object.setPoint()
            }
            else {
                if move % 2 == 0 {
                    
                    object.setPoint()
                }
            }
            
            let movingObjectDirection = getObjectDirection(from: previousObjectPoint, to: object.getPoint())
            
            if object.type != ObjectType.snail || (object.type == ObjectType.snail && move % 2 == 0) {
                if movingObjectDirection == RotationDirection.left {
                    object.run(SKAction.scaleX(to: 1, duration: 0.25))
                }
                
                if movingObjectDirection == RotationDirection.right {
                    object.run(SKAction.scaleX(to: -1, duration: 0.25))
                }
            }
            
            object.run(SKAction.move(to: pointFor(column: object.getPoint().column, row: object.getPoint().row), duration: 0.5))
        }
        
        for object in staticObjects {
            
            if object.type == ObjectType.bridge {
                object.run(SKAction.rotate(toAngle: object.zRotation - CGFloat(90 * Double.pi / 180), duration: 0.3))
                object.rotate = object.rotate.nextPoint()
                
                animateBridgeWall(object: object)
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
                    
                    bombFragment.run(SKAction.resize(toWidth: size.width, height: size.height, duration: 0.3))
                    
                    bombFragment.run(SKAction.sequence([SKAction.wait(forDuration: 0.125), SKAction.fadeAlpha(to: 0, duration: 0.225), SKAction.removeFromParent()]))
                    
                    staticObjects.remove(object)
                }
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
    }
}
