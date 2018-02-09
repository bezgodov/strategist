import SpriteKit
import Foundation

extension GameScene {
    /// Модальное окно
    enum modalWindowType {
        case win, lose, nolives
    }
    
    /// Моадльное окно
    ///
    /// - Parameter type: тип модального окна: выйгрыш/проигрыш
    func modalWindowPresent(type: modalWindowType) {
        // Добавляем бг, чтобы при клике на него закрыть всё модальное окно
        modalWindowBg = UIView(frame: self.view!.bounds)
        modalWindowBg.backgroundColor = UIColor.black
        modalWindowBg.alpha = 0
        
        // Добавляем модальное окно
        modalWindow = UIView(frame: CGRect(x: self.view!.frame.maxX, y: self.view!.bounds.midY - 200 / 2, width: 200, height: 200))

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
        
        let modalWindowTitleView = UIView(frame: CGRect(x: 0, y: -10 - modalWindow.frame.height / 4, width: modalWindow.frame.width, height: modalWindow.frame.height / 4))
        modalWindowTitleView.backgroundColor = UIColor.init(red: 0, green: 109 / 255, blue: 240 / 255, alpha: 1)
        modalWindowTitleView.layer.cornerRadius = 15
        modalWindowTitleView.layer.shadowColor = UIColor.black.cgColor
        modalWindowTitleView.layer.shadowOffset = CGSize.zero
        modalWindowTitleView.layer.shadowOpacity = 0.35
        modalWindowTitleView.layer.shadowRadius = 10
        modalWindow.addSubview(modalWindowTitleView)
        
        let modalWindowTitleLabel = UILabel(frame: CGRect(x: 0, y: 0, width: modalWindowTitleView.frame.width, height: modalWindowTitleView.frame.height))
        modalWindowTitleLabel.text = "Level \(Model.sharedInstance.currentLevel)"
        modalWindowTitleLabel.textAlignment = NSTextAlignment.center
        modalWindowTitleLabel.font = UIFont(name: "AvenirNext-DemiBold", size: 24)
        modalWindowTitleLabel.textColor = UIColor.white
        modalWindowTitleView.addSubview(modalWindowTitleLabel)
        
        /// Название выбранного уровня (для выйгрышного модального окна)
        let endingSentence = ["Awesome", "Well done", "Nice", "Great job", "Cool", "Good job", "Perfect", "Amazing"]
        
        // Кнопка "настройки" в модальном окне
        let goToSettingsBtn = UIButton(frame: CGRect(x: modalWindow.bounds.midX - ((modalWindow.frame.width - 40) / 2), y: modalWindow.frame.size.height - 50 - 15, width: modalWindow.frame.width - 40, height: 50))
        goToSettingsBtn.layer.cornerRadius = 10
        goToSettingsBtn.backgroundColor = UIColor.init(red: 165 / 255, green: 240 / 255, blue: 16 / 255, alpha: 1)
        goToSettingsBtn.setTitleColor(UIColor.black, for: UIControlState.normal)
        goToSettingsBtn.titleLabel?.font = UIFont(name: "AvenirNext-Medium", size: 19)
        goToSettingsBtn.setTitle("SETTINGS", for: UIControlState.normal)
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
        if type == modalWindowType.win {
            startBtn.setTitle("CONTINUE", for: UIControlState.normal)
            startBtn.addTarget(self, action: #selector(nextLevel), for: .touchUpInside)
            
            goToSettingsBtn.addTarget(self, action: #selector(goToSettings), for: .touchUpInside)
            
            sentenceLabel.text = endingSentence[Int(arc4random_uniform(UInt32(endingSentence.count)))]
        }
        else {
            goToSettingsBtn.setTitle("LEVELS", for: UIControlState.normal)
            goToSettingsBtn.addTarget(self, action: #selector(goToLevels), for: .touchUpInside)
            
            if type == modalWindowType.lose {
                startBtn.setTitle("RESTART", for: UIControlState.normal)
                startBtn.addTarget(self, action: #selector(restartLevelObjc), for: .touchUpInside)
                
                sentenceLabel.text = "You lose"
            }
            else {
                startBtn.setTitle("EXTRA LIFE", for: UIControlState.normal)
                startBtn.addTarget(self, action: #selector(addExtraLife), for: .touchUpInside)
                
                sentenceLabel.text = "No lives"
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
    }
    
    @objc func nextLevel(_ sender: UIButton) {
        SKTAudio.sharedInstance().playSoundEffect(filename: "Click_ModalWindow.wav")
        
        Model.sharedInstance.gameViewControllerConnect.goToLevels(moveCharacterFlag: true)
    }
    
    @objc func restartLevelObjc(_ sender: UIButton) {
        SKTAudio.sharedInstance().playSoundEffect(filename: "Click_ModalWindow.wav")
        
        restartingLevel()
    }
    
    func restartingLevel() {
        self.isPaused = false
        
        for object in movingObjects {
            object.run(SKAction.move(to: pointFor(column: object.moves!.first!.column, row: object.moves!.first!.row), duration: 0.215))
        }
        
        character.run(SKAction.move(to: pointFor(column: characterStart.column, row: characterStart.row), duration: 0.215))
        
        UIView.animate(withDuration: 0.215, animations: {
            self.modalWindowBg.alpha = 0
            self.modalWindow.frame.origin.x = self.view!.frame.maxX
        }) { (_) in
            self.modalWindow.removeFromSuperview()
            self.modalWindowBg.removeFromSuperview()
            
            self.restartLevel()
        }
    }
    
    @objc func addExtraLife(_ sender: UIButton) {
        SKTAudio.sharedInstance().playSoundEffect(filename: "Click_ModalWindow.wav")
        
        // Если больше 10 драг. камней
        if Model.sharedInstance.getCountGems() >= EXTRA_LIFE_PRICE {
            let alert = UIAlertController(title: "Buying an extra life", message: "An extra life is worth \(EXTRA_LIFE_PRICE) GEMS (you have \(Model.sharedInstance.getCountGems()) GEMS)", preferredStyle: UIAlertControllerStyle.alert)
            
            let actionCancel = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil)
            let actionOk = UIAlertAction(title: "Buy one life", style: UIAlertActionStyle.default, handler: {_ in
                Model.sharedInstance.setCountGems(amountGems: -EXTRA_LIFE_PRICE)
                
                Model.sharedInstance.setLevelLives(level: Model.sharedInstance.currentLevel, newValue: Model.sharedInstance.getLevelLives(Model.sharedInstance.currentLevel) + 1)
                
                self.restartingLevel()
            })
            
            alert.addAction(actionOk)
            alert.addAction(actionCancel)
            
            Model.sharedInstance.gameViewControllerConnect.present(alert, animated: true, completion: nil)
        }
        else {
            let alert = UIAlertController(title: "Not enough GEMS", message: "You do not have enough GEMS to buy an extra life. You need \(EXTRA_LIFE_PRICE) GEMS, but you have only \(Model.sharedInstance.getCountGems()) GEMS", preferredStyle: UIAlertControllerStyle.alert)
            
            let actionCancel = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil)
            let actionOk = UIAlertAction(title: "Buy GEMS", style: UIAlertActionStyle.default, handler: {_ in
                Model.sharedInstance.gameViewControllerConnect.presentMenu(dismiss: true)
            })
            
            alert.addAction(actionOk)
            alert.addAction(actionCancel)
            
            Model.sharedInstance.gameViewControllerConnect.present(alert, animated: true, completion: nil)
        }
    }
    
    @objc func goToLevels(_ sender: UIButton) {
        SKTAudio.sharedInstance().playSoundEffect(filename: "Click_ModalWindow.wav")
        
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
        
        rootLayer.bounds = CGRect(x: 0 + self.view!.bounds.width / 4 / 2, y: 0 + self.view!.bounds.height / 2, width: self.view!.bounds.width - self.view!.bounds.width / 4, height: self.view!.bounds.height / 2)
        
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
