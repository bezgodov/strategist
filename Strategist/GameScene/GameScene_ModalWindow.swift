import SpriteKit
import Foundation
import Flurry_iOS_SDK

extension GameScene {
    /// Модальное окно
    enum modalWindowType {
        case win, lose, nolives, menu
    }
    
    /// Моадльное окно
    ///
    /// - Parameter type: тип модального окна: выйгрыш/проигрыш
    func modalWindowPresent(type: modalWindowType) {
        
        // Если текущий уровень boss, то останавливаем все таймеры
        if bossLevel != nil {
            if type == modalWindowType.menu || type == modalWindowType.lose {
                bossEnemies.speed = 0
                objectsLayer.speed = 0
                bossLevel?.cleanTimers()
            }
        }
        
        // Добавляем бг, чтобы при клике на него закрыть всё модальное окно
        modalWindowBg = UIView(frame: self.view!.bounds)
        modalWindowBg.backgroundColor = UIColor.black
        modalWindowBg.alpha = 0
        modalWindowBg.restorationIdentifier = "modalWindowBg"
        
        if type == modalWindowType.menu {
            modalWindowBg.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(bgClick(_:))))
            self.isPaused = true
        }
        else {
            modalWindowBg.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(shakeModalWindow(_:))))
        }
        
        // Добавляем модальное окно
        modalWindow = UIView(frame: CGRect(x: self.view!.frame.maxX, y: self.view!.bounds.midY - 200 / 2, width: 220, height: 200))
        
        if type == modalWindowType.menu {
            modalWindow.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(bgClick(_:))))
            
            // Добавляем иконку закрытия модального окна
            let modalWindowClose = UIImageView(image: UIImage(named: "Modal_window_close"))
            modalWindowClose.frame.size = CGSize(width: modalWindowClose.frame.size.width * 0.1, height: modalWindowClose.frame.size.height * 0.1)
            modalWindowClose.frame.origin = CGPoint(x: modalWindow.frame.width + 3, y: 0 - modalWindowClose.frame.size.height)
            modalWindow.addSubview(modalWindowClose)
        }
        
        // Если обучение на 1-ом уровне, то модальное окно должно быть ниже бг для обучения
        if Model.sharedInstance.currentLevel == 1 && !Model.sharedInstance.isCompletedLevel(Model.sharedInstance.currentLevel) {
            self.view!.insertSubview(modalWindowBg, belowSubview: mainBgTutorial)
            self.view!.insertSubview(modalWindow, belowSubview: mainBgTutorial)
        }
        else {
            self.view!.addSubview(modalWindowBg)
            self.view!.addSubview(modalWindow)
        }
        
        UIView.animate(withDuration: 0.215, animations: {
            self.modalWindowBg.alpha = 0.5
            
            self.modalWindow.frame.origin.x = self.view!.bounds.midX - self.modalWindow.frame.size.width / 2
        }, completion: { (_) in
            // Если выйгрыш, то добавляем фейерверк
            if type == modalWindowType.win {
                self.createFireWorks()
            }
        })
        
        if type != modalWindowType.menu {
            let modalWindowTitleView = UIView(frame: CGRect(x: 0, y: -10 - modalWindow.frame.height / 4, width: modalWindow.frame.width, height: modalWindow.frame.height / 4))
            modalWindowTitleView.backgroundColor = UIColor.init(red: 0, green: 109 / 255, blue: 240 / 255, alpha: 1)
            modalWindowTitleView.layer.cornerRadius = 15
            modalWindowTitleView.layer.shadowColor = UIColor.black.cgColor
            modalWindowTitleView.layer.shadowOffset = CGSize.zero
            modalWindowTitleView.layer.shadowOpacity = 0.35
            modalWindowTitleView.layer.shadowRadius = 10
            modalWindow.addSubview(modalWindowTitleView)
            
            let modalWindowTitleLabel = UILabel(frame: CGRect(x: 0, y: 0, width: modalWindowTitleView.frame.width, height: modalWindowTitleView.frame.height))
            
            modalWindowTitleLabel.text = "\(NSLocalizedString("Level", comment: "")) \(Model.sharedInstance.currentLevel)"
            
            if Model.sharedInstance.currentLevel % Model.sharedInstance.distanceBetweenSections == 0 {
                let bossNumberTitle = Model.sharedInstance.currentLevel / Model.sharedInstance.distanceBetweenSections
                modalWindowTitleLabel.text = "\(NSLocalizedString("BOSS", comment: "")) #\(bossNumberTitle)"
            }
            
            modalWindowTitleLabel.textAlignment = NSTextAlignment.center
            modalWindowTitleLabel.font = UIFont(name: "AvenirNext-DemiBold", size: 24)
            modalWindowTitleLabel.textColor = UIColor.white
            modalWindowTitleView.addSubview(modalWindowTitleLabel)
        }
        
        /// Название выбранного уровня (для выйгрышного модального окна)
        let endingSentence = [NSLocalizedString("Awesome", comment: ""), NSLocalizedString("Well done", comment: ""), NSLocalizedString("Nice", comment: ""), NSLocalizedString("Great job", comment: ""), NSLocalizedString("Cool", comment: ""), NSLocalizedString("Good job", comment: ""), NSLocalizedString("Perfect", comment: ""), NSLocalizedString("Amazing", comment: "")]
        
        // Кнопка "настройки" в модальном окне
        let goToSettingsBtn = UIButton(frame: CGRect(x: modalWindow.bounds.midX - ((modalWindow.frame.width - 40) / 2), y: modalWindow.frame.size.height - 50 - 15, width: modalWindow.frame.width - 40, height: 50))
        goToSettingsBtn.layer.cornerRadius = 10
        goToSettingsBtn.backgroundColor = UIColor.init(red: 165 / 255, green: 240 / 255, blue: 16 / 255, alpha: 1)
        goToSettingsBtn.setTitleColor(UIColor.black, for: UIControlState.normal)
        goToSettingsBtn.titleLabel?.font = UIFont(name: "AvenirNext-Medium", size: 19)
        goToSettingsBtn.setTitle(NSLocalizedString("SETTINGS", comment: ""), for: UIControlState.normal)
        modalWindow.addSubview(goToSettingsBtn)
        
        let sentenceLabel = UILabel(frame: CGRect(x: 20, y: 25, width: modalWindow.frame.size.width - 40, height: 35))
        sentenceLabel.textAlignment = NSTextAlignment.left
        sentenceLabel.font = UIFont(name: "AvenirNext-DemiBold", size: 24)
        sentenceLabel.textColor = UIColor.white
        modalWindow.addSubview(sentenceLabel)
        
        // Кнопка "старт/рестарт" в модальном окне
        let startBtn = UIButton(frame: CGRect(x: modalWindow.bounds.midX - ((modalWindow.frame.width - 40) / 2), y: modalWindow.bounds.midY - 50 / 2, width: modalWindow.frame.width - 40, height: 50))
        startBtn.layer.cornerRadius = 10
        startBtn.backgroundColor = UIColor.init(red: 217 / 255, green: 29 / 255, blue: 29 / 255, alpha: 1)
        startBtn.titleLabel?.font = UIFont(name: "AvenirNext-Medium", size: 19)
        
        // В зависимости от модального окна выставляем нужные кнопки и действия к ним
        if type == modalWindowType.win || type == modalWindowType.menu {
            if type == modalWindowType.menu {
                startBtn.setTitle(NSLocalizedString("LEVELS", comment: ""), for: UIControlState.normal)
                startBtn.addTarget(self, action: #selector(goToLevelsFromMenu), for: .touchUpInside)
            }
            else {
                startBtn.setTitle(NSLocalizedString("CONTINUE", comment: ""), for: UIControlState.normal)
                startBtn.addTarget(self, action: #selector(nextLevel), for: .touchUpInside)
            }
            
            goToSettingsBtn.addTarget(self, action: #selector(goToSettings), for: .touchUpInside)
            
            if type != modalWindowType.menu {
                sentenceLabel.text = endingSentence[Int(arc4random_uniform(UInt32(endingSentence.count)))]
            }
            else {
                sentenceLabel.text = "\(NSLocalizedString("Level", comment: "")) \(Model.sharedInstance.currentLevel)"
                
                if Model.sharedInstance.currentLevel % Model.sharedInstance.distanceBetweenSections == 0 {
                    let bossNumberTitle = Model.sharedInstance.currentLevel / Model.sharedInstance.distanceBetweenSections
                    sentenceLabel.text = "\(NSLocalizedString("BOSS", comment: "")) #\(bossNumberTitle)"
                }
            }
        }
        else {
            goToSettingsBtn.setTitle(NSLocalizedString("LEVELS", comment: ""), for: UIControlState.normal)
            goToSettingsBtn.addTarget(self, action: #selector(goToLevelsAfterLose), for: .touchUpInside)
            
            if type == modalWindowType.lose {
                startBtn.setTitle(NSLocalizedString("RESTART", comment: ""), for: UIControlState.normal)
                startBtn.addTarget(self, action: #selector(restartLevelObjc), for: .touchUpInside)
                
                sentenceLabel.text = NSLocalizedString("You lose", comment: "")
            }
            else {
                startBtn.setTitle(NSLocalizedString("EXTRA LIFE", comment: ""), for: UIControlState.normal)
                startBtn.addTarget(self, action: #selector(addExtraLife), for: .touchUpInside)
                
                sentenceLabel.text = NSLocalizedString("No lives", comment: "")
            }
        }
        
        modalWindow.addSubview(startBtn)
        
        let countOfGemsImage = UIImageView(image: UIImage(named: "Gem_blue"))
        countOfGemsImage.frame.size = CGSize(width: countOfGemsImage.frame.size.width * 0.75, height: countOfGemsImage.frame.size.height * 0.75)
        countOfGemsImage.frame.origin = CGPoint(x: modalWindow.frame.size.width - 35 - 20, y: 22)
        modalWindow.addSubview(countOfGemsImage)
        
        countGemsModalWindowLabel = UILabel(frame: CGRect(x: countOfGemsImage.frame.width / 2 - 75 / 2, y: 10, width: 75, height: 50))
        countGemsModalWindowLabel.font = UIFont(name: "AvenirNext-Bold", size: 14)
        countGemsModalWindowLabel.text = "X\(Model.sharedInstance.getCountGems())"
        countGemsModalWindowLabel.textAlignment = NSTextAlignment.center
        countGemsModalWindowLabel.textColor = UIColor.white
        countOfGemsImage.addSubview(countGemsModalWindowLabel)
        
        modalWindow.backgroundColor = UIColor.init(red: 0, green: 109 / 255, blue: 240 / 255, alpha: 1)
        modalWindow.layer.cornerRadius = 15
        modalWindow.layer.shadowColor = UIColor.black.cgColor
        modalWindow.layer.shadowOffset = CGSize.zero
        modalWindow.layer.shadowOpacity = 0.35
        modalWindow.layer.shadowRadius = 10
        
        isModalWindowOpen = true
    }
    
    @objc func nextLevel(_ sender: UIButton) {
        SKTAudio.sharedInstance().playSoundEffect(filename: "Click_ModalWindow.wav")
        
        let eventParams = ["level": Model.sharedInstance.currentLevel]
        
        Flurry.logEvent("Continue_from_modal_window", withParameters: eventParams)
        
        Model.sharedInstance.gameViewControllerConnect.goToLevels(moveCharacterFlag: true)
        
        Model.sharedInstance.currentLevel += 1
        
        isModalWindowOpen = false
    }
    
    @objc func restartLevelObjc(_ sender: UIButton) {
        SKTAudio.sharedInstance().playSoundEffect(filename: "Click_ModalWindow.wav")
        
        SKTAudio.sharedInstance().resumeBackgroundMusic()
        
        let eventParams = ["level": Model.sharedInstance.currentLevel, "isCompletedLevel": Model.sharedInstance.isCompletedLevel(Model.sharedInstance.currentLevel), "countLives": Model.sharedInstance.getLevelLives(Model.sharedInstance.currentLevel)] as [String : Any]
        
        Flurry.logEvent("Restart_level_from_modal_window", withParameters: eventParams)
        
        restartingLevel()
    }
    
    @objc func bgClick(_ sender: UITapGestureRecognizer) {
        if sender.view?.restorationIdentifier == "modalWindowBg" {
            SKTAudio.sharedInstance().playSoundEffect(filename: "Swish.wav")
            
            UIView.animate(withDuration: 0.215, animations: {
                self.modalWindow.frame.origin.x = self.view!.bounds.maxX
                self.modalWindowBg.alpha = 0
            }, completion: { (_) in
                
                self.modalWindowBg.removeFromSuperview()
                self.modalWindow.removeFromSuperview()
                
                // Если текущий уровень "boss", то добавляем таймеры генерации объектов (так как паузу сняли)
                if self.bossLevel != nil {
                    self.bossLevel?.prepareBossLevel()
                }
                else {
                    self.isPaused = false
                }
                
                self.isModalWindowOpen = false
            })
        }
    }
    
    @objc func shakeModalWindow(_ sender: UITapGestureRecognizer) {
        if modalWindow != nil {
            if modalWindow.superview != nil {
                shakeView(modalWindow)
            }
        }
    }
    
    func restartingLevel() {
        self.isPaused = false
        objectsLayer.speed = 1

        
        for object in movingObjects {
            object.run(SKAction.move(to: pointFor(column: object.moves!.first!.column, row: object.moves!.first!.row), duration: 0.215))
        }
        
        // Если текущий уровень "boss" и начали уровень заново, то очищаем таймеры
        if bossLevel != nil {
            bossLevel?.cleanTimers()
        }
        
        character.run(SKAction.move(to: pointFor(column: characterStart.column, row: characterStart.row), duration: 0.215))
        
        UIView.animate(withDuration: 0.215, animations: {
            self.modalWindow.frame.origin.x = self.view!.frame.maxX
            self.modalWindowBg.alpha = 0
        }, completion: { (_) in
            
            self.modalWindowBg.removeFromSuperview()
            self.modalWindow.removeFromSuperview()
            self.restartLevel()
            
            self.isModalWindowOpen = false
        })
    }
    
    @objc func addExtraLife(_ sender: UIButton) {
        SKTAudio.sharedInstance().playSoundEffect(filename: "Click_ModalWindow.wav")
        
        SKTAudio.sharedInstance().resumeBackgroundMusic()
        
        // Если больше 10 драг. камней
        if Model.sharedInstance.getCountGems() >= EXTRA_LIFE_PRICE {
            let message = "\(NSLocalizedString("An extra life is worth", comment: "")) \(EXTRA_LIFE_PRICE) \(NSLocalizedString("GEMS", comment: "")) (\(NSLocalizedString("you have", comment: "")) \(Model.sharedInstance.getCountGems()) \(NSLocalizedString("GEMS", comment: "")))"
            let alert = UIAlertController(title: NSLocalizedString("Buying an extra life", comment: ""), message: message, preferredStyle: UIAlertControllerStyle.alert)
            
            let actionCancel = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: UIAlertActionStyle.cancel, handler: { (_) in
                let eventParams = ["level": Model.sharedInstance.currentLevel, "countGems": Model.sharedInstance.getCountGems()]
                
                Flurry.logEvent("Cancel_buy_extra_life_modal_window", withParameters: eventParams)
            })
            
            let actionOk = UIAlertAction(title: NSLocalizedString("Buy one life", comment: ""), style: UIAlertActionStyle.default, handler: { (_) in
                let eventParams = ["level": Model.sharedInstance.currentLevel, "countGems": Model.sharedInstance.getCountGems()]
                
                Model.sharedInstance.setCountGems(amountGems: -EXTRA_LIFE_PRICE)
                
                Flurry.logEvent("Buy_extra_life_modal_window", withParameters: eventParams)
                
                Model.sharedInstance.setLevelLives(level: Model.sharedInstance.currentLevel, newValue: Model.sharedInstance.getLevelLives(Model.sharedInstance.currentLevel) + 1)
                
                self.restartingLevel()
            })
            
            alert.addAction(actionOk)
            alert.addAction(actionCancel)
            
            Model.sharedInstance.gameViewControllerConnect.present(alert, animated: true, completion: nil)
        }
        else {
            let message = "\(NSLocalizedString("You do not have enough GEMS to buy an extra life", comment: "")). \(NSLocalizedString("You need", comment: "")) \(EXTRA_LIFE_PRICE) \(NSLocalizedString("GEMS", comment: "")), \(NSLocalizedString("but you only have", comment: "")) \(Model.sharedInstance.getCountGems()) \(NSLocalizedString("GEMS", comment: ""))"
            let alert = UIAlertController(title: NSLocalizedString("Not enough GEMS", comment: ""), message: message, preferredStyle: UIAlertControllerStyle.alert)
            
            let actionCancel = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: UIAlertActionStyle.cancel, handler: { (_) in
                let eventParams = ["level": Model.sharedInstance.currentLevel, "countGems": Model.sharedInstance.getCountGems()]
                
                Flurry.logEvent("Cancel_buy_extra_life_modal_window_not_enough_gems", withParameters: eventParams)
            })
            let actionOk = UIAlertAction(title: NSLocalizedString("Buy GEMS", comment: ""), style: UIAlertActionStyle.default, handler: { (_) in
                let eventParams = ["level": Model.sharedInstance.currentLevel, "countGems": Model.sharedInstance.getCountGems()]
                
                Flurry.logEvent("Buy_gems_extra_life_modal_window_not_enough_gems", withParameters: eventParams)
                
                Model.sharedInstance.gameViewControllerConnect.presentMenu(dismiss: true)
            })
            
            alert.addAction(actionOk)
            alert.addAction(actionCancel)
            
            Model.sharedInstance.gameViewControllerConnect.present(alert, animated: true, completion: nil)
        }
    }
    
    @objc func goToLevelsFromMenu(_ sender: UIButton) {
        goToLevels(modalWindowType.menu)
    }
    
    @objc func goToLevelsAfterLose(_ sender: UIButton) {
        goToLevels(modalWindowType.lose)
    }
    
    func goToLevels(_ type: modalWindowType) {
        SKTAudio.sharedInstance().playSoundEffect(filename: "Click_ModalWindow.wav")
        
        SKTAudio.sharedInstance().resumeBackgroundMusic()
        
        let eventParams = ["level": Model.sharedInstance.currentLevel, "isCompletedLevel": Model.sharedInstance.isCompletedLevel(Model.sharedInstance.currentLevel), "countLives": Model.sharedInstance.getLevelLives(Model.sharedInstance.currentLevel)] as [String : Any]
        
        if type == modalWindowType.lose {
            Flurry.logEvent("Go_to_levels_after_lose_from_modal_window", withParameters: eventParams)
        }
        else {
            Flurry.logEvent("Go_to_levels_from_menu_from_modal_window", withParameters: eventParams)
        }
        
        Model.sharedInstance.gameViewControllerConnect.goToLevels()
    }
    
    @objc func goToSettings(_ sender: UIButton) {
        SKTAudio.sharedInstance().playSoundEffect(filename: "Click_ModalWindow.wav")
        
        Model.sharedInstance.gameViewControllerConnect.presentMenu(dismiss: true)
    }
    
    /// Функция отображает фейерверк при выйгрыше уровня
    func createFireWorks() {
        let rootLayer:CALayer = CALayer()
        let emitterLayer:CAEmitterLayer = CAEmitterLayer()
        
        var yPos = 0 + self.view!.bounds.height / 2
        if Model.sharedInstance.isDeviceIpad() {
            yPos -= self.view!.bounds.height / 4
        }
        
        rootLayer.bounds = CGRect(x: 0 + self.view!.bounds.width / 4 / 2, y: yPos, width: self.view!.bounds.width - self.view!.bounds.width / 4, height: self.view!.bounds.height / 2)
        
        rootLayer.anchorPoint = CGPoint(x: 1, y: 1)
        
        let image = UIImage(named: "Fireworks_particle")
        let img:CGImage = (image?.cgImage)!
        
        rootLayer.setAffineTransform(CGAffineTransform(rotationAngle: CGFloat(Double.pi)))
        emitterLayer.emitterPosition = CGPoint(x: rootLayer.bounds.width/2,y: 0 - self.view!.bounds.height / 4)
        emitterLayer.renderMode = kCAEmitterLayerAdditive
        
        let emitterCell = CAEmitterCell()
        
        emitterCell.emissionLongitude = CGFloat(Double.pi / 2)
        emitterCell.emissionLatitude = 0
        emitterCell.lifetime = 2.6
        emitterCell.birthRate = 1.5
        emitterCell.velocity = 300
        emitterCell.velocityRange = 100
        emitterCell.yAcceleration = 150
        emitterCell.emissionRange = CGFloat(Double.pi / 4)
        
        let newColor = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.5).cgColor
        emitterCell.color = newColor
        
        emitterCell.redRange = 0.9
        emitterCell.greenRange = 0.9
        emitterCell.blueRange = 0.9
        emitterCell.name = "base"
        
        let flareCell = CAEmitterCell()
        
        flareCell.contents = img
        flareCell.emissionLongitude = CGFloat(4 * Double.pi) / 2
        flareCell.scale = 0.4
        flareCell.velocity = 80
        flareCell.birthRate = 20
        flareCell.lifetime = 0.5
        flareCell.yAcceleration = -350
        flareCell.emissionRange = CGFloat(Double.pi / 7)
        flareCell.alphaSpeed = -0.7
        flareCell.scaleSpeed = -0.1
        flareCell.scaleRange = 0.1
        flareCell.beginTime = 0.01
        flareCell.duration = 1.7
        
        let fireworkCell = CAEmitterCell()
        
        fireworkCell.contents = img
        fireworkCell.birthRate = 15000
        fireworkCell.scale = 0.6
        fireworkCell.velocity = 130
        fireworkCell.lifetime = 100
        fireworkCell.alphaSpeed = -0.2
        fireworkCell.yAcceleration = -80
        fireworkCell.beginTime = 1.5
        fireworkCell.duration = 0.1
        fireworkCell.emissionRange = 2 * CGFloat(Double.pi)
        fireworkCell.scaleSpeed = -0.1
        fireworkCell.spin = 2
        
        emitterCell.emitterCells = [flareCell,fireworkCell]
        emitterLayer.emitterCells = [emitterCell]
        rootLayer.addSublayer(emitterLayer)
        
        Timer.scheduledTimer(withTimeInterval: 15, repeats: false) { (_) in
            emitterLayer.removeFromSuperlayer()
        }
        
        self.view!.layer.insertSublayer(rootLayer, below: modalWindow.layer)
    }
}
