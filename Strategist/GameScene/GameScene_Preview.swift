import Foundation
import SpriteKit
import Flurry_iOS_SDK

extension GameScene {
    func previewMainTimer() {
        previewTimer.invalidate()
        var move = 0
        previewTimer = Timer.scheduledTimer(withTimeInterval: 0.65, repeats: true) { (_) in
            if move == 0 {
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
            
            move += 1
            self.worldPreview(move: move)
        }
    }
    
    func worldPreview(move: Int) {
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
                if !isSnailStopped || (move % 2 == 0) {
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
    
    func presentPreview() {
        if isPreviewing {
            removeObjectInfoView()
            
            previewTimer.invalidate()
            cleanLevel()
            createLevel()
            isLevelWithTutorial = false
            isPreviewing = false
            
            Model.sharedInstance.gameViewControllerConnect.goToMenuButton.isEnabled = true
            Model.sharedInstance.gameViewControllerConnect.buyLevelButton.isEnabled = true
            Model.sharedInstance.gameViewControllerConnect.startLevel.setImage(UIImage(named: "Menu_start"), for: UIControlState.normal)
        }
        else {
            previewMainTimer()
            isPreviewing = true
            
            removeObjectInfoView()
            for object in movingObjects {
                object.path(hide: true)
            }
            
            presentObjectInfoView(spriteName: "PlayerStaysFront", description: NSLocalizedString("Preview mode", comment: ""))
            
            Model.sharedInstance.gameViewControllerConnect.goToMenuButton.isEnabled = false
            Model.sharedInstance.gameViewControllerConnect.buyLevelButton.isEnabled = false
            Model.sharedInstance.gameViewControllerConnect.startLevel.setImage(UIImage(named: "Menu_stop"), for: UIControlState.normal)
        }
    }
    
    func buyPreviewOnGameBoard() {
        if Model.sharedInstance.getCountGems() >= PREVIEW_MODE_PRICE {
            let message = "\(NSLocalizedString("Buying preview mode for all time is worth", comment: "")) \(PREVIEW_MODE_PRICE) \(NSLocalizedString("GEMS", comment: "")) (\(NSLocalizedString("you have", comment: "")) \(Model.sharedInstance.getCountGems()) \(NSLocalizedString("GEMS", comment: "")))"
            
            let alert = UIAlertController(title: NSLocalizedString("Buying preview mode", comment: ""), message: message, preferredStyle: UIAlertControllerStyle.alert)
            
            let actionCancel = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: UIAlertActionStyle.cancel, handler: { (_) in
                let eventParams = ["level": Model.sharedInstance.currentLevel, "countGems": Model.sharedInstance.getCountGems()]
                
                Flurry.logEvent("Cancel_buy_preview_mode", withParameters: eventParams)
            })
            
            let actionOk = UIAlertAction(title: NSLocalizedString("Buy", comment: ""), style: UIAlertActionStyle.default, handler: { (_) in
                Model.sharedInstance.setValuePreviewMode(true)
                
                let eventParams = ["level": Model.sharedInstance.currentLevel, "countGems": Model.sharedInstance.getCountGems()]
                
                // Отнимаем 50 драг. камней, ибо мы покупаем
                Model.sharedInstance.setCountGems(amountGems: -PREVIEW_MODE_PRICE)
                
                Flurry.logEvent("Buy_preview_mode", withParameters: eventParams)
                
                self.presentPreview()
            })
            
            alert.addAction(actionOk)
            alert.addAction(actionCancel)
            
            Model.sharedInstance.gameViewControllerConnect.present(alert, animated: true, completion: nil)
        }
        else {
            let message = "\(NSLocalizedString("Expensive Preview mode", comment: "")). \(NSLocalizedString("You need", comment: "")) \(PREVIEW_MODE_PRICE) \(NSLocalizedString("GEMS", comment: "")), \(NSLocalizedString("but you only have", comment: "")) \(Model.sharedInstance.getCountGems()) \(NSLocalizedString("GEMS", comment: ""))"
            
            let alert = UIAlertController(title: NSLocalizedString("Not enough GEMS", comment: ""), message: message, preferredStyle: UIAlertControllerStyle.alert)
            
            let actionCancel = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: UIAlertActionStyle.cancel, handler: { (in) in
                let eventParams = ["level": Model.sharedInstance.currentLevel, "countGems": Model.sharedInstance.getCountGems()]
                
                Flurry.logEvent("Cancel_buy_preview_mode_not_enough_gems", withParameters: eventParams)
            })
            
            let actionOk = UIAlertAction(title: NSLocalizedString("Buy GEMS", comment: ""), style: UIAlertActionStyle.default, handler: { (_) in
                let eventParams = ["level": Model.sharedInstance.currentLevel, "countGems": Model.sharedInstance.getCountGems()]
                
                Flurry.logEvent("Buy_gems_preview_mode_not_enough_gems", withParameters: eventParams)
                
                Model.sharedInstance.gameViewControllerConnect.presentMenu(dismiss: true)
            })
            
            alert.addAction(actionOk)
            alert.addAction(actionCancel)
            
            Model.sharedInstance.gameViewControllerConnect.present(alert, animated: true, completion: nil)
        }
    }
}
