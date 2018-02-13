import UIKit
import SpriteKit

class ChooseLevelViewController: UIViewController {
    @IBOutlet weak var scrollView: UIScrollView!
    
    /// Размеры поля, на котором располагается меню
    var boardSize = Point(column: 5, row: 5)
    
    /// Размер ячейки поля
    var levelTileSize = CGSize(width: 50, height: 50)
    
    /// UIView, на которую крепятся все ячейки поля
    var tilesLayer: UIView!
    
    /// Расстояние по вертикали между ячейками уровней
    var distanceBetweenLevels = 3
    
    /// Доп. переменная, которая служит для фиксов различных случаем (на начальных и последних уровнях)
    var extraCountForExtremeLevels = 0
    
    /// Начальная точка главного персонажа
    var characterPointStart: Point!
    
    /// UIImageView ГП
    var character: UIImageView!
    
    /// Текстуры анимации ГП
    var walkFrames: [UIImage]!
    
    /// Координаты всех кнопок увроней
    var levelButtonsPositions = [Point]()
    
    /// Флаг, который определяет автоматическое перемещение персонажа при открытии меню
    var moveCharacterToNextLevel = false

    /// БГ модального окна
    var modalWindowBg: UIView!
    
    /// Модальное окно
    var modalWindow: UIView!
    
    /// Количество уровней, которое необходимо завершить для каждой секции для 1 секции -> 11, для второй -> 23
    var sections = [11, 23, 39]
    
    /// Количество уровней между секциями
    var distanceBetweenSections = 15
    
    /// Заблокирована ли следующая секция (если не пройдено необходимо кол-во уровней за предыдущую секцию)
    var isNextSectionDisabled = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        menuSettings()
        
        characterInitial()
        
        // Если самое начало игры, то делаем анимацию перехода на 1-ый уровень
        if Model.sharedInstance.getCountCompletedLevels() == 0 {
            moveToPoint(from: Point(column: levelButtonsPositions[Model.sharedInstance.currentLevel - 1].column, row: levelButtonsPositions[Model.sharedInstance.currentLevel - 1].row - distanceBetweenLevels), to: levelButtonsPositions[Model.sharedInstance.currentLevel - 1], delay: 0.5)
        }
        else {
            if !isNextSectionDisabled {
                if Model.sharedInstance.currentLevel - 1 < Model.sharedInstance.countLevels {
                    // Если перешли в меню после прохождения уровня, то запускаем анимацию перехода на след. уровень
                    if moveCharacterToNextLevel {
                        // Если последний пройденный уровень больше, чем последний максимальный
                        if Model.sharedInstance.currentLevel > Model.sharedInstance.getCountCompletedLevels() {
                            var levelFrom = Model.sharedInstance.getCountCompletedLevels() - 1
                            if Model.sharedInstance.currentLevel > 2 {
                                if !Model.sharedInstance.isCompletedLevel(levelFrom) {
                                    levelFrom -= 1
                                }
                            }
                            
                            moveToPoint(from: levelButtonsPositions[levelFrom], to: levelButtonsPositions[Model.sharedInstance.getCountCompletedLevels()], delay: 0.5)
                        }
                    }
                }
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        
        // Если обучение было "прервано" после 1-ого уровня
        if !moveCharacterToNextLevel && Model.sharedInstance.currentLevel == 2 && Model.sharedInstance.getCountCompletedLevels() == 1 && !Model.sharedInstance.isCompletedLevel(2) {
            modalWindowPresent()
        }
    }
    
    func characterInitial() {
        /// Задаём анимацию для ГП
        let playerAnimatedAtlas = SKTextureAtlas(named: "PlayerWalks")
        walkFrames = [UIImage]()
        let numImages = playerAnimatedAtlas.textureNames.count
        for i in 1...numImages {
            let playerTextureName = "PlayerWalks_\(i)"
            walkFrames.append(UIImage(cgImage: playerAnimatedAtlas.textureNamed(playerTextureName).cgImage()))
        }
        
        let pointCharacter = pointFor(column: characterPointStart.column, row: characterPointStart.row - (Model.sharedInstance.getCountCompletedLevels() == 0 ? distanceBetweenLevels : 0))
        let textureCharacter = playerAnimatedAtlas.textureNamed("PlayerWalks_2").cgImage()
        let sizeCharacter = CGSize(width: levelTileSize.width * 0.5, height: CGFloat(textureCharacter.height) / (CGFloat(textureCharacter.width) / (levelTileSize.width * 0.5)))
        
        character = UIImageView(frame: CGRect(x: pointCharacter.x - sizeCharacter.width / 2, y: pointCharacter.y - sizeCharacter.height / 2, width: sizeCharacter.width, height: sizeCharacter.height))
        character.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi))
        character.image = UIImage(cgImage: playerAnimatedAtlas.textureNamed("PlayerWalks_2").cgImage())
        
        scrollView.addSubview(character)
    }
    
    func menuSettings() {
         // Если нахожимся на последних уровнях, то подфиксиваем так, чтобы последний уровень фиксировался по центру и не уходил дальше
        if Model.sharedInstance.countLevels - (Model.sharedInstance.getCountCompletedLevels()) < distanceBetweenLevels {
            extraCountForExtremeLevels = Model.sharedInstance.countLevels - Model.sharedInstance.getCountCompletedLevels() - distanceBetweenLevels + 1
        }
        
        boardSize.row = (Model.sharedInstance.getCountCompletedLevels() + distanceBetweenLevels + extraCountForExtremeLevels) * distanceBetweenLevels
        
        levelTileSize.width = self.view.bounds.width / CGFloat(boardSize.column)
        levelTileSize.height = levelTileSize.width
        
        tilesLayer = UIView(frame: CGRect(x: -levelTileSize.width * CGFloat(boardSize.column) / 2, y: 0, width: self.view.bounds.width, height: CGFloat(boardSize.row) * levelTileSize.height))
        
        scrollView.addSubview(tilesLayer)
        addTiles()

        if !isNextSectionDisabled {
            if Model.sharedInstance.currentLevel <= Model.sharedInstance.getCountCompletedLevels() {
                var lastLevelKoef = 0
                if Model.sharedInstance.getCountCompletedLevels() >= levelButtonsPositions.count {
                    lastLevelKoef = 1
                }
                
                characterPointStart = levelButtonsPositions[Model.sharedInstance.getCountCompletedLevels() - lastLevelKoef]
            }
            else {
                if Model.sharedInstance.currentLevel > Model.sharedInstance.countLevels {
                    characterPointStart = levelButtonsPositions.last!
                }
                else {
                    var levelFrom = Model.sharedInstance.getCountCompletedLevels() - 1
                    if Model.sharedInstance.currentLevel > 2 {
                        if moveCharacterToNextLevel {
                            if !Model.sharedInstance.isCompletedLevel(levelFrom) {
                                levelFrom -= 1
                            }
                            
                            characterPointStart = levelButtonsPositions[levelFrom]
                        }
                    }
                }
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        // Почему-то было сложно сделать scroll снизу вверх, то просто перевернул на 180 слой, а потом все кнопки тоже на 180
        scrollView.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi))
        
        let koefisNextSectionDisabled = isNextSectionDisabled ? 1 : 0
        
        scrollView.contentSize = CGSize(width: self.view.bounds.width, height: CGFloat((Model.sharedInstance.getCountCompletedLevels() + distanceBetweenLevels + extraCountForExtremeLevels - koefisNextSectionDisabled) * distanceBetweenLevels) * levelTileSize.height)
        
        scrollView.contentOffset.y = CGFloat((Model.sharedInstance.getCountCompletedLevels() - 1) * distanceBetweenLevels) * levelTileSize.height
        
        scrollView.contentInset = UIEdgeInsets.zero
        scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentBehavior.never
        scrollView.scrollIndicatorInsets = UIEdgeInsets.zero
        
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = false
        
        if Model.sharedInstance.lastYpositionLevels != nil {
            scrollView.contentOffset.y = Model.sharedInstance.lastYpositionLevels!
        }
    }
    
    @objc func buttonAction(sender: UIButton!) {
        let buttonSenderAction: UIButton = sender
        
        SKTAudio.sharedInstance().playSoundEffect(filename: "Swish.wav")
        
        // Если уровень не заблокирован
        if buttonSenderAction.tag != -1 {
            Model.sharedInstance.currentLevel = buttonSenderAction.tag
            moveCharacterToNextLevel = false

            self.modalWindowPresent()
        }
    }
    
    /// Функция, которая вызывает анимацию следования ГП по кривой Безье
    func moveToPoint(from: Point, to: Point, delay: CFTimeInterval = 0) {
        // Если конечная позиция не совпадает с начальной
        if from != to {
            // Второе -1, т.к. массив кнопок уровней начинается с 0
            let path = pathToPoint(from: from, to: to)
            
            // Если предыдущая анимация ещё не закончилась
            if character.layer.animation(forKey: "movement") == nil {
                let movement = CAKeyframeAnimation(keyPath: "position")
                scrollView.isScrollEnabled = false
                
                // Анимации ходьбы ГП
                character.animationImages = walkFrames
                character.animationRepeatCount = 0
                character.animationDuration = TimeInterval(0.05 * Double(walkFrames.count))
                character.startAnimating()
                
                CATransaction.begin()
                
                // Пока ГП перемещается, то блокируем клики
                scrollView.isUserInteractionEnabled = false
                
                if to.row != 1 {
                    DispatchQueue.main.async {
                        
                        /// Время, через которое анимации начнёт воспроизводиться
                        var delayForAnimation: CFTimeInterval = 0
                        if self.moveCharacterToNextLevel {
                            delayForAnimation = delay
                        }
                        
                        UIView.animate(withDuration: 0.25 * Double(path.count), delay: delayForAnimation, options: UIViewAnimationOptions.curveLinear, animations: {
                            self.scrollView.contentOffset.y = CGFloat((Model.sharedInstance.currentLevel - 2) * self.distanceBetweenLevels) * self.levelTileSize.height
                        })
                    }
                }
                
                CATransaction.setCompletionBlock({
                    self.character.layer.position = self.pointFor(column: to.column, row: to.row)
                    self.character.layer.removeAnimation(forKey: "movement")
                    self.character.stopAnimating()
                    self.scrollView.isScrollEnabled = true
                    
                    self.modalWindowPresent()
                    self.characterPointStart = to
                    
                    self.scrollView.isUserInteractionEnabled = true
                })
                
                movement.beginTime = CACurrentMediaTime() + delay
                movement.path = path.bezier.cgPath
                movement.fillMode = kCAFillModeForwards
                movement.isRemovedOnCompletion = false
                movement.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
                movement.duration = 0.25 * Double(path.count)
//                movement.rotationMode = kCAAnimationRotateAuto
                
                character.layer.add(movement, forKey: "movement")
                CATransaction.commit()
            }
        }
        else {
            self.modalWindowPresent()
            self.characterPointStart = to
        }
    }
    
    /// Функция показывает модальное окно с информацией об уровне
    func modalWindowPresent() {
        // Добавляем бг, чтобы при клике на него закрыть всё модальное окно
        modalWindowBg = UIView(frame: scrollView.bounds)
        modalWindowBg.backgroundColor = UIColor.black
        modalWindowBg.restorationIdentifier = "modalWindowBg"
        modalWindowBg.alpha = 0
        
        // Если уровни без начального обучения, то можно скрыть окно с выбором уровня
        if (Model.sharedInstance.currentLevel != 1 && Model.sharedInstance.currentLevel != 2) || Model.sharedInstance.getCountCompletedLevels() > 1 {
            modalWindowBg.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.bgClick(_:))))
        }
        modalWindowBg.isUserInteractionEnabled = true
        
        scrollView.addSubview(modalWindowBg)
        scrollView.isScrollEnabled = false
        
        // Добавляем модальное окно
        modalWindow = UIView(frame: CGRect(x: scrollView.bounds.minX - 200, y: scrollView.bounds.midY - 200 / 2, width: 200, height: 200))
        modalWindow.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi))
        
        modalWindow.backgroundColor = UIColor.init(red: 0, green: 109 / 255, blue: 240 / 255, alpha: 1)
        modalWindow.layer.cornerRadius = 15
        modalWindow.layer.shadowColor = UIColor.black.cgColor
        modalWindow.layer.shadowOffset = CGSize.zero
        modalWindow.layer.shadowOpacity = 0.35
        modalWindow.layer.shadowRadius = 10
        
        scrollView.addSubview(modalWindow)
        
        UIView.animate(withDuration: 0.215, animations: {
            self.modalWindowBg.alpha = 0.5
            self.modalWindow.frame.origin.x = self.scrollView.bounds.midX - self.modalWindow.frame.width / 2
        })
        
        // Если уровни без начального обучения, то можно скрыть окно с выбором уровня
        if (Model.sharedInstance.currentLevel != 1 && Model.sharedInstance.currentLevel != 2) || Model.sharedInstance.getCountCompletedLevels() > 1 {
            modalWindow.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.bgClick(_:))))
        }
        
        /// Название выбранного уровня
        let levelNumberLabel = UILabel(frame: CGRect(x: 20, y: 25, width: modalWindow.frame.size.width - 40, height: 35))
        levelNumberLabel.text = "Level \(Model.sharedInstance.currentLevel)"
        levelNumberLabel.textAlignment = NSTextAlignment.left
        levelNumberLabel.font = UIFont(name: "AvenirNext-DemiBold", size: 24)
        levelNumberLabel.textColor = UIColor.white
        modalWindow.addSubview(levelNumberLabel)
        
        // Кнопка "старт" в модальном окне, которая переносит на выбранный уровень
        let btnStart = UIButton(frame: CGRect(x: modalWindow.bounds.midX - ((modalWindow.frame.width - 40) / 2), y: modalWindow.bounds.midY - 50 / 2, width: modalWindow.frame.width - 40, height: 50))
        btnStart.layer.cornerRadius = 10
        btnStart.backgroundColor = UIColor.init(red: 217 / 255, green: 29 / 255, blue: 29 / 255, alpha: 1)
        btnStart.titleLabel?.font = UIFont(name: "AvenirNext-Medium", size: 19)
        btnStart.addTarget(self, action: #selector(startLevel), for: .touchUpInside)
        btnStart.setTitle("START", for: UIControlState.normal)
        modalWindow.addSubview(btnStart)
        
        if !Model.sharedInstance.isCompletedLevel(Model.sharedInstance.currentLevel) {
            let countOfGemsImage = UIImageView(image: UIImage(named: "Heart"))
            countOfGemsImage.frame.size = CGSize(width: countOfGemsImage.frame.size.width * 0.75, height: countOfGemsImage.frame.size.height * 0.75)
            countOfGemsImage.frame.origin = CGPoint(x: modalWindow.frame.size.width - 35 - 20, y: 22)
            modalWindow.addSubview(countOfGemsImage)
        
            let countGemsModalWindowLabel = UILabel(frame: CGRect(x: countOfGemsImage.frame.width / 2 - 75 / 2, y: countOfGemsImage.frame.height / 2 - 50 / 2, width: 75, height: 50))
            countGemsModalWindowLabel.font = UIFont(name: "AvenirNext-Bold", size: 18)
            countGemsModalWindowLabel.text = String(Model.sharedInstance.getLevelLives(Model.sharedInstance.currentLevel))
            countGemsModalWindowLabel.textAlignment = NSTextAlignment.center
            countGemsModalWindowLabel.textColor = UIColor.white
            countOfGemsImage.addSubview(countGemsModalWindowLabel)
        }
        else {
            let completedLevelLabel = UIImageView(image: UIImage(named: "Checked"))
            completedLevelLabel.frame.size = CGSize(width: 32, height: 32)
            completedLevelLabel.frame.origin = CGPoint(x: modalWindow.frame.size.width - 45, y: 22)
            modalWindow.addSubview(completedLevelLabel)
        }
        
        // Кнопка "дополнительная жизнь" или "настройки" в модальном окне в зависимости от кол-ва жизней
        let secondButton = UIButton(frame: CGRect(x: modalWindow.bounds.midX - ((modalWindow.frame.width - 40) / 2), y: modalWindow.frame.size.height - 50 - 15, width: modalWindow.frame.width - 40, height: 50))
        secondButton.layer.cornerRadius = 10
        secondButton.backgroundColor = UIColor.init(red: 165 / 255, green: 240 / 255, blue: 16 / 255, alpha: 1)
        secondButton.titleLabel?.font = UIFont(name: "AvenirNext-Medium", size: 19)
        secondButton.setTitleColor(UIColor.black, for: UIControlState.normal)
        modalWindow.addSubview(secondButton)
        
        // Если количество жизенй на уровне меньше 0, то добавляем кнопку получения новой жизни
        if Model.sharedInstance.getLevelLives(Model.sharedInstance.currentLevel) <= 0 {
            btnStart.backgroundColor = UIColor.init(red: 187 / 255, green: 36 / 255, blue: 36 / 255, alpha: 0.9)
            btnStart.removeTarget(self, action: nil, for: .allEvents)
            btnStart.addTarget(self, action: #selector(shakeBtnStart), for: .touchUpInside)
            
            secondButton.setTitle("EXTRA LIFE", for: UIControlState.normal)
            secondButton.addTarget(self, action: #selector(addExtraLife), for: .touchUpInside)
        }
        else {
            secondButton.setTitle("SETTINGS", for: UIControlState.normal)
            secondButton.addTarget(self, action: #selector(goToMenuFromModalWindow), for: .touchUpInside)
        }
        
//        drawHearts(Model.sharedInstance.currentLevel)
    }
    
    @objc func startLevel() {
        SKTAudio.sharedInstance().playSoundEffect(filename: "Click_ModalWindow.wav")
        
        Model.sharedInstance.lastYpositionLevels = scrollView.contentOffset.y
        
        self.goToLevel()
    }
    
    @objc func bgClick(_ sender: UITapGestureRecognizer) {
        if sender.view?.restorationIdentifier == "modalWindowBg" {
            SKTAudio.sharedInstance().playSoundEffect(filename: "Swish.wav")
            
            UIView.animate(withDuration: 0.215, animations: {
                self.modalWindow.frame.origin.x = self.view.bounds.minX - self.modalWindow.frame.size.width
                self.modalWindowBg.alpha = 0
            }, completion: { (_) in
                self.modalWindowBg.removeFromSuperview()
                self.modalWindow.removeFromSuperview()
                self.scrollView.isScrollEnabled = true
            })
        }
    }
    
    @objc func shakeBtnStart(_ button: UIButton) {
        shakeView(button)
    }
    
    @objc func shakeScreen() {
        shakeView(self.view)
        
        SKTAudio.sharedInstance().playSoundEffect(filename: "Disable.wav")
    }
    
    @objc func goToMenuFromModalWindow(sender: UIButton) {
        SKTAudio.sharedInstance().playSoundEffect(filename: "Click_ModalWindow.wav")
        
        presentMenu(dismiss: true)
    }
    
    func buyExtraLife() {
        // Отнимаем 10 драг. камней
        Model.sharedInstance.setCountGems(amountGems: -EXTRA_LIFE_PRICE)
        
        Model.sharedInstance.setLevelLives(level: Model.sharedInstance.currentLevel, newValue: Model.sharedInstance.getLevelLives(Model.sharedInstance.currentLevel) + 1)
        UIView.animate(withDuration: 0.215, animations: {
            self.modalWindow.frame.origin.x = self.view.bounds.minX - self.modalWindow.frame.size.width
        }, completion: { (_) in
            self.modalWindowBg.removeFromSuperview()
            
            // Ищем кнопку-уровень на scrollView
            var tileLevelSubView: UIView!
            for tileSubview in self.scrollView.subviews {
                if tileSubview.restorationIdentifier == "levelTile_\(Model.sharedInstance.currentLevel)" {
                    tileLevelSubView = tileSubview
                }
            }
            // Ищем view, который выводит состояние уровня
            for subview in tileLevelSubView.subviews {
                if subview.restorationIdentifier == "levelStateImage" {
                    subview.removeFromSuperview()
                }
            }
            
            self.modalWindowPresent()
        })
    }
    
    @objc func addExtraLife(_ sender: UIButton) {
        SKTAudio.sharedInstance().playSoundEffect(filename: "Click_ModalWindow.wav")
        
        // Если больше 10 драг. камней, то добавляем новую жизнь
        if Model.sharedInstance.getCountGems() >= EXTRA_LIFE_PRICE {
            
            let alert = UIAlertController(title: "Buying an extra life", message: "An extra life is worth \(EXTRA_LIFE_PRICE) GEMS (you have \(Model.sharedInstance.getCountGems()) GEMS)", preferredStyle: UIAlertControllerStyle.alert)
            
            let actionCancel = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil)
            let actionOk = UIAlertAction(title: "Buy one life", style: UIAlertActionStyle.default, handler: {_ in
                self.buyExtraLife()
            })
            
            alert.addAction(actionOk)
            alert.addAction(actionCancel)
            
            self.present(alert, animated: true, completion: nil)
        }
        else {
            let alert = UIAlertController(title: "Not enough GEMS", message: "You do not have enough GEMS to buy an extra life. You need \(EXTRA_LIFE_PRICE) GEMS, but you have only \(Model.sharedInstance.getCountGems()) GEMS", preferredStyle: UIAlertControllerStyle.alert)
            
            let actionCancel = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil)
            let actionOk = UIAlertAction(title: "Buy GEMS", style: UIAlertActionStyle.default, handler: {_ in
                self.presentMenu(dismiss: true)
            })
            
            alert.addAction(actionOk)
            alert.addAction(actionCancel)
            
            self.present(alert, animated: true, completion: nil)
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
    
    /// Функция, отрисовывающая количество оставшихся жизней на уровне
    func drawHearts(_ forLevel: Int) {
        if !Model.sharedInstance.isCompletedLevel(forLevel) {
            let livesOnLevel = Model.sharedInstance.getLevelLives(forLevel)
            let allLivesPerLevel = 5
            
            if livesOnLevel > 0 {
                var heartTexture = SKTexture(imageNamed: "Heart")
                let heartSize = CGSize(width: heartTexture.size().width / 1.5, height: heartTexture.size().height / 1.5)
                
                let heartsStackView = UIView(frame: CGRect(x: Int(modalWindow.bounds.midX - ((modalWindow.frame.width - 40) / 2)), y: Int(modalWindow.frame.size.height - heartSize.height - 15), width: Int(modalWindow.frame.size.width), height: Int(heartSize.height)))
                
                for index in 0...allLivesPerLevel - 1 {
                    heartTexture = allLivesPerLevel - 1 - index < livesOnLevel ? SKTexture(imageNamed: "Heart") : SKTexture(imageNamed: "Heart_empty")
                    
                    let button = UIButton(frame: CGRect(x: 3 / 2 + (modalWindow.frame.size.width - (CGFloat((heartSize.width + 3) * CGFloat(allLivesPerLevel)))) / 2 + CGFloat((heartSize.width + 3) * CGFloat(index)), y: 0, width: heartSize.width, height: heartSize.height))
                    button.setBackgroundImage(UIImage(cgImage: heartTexture.cgImage()), for: UIControlState.normal)
                    button.isUserInteractionEnabled = false
                    button.tag = index + 1
                    
                    heartsStackView.addSubview(button)
                }
                modalWindow.addSubview(heartsStackView)
            }
        }
        else {
            let completedLabel = UILabel(frame: CGRect(x: modalWindow.bounds.midX - modalWindow.frame.size.width / 2, y: modalWindow.frame.size.height - 35 - 15, width: modalWindow.frame.size.width, height: 35))
            completedLabel.text = "Completed"
            completedLabel.textAlignment = NSTextAlignment.center
            completedLabel.font = UIFont(name: "Avenir Next", size: 24)
            completedLabel.textColor = UIColor.white
            modalWindow.addSubview(completedLabel)
        }
    }
    
    func goToLevel() {
        if Model.sharedInstance.getLevelLives(Model.sharedInstance.currentLevel) > 0 {
            if Model.sharedInstance.gameScene != nil {
                Model.sharedInstance.gameScene.cleanLevel()
            }
            
            if let storyboard = storyboard {
                let gameViewController = storyboard.instantiateViewController(withIdentifier: "GameViewController") as! GameViewController
                navigationController?.pushViewController(gameViewController, animated: true)
            }
        }
    }
    
    /// Функция, которая возвращает близжайший путь между точками
    func pathToPoint(from: Point, to: Point) -> (bezier: UIBezierPath, count: Int) {
        let path = UIBezierPath()
        var count = 0
        
        path.move(to: pointFor(column: from.column, row: from.row))
        
        var direction = 1
        if to.column <= from.column {
            direction = -1
        }
        
        var col = from.column
        var row = from.row
        
        while col != to.column {
            col += direction
            path.addLine(to: pointFor(column: col, row: row))
            count += 1
        }
        
        direction = 1
        if to.row <= from.row {
            direction = -1
        }
        
        while row != to.row {
            row += direction
            path.addLine(to: pointFor(column: col, row: row))
            count += 1
        }
        
        return (bezier: path, count: count)
    }
    
    func addLevelImageState(spriteName: String = "Locked", buttonToPin: UIButton, sizeKoef: CGSize = CGSize(width: 0.275, height: 0.275)) {
        let levelStateImage = UIImageView(image: UIImage(named: spriteName))
        levelStateImage.frame.size = CGSize(width: buttonToPin.frame.size.width * sizeKoef.width, height: buttonToPin.frame.size.height * sizeKoef.height)
        levelStateImage.restorationIdentifier = "levelStateImage"
        levelStateImage.frame.origin = CGPoint(x: buttonToPin.frame.size.width - levelStateImage.frame.size.width - 5, y: buttonToPin.frame.size.height - levelStateImage.frame.size.height - 5)
        buttonToPin.addSubview(levelStateImage)
    }

    /// Функция получает значение кол-ва уровней, которые должны быть завершены. чтобы получить доступ к следующей секции
    func getCountCompleteLevelsForNextSection(_ level: Int) -> Int {
        return sections[level / distanceBetweenSections - 1]
    }
    
    /// Функция, считает количество пройденных уровней в интервале [0; maxLevel]
    func countCompletedLevelsForPreviousSection(_ maxLevel: Int) -> Int {
        var level = maxLevel
        
        var countOfCompletedLevels = 0
        
        while level > 0 {
            if Model.sharedInstance.isCompletedLevel(level) {
                countOfCompletedLevels += 1
            }
            
            level -= 1
        }
        
        return countOfCompletedLevels
    }
    
    func addTiles() {
        /// Флаг, который запоминает последнюю строку, на которой была вставлена кнопка уровня
        var lastRowWhereBtnAdded = Int.min
        
        /// Нужно ли заблокировать все уровни, если текущая секция не пройдена
        var isLevelsAfterSectionDisabled = false
        
        // -5 и 5 для того, чтобы при "bounce" были сверху и снизу ячейки
        for row in -10..<boardSize.row + 10 {
            for column in 0..<boardSize.column {
                var tileSprite: String = "center"
                var rotation: Double = 0.0
                
                if column == 0 {
                    tileSprite = "top"
                    rotation = (-90 * Double.pi / 180)
                }

                if column == boardSize.column - 1 {
                    tileSprite = "top"
                    rotation = (90 * Double.pi / 180)
                }
                
                let pos = pointFor(column: column, row: row)
                
                let tileImage = UIImageView(frame: CGRect(x: pos.x + self.view.bounds.width / 2 - levelTileSize.width / 2, y: pos.y - levelTileSize.height / 2, width: levelTileSize.width, height: levelTileSize.height))
                tileImage.image = UIImage(named: "Tile_\(tileSprite)")
                tileImage.transform = CGAffineTransform(rotationAngle: CGFloat(rotation))
                tilesLayer.addSubview(tileImage)
                
                let randColumn = Int(arc4random_uniform(3)) + 1
                
                if (lastRowWhereBtnAdded != row) && (row >= 0 && row < boardSize.row + distanceBetweenLevels * distanceBetweenLevels) && ((row / distanceBetweenLevels + 1) <= Model.sharedInstance.countLevels) && (row % 3 == 0) {
                    
                    let buttonPos = pointFor(column: randColumn, row: row + 1)
                    
                    let button = UIButton(frame: CGRect(x: buttonPos.x - levelTileSize.width / 2, y: buttonPos.y - levelTileSize.height / 2, width: levelTileSize.width, height: levelTileSize.height))
                    
                    button.setBackgroundImage(UIImage(named: "Tile_center"), for: UIControlState.normal)
                    button.titleLabel?.font = UIFont(name: "Avenir Next", size: 24)
                    button.setTitle("\(row / distanceBetweenLevels + 1)", for: UIControlState.normal)
                    button.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
                    button.tag = row / distanceBetweenLevels + 1
                    button.adjustsImageWhenHighlighted = false
                    // Переворачиваем кнопку, т. к. перевернул весь слой
                    button.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi))
                    
                    var koefForLastLevel = 0
                    
                    if Model.sharedInstance.countLevels == Model.sharedInstance.getCountCompletedLevels() {
                        koefForLastLevel = 0
                    }
                    else {
                        if !moveCharacterToNextLevel {
                            koefForLastLevel = 1
                        }
                    }
                    
                    // Если уровень (который отображает кнопка) равен тому уровню, который был пройден последним, то запомнить координаты этой позиции, чтобы вывести туда персонажа
                    if row / distanceBetweenLevels + 1 == Model.sharedInstance.getCountCompletedLevels() + koefForLastLevel {
                        characterPointStart = Point(column: randColumn, row: row + 1)
                    }
                    
                    // Если уровень пройден, то добавляем соответствующую метку
                    if Model.sharedInstance.isCompletedLevel(row / distanceBetweenLevels + 1) {
                        addLevelImageState(spriteName: "Checked", buttonToPin: button)
                    }
                    
                    if (row > 0) && ((row / distanceBetweenLevels) % distanceBetweenSections == 0) && (row > Model.sharedInstance.getCountCompletedLevels()) {
                        /// Количество пройденных уровней [0; ближайшая граница секции]
                        let completedLevels = countCompletedLevelsForPreviousSection(row / distanceBetweenLevels)
                        
                        /// Кол-во уровней, которое разблокирует новую секцию
                        let needCompleteLevelsPreviousSection = getCountCompleteLevelsForNextSection(row / distanceBetweenLevels)
                        
                        if completedLevels < needCompleteLevelsPreviousSection {
                            isLevelsAfterSectionDisabled = true
                            
                            if Model.sharedInstance.getCountCompletedLevels() >= needCompleteLevelsPreviousSection {
                                isNextSectionDisabled = true
                                characterPointStart = levelButtonsPositions.last!
                            }
                            
                            let point = pointFor(column: 1, row: row - 2)
                            let viewCountLevelsToUnlock = UIView(frame: CGRect(x: point.x - levelTileSize.width, y: point.y + levelTileSize.height, width: levelTileSize.width * 4, height: levelTileSize.height))
                            viewCountLevelsToUnlock.backgroundColor = UIColor.init(red: 0, green: 109 / 255, blue: 240 / 255, alpha: 1)
                            viewCountLevelsToUnlock.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi))
                            
                            viewCountLevelsToUnlock.layer.cornerRadius = 15
                            viewCountLevelsToUnlock.layer.shadowColor = UIColor.black.cgColor
                            viewCountLevelsToUnlock.layer.shadowOffset = CGSize.zero
                            viewCountLevelsToUnlock.layer.shadowOpacity = 0.35
                            viewCountLevelsToUnlock.layer.shadowRadius = 10
                            scrollView.addSubview(viewCountLevelsToUnlock)
                            
                            let labelCountLevelsToUnlock = UILabel(frame: CGRect(x: 10, y: 0, width: viewCountLevelsToUnlock.frame.width - 20, height: viewCountLevelsToUnlock.frame.height))
                            labelCountLevelsToUnlock.text = "To unlock next section complete at least \(needCompleteLevelsPreviousSection - completedLevels) more levels"
                            labelCountLevelsToUnlock.textAlignment = NSTextAlignment.center
                            labelCountLevelsToUnlock.numberOfLines = 3
                            labelCountLevelsToUnlock.font = UIFont(name: "AvenirNext-Medium", size: 18)
                            labelCountLevelsToUnlock.textColor = UIColor.white
                            viewCountLevelsToUnlock.addSubview(labelCountLevelsToUnlock)
                        }
                    }
                    
                    if (row / distanceBetweenLevels) <= Model.sharedInstance.getCountCompletedLevels() + 1 && !isLevelsAfterSectionDisabled {
                        if Model.sharedInstance.emptySavedLevelsLives() == false {
                            // Если на уровне не осталось жизней, то добавляем соответствующую метку
                            if Model.sharedInstance.getLevelLives(row / distanceBetweenLevels + 1) <= 0 {
                                addLevelImageState(spriteName: "Heart_empty-unfilled", buttonToPin: button, sizeKoef: CGSize(width: 0.275, height: 0.25))
                            }
                        }
                    }
                    else {
                        button.tag = -1
                        button.addTarget(self, action: #selector(shakeScreen), for: .touchUpInside)
                        addLevelImageState(spriteName: "Locked", buttonToPin: button, sizeKoef: CGSize(width: 0.3, height: 0.3))
                    }
                    
                    
                    
                    button.restorationIdentifier = "levelTile_\(button.tag)"
                    
                    levelButtonsPositions.append(Point(column: randColumn, row: row + 1))
                    
                    scrollView.addSubview(button)
                    
                    lastRowWhereBtnAdded = row
                }
            }
        }
        
        if characterPointStart == nil {
            characterPointStart = levelButtonsPositions.first!
        }
    }
    
    /// Функция, которая ппереводим координаты игрового поля в физические
    func pointFor(column: Int, row: Int) -> CGPoint {
        return CGPoint(
            x: CGFloat(column) * levelTileSize.width + levelTileSize.width / 2,
            y: CGFloat(row) * levelTileSize.height + levelTileSize.height / 2)
    }
    
    /// Функция конвертирует CGPoint в позицию на игровом поле, если клик был сделан по игровому полю
    func convertPoint(point: CGPoint) -> (success: Bool, point: Point) {
        if point.x >= 0 && point.x < CGFloat(boardSize.column) * levelTileSize.width &&
            point.y >= 0 && point.y < CGFloat(boardSize.row) * levelTileSize.height {
            return (true, Point(column: Int(point.x / levelTileSize.width), row: Int(point.y / levelTileSize.height)))
        }
        else {
            return (false, Point(column: 0, row: 0))
        }
    }
    
    /// Переход в настройки
    @IBAction func goToMenu(sender: UIButton) {
        SKTAudio.sharedInstance().playSoundEffect(filename: "Click.wav")
        
        presentMenu(dismiss: true)
    }
    
    func presentMenu(dismiss: Bool = false) {
        if let storyboard = storyboard {
            let menuViewController = storyboard.instantiateViewController(withIdentifier: "MenuViewController") as! MenuViewController
            menuViewController.isDismissed = dismiss
            navigationController?.pushViewController(menuViewController, animated: true)
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
}
