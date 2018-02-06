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
            self.view!.insertSubview(modalWindow, belowSubview: mainBgTutorial)
        }
        else {
            self.view!.addSubview(modalWindowBg)
            self.view!.addSubview(modalWindow)
        }
        
        UIView.animate(withDuration: 0.215, animations: {
            self.modalWindowBg.alpha = 0.5
            
            self.modalWindow.frame.origin.x = self.view!.bounds.midX - self.modalWindow.frame.size.width / 2
        })
        
        /// Название выбранного уровня (для выйгрышного модального окна)
        let endingSentence = ["Awesome", "Well Done", "Nice", "Great Job", "Cool", "Good Job", "Perfect", "Amazing"]
        
        // Кнопка "настройки" в модальном окне
        let goToSettingsBtn = UIButton(frame: CGRect(x: modalWindow.bounds.midX - ((modalWindow.frame.width - 40) / 2), y: modalWindow.frame.size.height - 50 - 15, width: modalWindow.frame.width - 40, height: 50))
        goToSettingsBtn.layer.cornerRadius = 10
        goToSettingsBtn.backgroundColor = UIColor.green
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
        startBtn.backgroundColor = UIColor.red
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
        
        countGemsModalWindowLabel = UILabel(frame: CGRect(x: countOfGemsImage.frame.width / 2 - 35 / 2, y: 10, width: 35, height: 50))
        countGemsModalWindowLabel.font = UIFont(name: "AvenirNext-Bold", size: 14)
        countGemsModalWindowLabel.text = "X\(Model.sharedInstance.getCountGems())"
        countGemsModalWindowLabel.textAlignment = NSTextAlignment.center
        countGemsModalWindowLabel.textColor = UIColor.white
        countOfGemsImage.addSubview(countGemsModalWindowLabel)
        
        modalWindow.backgroundColor = UIColor.blue
        modalWindow.layer.cornerRadius = 15
        modalWindow.layer.shadowColor = UIColor.black.cgColor
        modalWindow.layer.shadowOffset = CGSize.zero
        modalWindow.layer.shadowOpacity = 0.35
        modalWindow.layer.shadowRadius = 10
    }
    
    @objc func nextLevel(_ sender: UIButton) {
        Model.sharedInstance.gameViewControllerConnect.goToLevels(moveCharacterFlag: true)
    }
    
    @objc func restartLevelObjc(_ sender: UIButton) {
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
                Model.sharedInstance.gameViewControllerConnect.presentMenu()
            })
            
            alert.addAction(actionOk)
            alert.addAction(actionCancel)
            
            Model.sharedInstance.gameViewControllerConnect.present(alert, animated: true, completion: nil)
        }
    }
    
    @objc func goToLevels(_ sender: UIButton) {
        Model.sharedInstance.gameViewControllerConnect.goToLevels()
    }
    
    @objc func goToSettings(_ sender: UIButton) {
        Model.sharedInstance.gameViewControllerConnect.presentMenu()
    }
}
