import SpriteKit
import GoogleMobileAds
import Flurry_iOS_SDK

class ChooseLevelViewController: UIViewController, GADRewardBasedVideoAdDelegate {
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet var interfaceButtons: [UIButton]!
    @IBOutlet var controlsSizeConstraint: [NSLayoutConstraint]!
    @IBOutlet weak var bgView: UIView!
    @IBOutlet weak var sectionTitle: UILabel!
    @IBOutlet weak var topMenuView: UIView!
    
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
    
    /// Координаты всех кнопок уровней
    var levelButtonsPositions = [Point]()
    
    /// Флаг, который определяет автоматическое перемещение персонажа при открытии меню
    var moveCharacterToNextLevel = false

    /// БГ модального окна
    var modalWindowBg: UIView!
    
    /// Модальное окно
    var modalWindow: UIView!
    
    /// Количество уровней, которое необходимо завершить для каждой секции для 1 секции -> 11, для второй -> 25
    var sections = [11, 25, 40]
    
    /// Заблокирована ли следующая секция (если не пройдено необходимо кол-во уровней за предыдущую секцию)
    var isNextSectionDisabled = false
    
    /// true, если модальное окно открыто
    var isModalWindowOpen = false
    
    /// окно для таймера для получения бесплатной доп. жизни
    var viewExtraLifeForAd: UIView!
    
    /// Таймер для получения бесплатной жизни на уровне
    var timerToClaimFreeLife = Timer()
    
    /// Уровни, у которых по 0 жизней, и которые уже на Timer
    var levelsOnTimer = [Int]()
    
    var countGemsModalWindowLabel: UILabel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sectionTitle.text = NSLocalizedString("LEVELS", comment: "")
        
        for level in 1...Model.sharedInstance.countLevels {
            let timeToClaimFreeLife = TIME_TO_CLAIM_FREE_LIFE - (Model.sharedInstance.getLastDateClaimFreeLife(level)!.timeIntervalSinceNow * -1)
            if Model.sharedInstance.getLevelLives(level) < 1 {
                if timeToClaimFreeLife < 1 {
                    Model.sharedInstance.setLevelLives(level: level, newValue: Model.sharedInstance.getLevelLives(level) + 1)
                }
            }
        }
        
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
        
        for level in 1...Model.sharedInstance.countLevels {
            if Model.sharedInstance.getLevelLives(level) < 1 {
                labelToGetFreeLifeTime(buttonExtraLifeForAd: nil, customLevel: level)
            }
        }
        
        bgView.backgroundColor = UIColor.init(red: 149/255, green: 201/255, blue: 45/255, alpha: 0.1)
        
        // Если обучение было "прервано" после 1-ого уровня
        if !moveCharacterToNextLevel && Model.sharedInstance.currentLevel == 2 && Model.sharedInstance.getCountCompletedLevels() == 1 && !Model.sharedInstance.isCompletedLevel(2) {
            modalWindowPresent()
        }
        
        if Model.sharedInstance.getCountCompletedLevels() > 1 {
            if moveCharacterToNextLevel == false {
                if Model.sharedInstance.getLastTimeUserClaimFreeEveryDayGem() == nil {
                    Model.sharedInstance.setLastTimeUserClaimFreeEveryDayGem(Calendar.current.date(byAdding: Calendar.Component.hour, value: -10, to: Date())!)
                }
                
                let timeToClaimFreeGem = TIME_TO_CLAIM_FREE_GEM - (Model.sharedInstance.getLastTimeUserClaimFreeEveryDayGem()!.timeIntervalSinceNow * -1)
                
                if timeToClaimFreeGem <= 0 {
                    self.scrollView.isScrollEnabled = false
                    
                    for button in interfaceButtons {
                        button.isEnabled = false
                    }
                    
                    topMenuView.alpha = 0
                }
                
                Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { (_) in
                    if timeToClaimFreeGem <= 0 {
                        let bgForFreeGemView = UIView(frame: self.scrollView.bounds)
                        bgForFreeGemView.backgroundColor = UIColor.black.withAlphaComponent(0)
                        bgForFreeGemView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.clickOnBgGetFreeGem(_:))))
                        bgForFreeGemView.restorationIdentifier = "bgForFreeGemView"
                        self.scrollView.addSubview(bgForFreeGemView)
                        
                        let freeGemView = UIImageView(image: UIImage(named: "Gem_blue_big"))
                        freeGemView.frame.size = CGSize(width: 46, height: 36)
                        freeGemView.frame.origin = CGPoint(x: bgForFreeGemView.frame.width / 2 - freeGemView.frame.width / 2, y: 0 - freeGemView.frame.height)
                        freeGemView.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi))
                        freeGemView.isUserInteractionEnabled = true
                        freeGemView.restorationIdentifier = "freeGemView"
                        
                        let koefForHeight = ((self.view.frame.width * 4) / 5) / freeGemView.frame.width
                        
                        bgForFreeGemView.addSubview(freeGemView)
                        
                        let viewInfoAboutFreeEveryDayGem = UILabel(frame: CGRect(x: 0, y: 0, width: bgForFreeGemView.frame.width, height: 65))
                        viewInfoAboutFreeEveryDayGem.textAlignment = NSTextAlignment.center
                        viewInfoAboutFreeEveryDayGem.textColor = UIColor.white
                        viewInfoAboutFreeEveryDayGem.backgroundColor = UIColor.black.withAlphaComponent(0.35)
                        viewInfoAboutFreeEveryDayGem.text = NSLocalizedString("Tap at gem to get its", comment: "")
                        viewInfoAboutFreeEveryDayGem.numberOfLines = 3
                        viewInfoAboutFreeEveryDayGem.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi))
                        bgForFreeGemView.addSubview(viewInfoAboutFreeEveryDayGem)
                        
                        UIView.animate(withDuration: 0.215, animations: {
                            bgForFreeGemView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
                            for button in self.interfaceButtons {
                                button.alpha = 0
                            }
                            
                            self.topMenuView.alpha = 0
                        })
                        
                        UIView.animate(withDuration: 0.5, animations: {
                            freeGemView.frame.size = CGSize(width: (self.view.frame.width * 4) / 5, height: freeGemView.frame.height * koefForHeight)
                            freeGemView.frame.origin = CGPoint(x: bgForFreeGemView.frame.width / 2 - freeGemView.frame.width / 2, y: bgForFreeGemView.frame.height / 2 - freeGemView.frame.height / 2)
                        }, completion: { (_) in
                            freeGemView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.getFreeEveryDayGem(_:))))
                        })
                    }
                }
            }
        }
    }
    
    @objc func getFreeEveryDayGem(_ sender: UITapGestureRecognizer) {
        sender.view?.isUserInteractionEnabled = false
        sender.view?.layer.removeAllAnimations()
        
        UIView.animate(withDuration: 0.5, animations: {
            sender.view?.frame.origin = CGPoint(x: 15 / 2, y: self.scrollView.frame.height - 15 / 2)
            sender.view?.frame.size = CGSize(width: 0, height: 0)
            sender.view?.alpha = 0
            
            for button in self.interfaceButtons {
                button.alpha = 1
            }
            
            self.topMenuView.alpha = 1
        }, completion: { (_) in
            for button in self.interfaceButtons {
                button.isEnabled = true
            }
            
            Model.sharedInstance.setCountCollectedGems()
            Model.sharedInstance.setCountGems(amountGems: 1)
            Model.sharedInstance.setLastTimeUserClaimFreeEveryDayGem(Date())
            
            SKTAudio.sharedInstance().playSoundEffect(filename: "PickUpCoin.mp3")
            
            UIView.animate(withDuration: 0.215, animations: {
                sender.view?.superview?.backgroundColor = UIColor.black.withAlphaComponent(0)
            }, completion: { (_) in
                if sender.view?.superview?.restorationIdentifier == "bgForFreeGemView" {
                    sender.view?.superview?.removeFromSuperview()
                }
                sender.view?.removeFromSuperview()
                
                self.scrollView.isScrollEnabled = true
            })
        })
    }
    
    @objc func clickOnBgGetFreeGem(_ sender: UITapGestureRecognizer) {
        for subview in sender.view!.subviews {
            if subview.restorationIdentifier == "freeGemView" {
                shakeView(subview)
                break
            }
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
        let textureCharacter = UIImage(named: "PlayerStaysFront")?.cgImage
        let sizeCharacter = CGSize(width: levelTileSize.width * 0.5, height: CGFloat(textureCharacter!.height) / (CGFloat(textureCharacter!.width) / (levelTileSize.width * 0.5)))
        
        character = UIImageView(frame: CGRect(x: pointCharacter.x - sizeCharacter.width / 2, y: pointCharacter.y - sizeCharacter.height / 2, width: sizeCharacter.width, height: sizeCharacter.height))
        character.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi))
        character.image = UIImage(named: "PlayerStaysFront")
        
        scrollView.addSubview(character)
    }
    
    func menuSettings() {
        
        /// коэф. для планшетов (настройки, найти ГП)
//        var sizeForControls: CGFloat = 1
//        if Model.sharedInstance.isDeviceIpad() {
//            sizeForControls = 2
//        }
        
//        for constraint in controlsSizeConstraint {
//            constraint.constant *= sizeForControls
//        }
        
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
        
        if #available(iOS 11.0, *) {
            scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentBehavior.never
        }
        else {
            automaticallyAdjustsScrollViewInsets = false
        }
        
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

            modalWindowPresent()
        }
    }
    
    /// Функция, которая вызывает анимацию следования ГП по кривой Безье
    func moveToPoint(from: Point, to: Point, delay: CFTimeInterval = 0) {
        // Если конечная позиция не совпадает с начальной
        if from != to {
            
            /// Конечный путь до какой-либо точки через остальные, которые попадаются на пути
            var path = (bezier: UIBezierPath(), count: 0)
            
            /// текущая Y-позиция
            var row = from.row - 1
            
            /// Кол-во кнопок между началом и концом пермещения (расстояние)
            var countButtonsThrough = (to.row - from.row) / distanceBetweenLevels
            
            // Если самое начало игры, то перемещаем на 1-ую ячейку
            if Model.sharedInstance.getCountCompletedLevels() == 0 {
                path = pathToPoint(from: from, to: to)
            }
            else {
                while row < to.row - 1 {
                    // В общем, бесполезная проверка, ибо всегда передаётся число кратное 3, а после добавляется 3, но мало ли :3
                    if row % 3 == 0 {
                        let path2point = pathToPoint(from: levelButtonsPositions[row / 3], to: levelButtonsPositions[row / 3 + 1])
                        
                        // Если последняя кнопка, то ГП должен двигаться в верную сторону
                        if countButtonsThrough == 1 {
                            if levelButtonsPositions[row / 3].column < levelButtonsPositions[row / 3 + 1].column {
                                character.transform = CGAffineTransform(scaleX: 1, y: -1)
                            }
                            else {
                                character.transform = CGAffineTransform(scaleX: -1, y: -1)
                            }
                        }
                        
                        countButtonsThrough -= 1
                        
                        path.bezier.append(path2point.bezier)
                        path.count += path2point.count
                        row += 3
                    }
                }
            }
            
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
        if isModalWindowOpen == false {
            isModalWindowOpen = true
            
            if Model.sharedInstance.getLevelLives(Model.sharedInstance.currentLevel) < 1 {
                let timeToClaimFreeLife = TIME_TO_CLAIM_FREE_LIFE - (Model.sharedInstance.getLastDateClaimFreeLife(Model.sharedInstance.currentLevel)!.timeIntervalSinceNow * -1)
                
                if timeToClaimFreeLife <= 0 {
                    Model.sharedInstance.setLevelLives(level: Model.sharedInstance.currentLevel, newValue: Model.sharedInstance.getLevelLives(Model.sharedInstance.currentLevel) + 1)
                    removeLevelTileState(Model.sharedInstance.currentLevel)
                }
                else {
                    loadClaimFreeLifeAD()
                }
            }
            // Добавляем бг, чтобы при клике на него закрыть всё модальное окно
            modalWindowBg = UIView(frame: scrollView.bounds)
            modalWindowBg.backgroundColor = UIColor.black
            modalWindowBg.restorationIdentifier = "modalWindowBg"
            modalWindowBg.alpha = 0
            
            // Если уровни без начального обучения, то можно скрыть окно с выбором уровня
            if (Model.sharedInstance.currentLevel != 1 && Model.sharedInstance.currentLevel != 2) || Model.sharedInstance.getCountCompletedLevels() > 1 {
                modalWindowBg.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(bgClick(_:))))
            }
            else {
                modalWindowBg.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(shakeModalWindow(_:))))
            }
            
            modalWindowBg.isUserInteractionEnabled = true
            
            scrollView.addSubview(modalWindowBg)
            scrollView.isScrollEnabled = false
            
            // Добавляем модальное окно
            modalWindow = UIView(frame: CGRect(x: scrollView.bounds.minX - 220, y: scrollView.bounds.midY - 200 / 2, width: 220, height: 200))
            modalWindow.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi))
            
            modalWindow.backgroundColor = UIColor.init(red: 0, green: 109 / 255, blue: 240 / 255, alpha: 1)
            modalWindow.layer.cornerRadius = 15
            modalWindow.layer.shadowColor = UIColor.black.cgColor
            modalWindow.layer.shadowOffset = CGSize.zero
            modalWindow.layer.shadowOpacity = 0.35
            modalWindow.layer.shadowRadius = 10
            
            scrollView.addSubview(modalWindow)
            
            UIView.animate(withDuration: 0.215, animations: {
                for button in self.interfaceButtons {
                    button.alpha = 0
                }
                self.topMenuView.alpha = 0
                
                self.modalWindowBg.alpha = 0.5
                self.modalWindow.frame.origin.x = self.scrollView.bounds.midX - self.modalWindow.frame.width / 2
            })
            
            // Если уровни без начального обучения, то можно скрыть окно с выбором уровня
            if (Model.sharedInstance.currentLevel != 1 && Model.sharedInstance.currentLevel != 2) || Model.sharedInstance.getCountCompletedLevels() > 1 {
                modalWindow.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.bgClick(_:))))
                
                // Добавляем иконку закрытия модального окна
                let modalWindowClose = UIImageView(image: UIImage(named: "Modal_window_close"))
                modalWindowClose.frame.size = CGSize(width: modalWindowClose.frame.size.width * 0.1, height: modalWindowClose.frame.size.height * 0.1)
                modalWindowClose.frame.origin = CGPoint(x: modalWindow.frame.width + 3, y: 0 - modalWindowClose.frame.size.height)
                modalWindow.addSubview(modalWindowClose)
            }
            
            /// Название выбранного уровня
            let levelNumberLabel = UILabel(frame: CGRect(x: 20, y: 25, width: modalWindow.frame.size.width - 40, height: 35))
            levelNumberLabel.text = "\(NSLocalizedString("Level", comment: "")) \(Model.sharedInstance.currentLevel)"
            
            if Model.sharedInstance.currentLevel % Model.sharedInstance.distanceBetweenSections == 0 {
                let bossNumberTitle = Model.sharedInstance.currentLevel / Model.sharedInstance.distanceBetweenSections
                levelNumberLabel.text = "\(NSLocalizedString("BOSS", comment: "")) #\(bossNumberTitle)"
            }
            
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
            btnStart.setTitle(NSLocalizedString("START", comment: ""), for: UIControlState.normal)
            modalWindow.addSubview(btnStart)
            
            if !Model.sharedInstance.isCompletedLevel(Model.sharedInstance.currentLevel) {
                if Model.sharedInstance.currentLevel % Model.sharedInstance.distanceBetweenSections != 0 {
                    let countOfGemsImage = UIImageView(image: UIImage(named: "Heart"))
                    countOfGemsImage.frame.size = CGSize(width: countOfGemsImage.frame.size.width * 0.75, height: countOfGemsImage.frame.size.height * 0.75)
                    countOfGemsImage.frame.origin = CGPoint(x: modalWindow.frame.size.width - 35 - 20, y: 22)
                    modalWindow.addSubview(countOfGemsImage)
                
                    countGemsModalWindowLabel = UILabel(frame: CGRect(x: countOfGemsImage.frame.width / 2 - 75 / 2, y: countOfGemsImage.frame.height / 2 - 50 / 2, width: 75, height: 50))
                    countGemsModalWindowLabel?.font = UIFont(name: "AvenirNext-Bold", size: 18)
                    countGemsModalWindowLabel?.text = String(Model.sharedInstance.getLevelLives(Model.sharedInstance.currentLevel))
                    countGemsModalWindowLabel?.textAlignment = NSTextAlignment.center
                    countGemsModalWindowLabel?.textColor = UIColor.white
                    countOfGemsImage.addSubview(countGemsModalWindowLabel!)
                    
                    if Model.sharedInstance.getLevelLives(Model.sharedInstance.currentLevel) < 1 {
                        
                        countGemsModalWindowLabel?.alpha = 0
                        countGemsModalWindowLabel?.font = UIFont(name: "AvenirNext-DemiBold", size: 13)
                        countGemsModalWindowLabel?.frame.origin.y -= 3
                        labelToGetFreeLifeTime(buttonExtraLifeForAd: countGemsModalWindowLabel)
                    }
                }
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
            if Model.sharedInstance.getLevelLives(Model.sharedInstance.currentLevel) <= 0 && Model.sharedInstance.currentLevel % Model.sharedInstance.distanceBetweenSections != 0 {
                btnStart.backgroundColor = UIColor.init(red: 187 / 255, green: 36 / 255, blue: 36 / 255, alpha: 0.9)
                btnStart.removeTarget(self, action: nil, for: .allEvents)
                btnStart.addTarget(self, action: #selector(shakeBtnStart), for: .touchUpInside)
                
                secondButton.setTitle(NSLocalizedString("EXTRA LIFE", comment: ""), for: UIControlState.normal)
                secondButton.addTarget(self, action: #selector(addExtraLife), for: .touchUpInside)
                
                // Если жизней 0, то выводим надпись о получении бесплатной жизни
                if Model.sharedInstance.isCompletedLevel(Model.sharedInstance.currentLevel) == false {
                    buttonToClaimFreeLife()
                }
            }
            else {
                secondButton.setTitle(NSLocalizedString("SETTINGS", comment: ""), for: UIControlState.normal)
                secondButton.addTarget(self, action: #selector(goToMenuFromModalWindow), for: .touchUpInside)
            }
        }
    }
    
    @objc func startLevel() {
        SKTAudio.sharedInstance().playSoundEffect(filename: "Click_ModalWindow.wav")
        
        Model.sharedInstance.lastYpositionLevels = scrollView.contentOffset.y
        
        timerToClaimFreeLife.invalidate()
        
        goToLevel()
    }
    
    @objc func bgClick(_ sender: UITapGestureRecognizer) {
        if sender.view?.restorationIdentifier == "modalWindowBg" {
            SKTAudio.sharedInstance().playSoundEffect(filename: "Swish.wav")
            
            UIView.animate(withDuration: 0.215, animations: {
                for button in self.interfaceButtons {
                    button.alpha = 1
                }
                
                self.topMenuView.alpha = 1
                
                self.modalWindow.frame.origin.x = self.view.bounds.minX - self.modalWindow.frame.size.width
                
                if self.viewExtraLifeForAd != nil {
                    if self.viewExtraLifeForAd.superview != nil {
                        self.viewExtraLifeForAd.frame.origin.x = self.view.bounds.minX - self.modalWindow.frame.size.width
                    }
                }
                
                self.modalWindowBg.alpha = 0
            }, completion: { (_) in
                self.modalWindowBg.removeFromSuperview()
                self.modalWindow.removeFromSuperview()
                
                if self.viewExtraLifeForAd != nil {
                    if self.viewExtraLifeForAd.superview != nil {
                        self.viewExtraLifeForAd.removeFromSuperview()
                    }
                }
                
                self.scrollView.isScrollEnabled = true
                
                self.isModalWindowOpen = false
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
    
    @objc func shakeModalWindow(_ sender: UITapGestureRecognizer) {
        if modalWindow != nil {
            if modalWindow.superview != nil {
                shakeView(modalWindow)
            }
        }
    }
    
    @objc func goToMenuFromModalWindow(sender: UIButton) {
        SKTAudio.sharedInstance().playSoundEffect(filename: "Click_ModalWindow.wav")
        
        presentMenu(dismiss: true)
    }
    
    func buyExtraLife(price: Int = 0, addLives: Int = 1, isRefreshModalWindow: Bool = true, customLevel: Int?) {
        
        if price != 0 {
            // Отнимаем 10 драг. камней
            Model.sharedInstance.setCountGems(amountGems: price)
        }
        let level = customLevel == nil ? Model.sharedInstance.currentLevel : customLevel!
        
        Model.sharedInstance.setLevelLives(level: level, newValue: addLives)
        if isModalWindowOpen && isRefreshModalWindow {
            UIView.animate(withDuration: 0.215, animations: {
                self.modalWindow.frame.origin.x = self.view.bounds.minX - self.modalWindow.frame.size.width
                
                if self.viewExtraLifeForAd != nil {
                    if self.viewExtraLifeForAd.superview != nil {
                        self.viewExtraLifeForAd.frame.origin.x = self.view.bounds.minX - self.modalWindow.frame.size.width
                    }
                }
            }, completion: { (_) in
                self.modalWindowBg.removeFromSuperview()
                
                if self.viewExtraLifeForAd != nil {
                    self.viewExtraLifeForAd.removeFromSuperview()
                }
                
                self.removeLevelTileState(level)
                
                self.isModalWindowOpen = false
                
                self.modalWindowPresent()
            })
        }
        else {
            self.removeLevelTileState(level)
        }
    }
    
    func removeLevelTileState(_ level: Int) {
        // Ищем кнопку-уровень на scrollView
        var tileLevelSubView: UIView!
        for tileSubview in self.scrollView.subviews {
            if tileSubview.restorationIdentifier == "levelTile_\(level)" {
                tileLevelSubView = tileSubview
            }
        }
        // Ищем view, который выводит состояние уровня
        for subview in tileLevelSubView.subviews {
            if subview.restorationIdentifier == "levelStateImage" {
                UIView.animate(withDuration: 0.5, animations: {
                    subview.alpha = 0
                }, completion: { (_) in
                    subview.removeFromSuperview()
                })
            }
        }
    }
    
    @objc func addExtraLife(_ sender: UIButton) {
        SKTAudio.sharedInstance().playSoundEffect(filename: "Click_ModalWindow.wav")
        
        // Если больше 10 драг. камней, то добавляем новую жизнь
        if Model.sharedInstance.getCountGems() >= EXTRA_LIFE_PRICE {
            let message = "5 \(NSLocalizedString("An extra life is worth", comment: "")) \(EXTRA_LIFE_PRICE) \(NSLocalizedString("GEMS", comment: "")) (\(NSLocalizedString("you have", comment: "")) \(Model.sharedInstance.getCountGems()) \(NSLocalizedString("GEMS", comment: "")))"
            
            let alert = UIAlertController(title: NSLocalizedString("Buying an extra life", comment: ""), message: message, preferredStyle: UIAlertControllerStyle.alert)
            
            let actionCancel = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: UIAlertActionStyle.cancel, handler: { (_) in
                let eventParams = ["level": Model.sharedInstance.currentLevel, "countGems": Model.sharedInstance.getCountGems()]
                
                Flurry.logEvent("Cancel_buy_extra_life_levels", withParameters: eventParams)
            })
            
            let actionOk = UIAlertAction(title: NSLocalizedString("Buy one life", comment: ""), style: UIAlertActionStyle.default, handler: { (_) in
                let eventParams = ["level": Model.sharedInstance.currentLevel, "countGems": Model.sharedInstance.getCountGems()]
                
                self.buyExtraLife(price: -EXTRA_LIFE_PRICE, addLives: 5, customLevel: Model.sharedInstance.currentLevel)
                
                Flurry.logEvent("Buy_extra_life_levels", withParameters: eventParams)
            })
            
            alert.addAction(actionOk)
            alert.addAction(actionCancel)
            
            self.present(alert, animated: true, completion: nil)
        }
        else {
            let message = "\(NSLocalizedString("You do not have enough GEMS to buy an extra life", comment: "")). \(NSLocalizedString("You need", comment: "")) \(EXTRA_LIFE_PRICE) \(NSLocalizedString("GEMS", comment: "")), \(NSLocalizedString("but you only have", comment: "")) \(Model.sharedInstance.getCountGems()) \(NSLocalizedString("GEMS", comment: ""))"
            
            let alert = UIAlertController(title: NSLocalizedString("Not enough GEMS", comment: ""), message: message, preferredStyle: UIAlertControllerStyle.alert)
            
            let actionCancel = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: UIAlertActionStyle.cancel, handler: { (_) in
                let eventParams = ["level": Model.sharedInstance.currentLevel, "countGems": Model.sharedInstance.getCountGems()]
                
                Flurry.logEvent("Cancel_buy_extra_life_levels_not_enough_gems", withParameters: eventParams)
            })
            
            let actionOk = UIAlertAction(title: NSLocalizedString("Buy GEMS", comment: ""), style: UIAlertActionStyle.default, handler: { (_) in
                let eventParams = ["level": Model.sharedInstance.currentLevel, "countGems": Model.sharedInstance.getCountGems()]
                
                Flurry.logEvent("Buy_gems_extra_life_levels_not_enough_gems", withParameters: eventParams)
                
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
    
    func goToLevel() {
        if Model.sharedInstance.getLevelLives(Model.sharedInstance.currentLevel) > 0 || Model.sharedInstance.currentLevel % Model.sharedInstance.distanceBetweenSections == 0 {
            
            let eventParams = ["level": Model.sharedInstance.currentLevel, "isCompletedLevel": Model.sharedInstance.isCompletedLevel(Model.sharedInstance.currentLevel), "countLives": Model.sharedInstance.getLevelLives(Model.sharedInstance.currentLevel)] as [String : Any]
            
            Flurry.logEvent("Go_to_level", withParameters: eventParams)
            
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
        return sections[level / Model.sharedInstance.distanceBetweenSections - 1]
    }
    
    /// Функция, считает количество пройденных уровней в интервале [0; maxLevel]
    func countCompletedLevelsForPreviousSection(_ maxLevel: Int) -> Int {
        var level = maxLevel
        
        var countOfCompletedLevels = 0
        
        while level > 0 {
            if Model.sharedInstance.isCompletedLevel(level) && level % Model.sharedInstance.distanceBetweenSections != 0 {
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
        
        /// Позиции ячеек уровней
        var buttonsPositions = UserDefaults.standard.array(forKey: "levelsTilesPositions") as? [Int]
        
        // Если позиции для кнопок уровней не заданы
        if buttonsPositions == nil {
            for _ in 1...Model.sharedInstance.countLevels {
                Model.sharedInstance.generateTilesPosition()
            }
            buttonsPositions = UserDefaults.standard.array(forKey: "levelsTilesPositions") as? [Int]
        }
        
        var nearestBossPos = 0
        
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
                
                if (lastRowWhereBtnAdded != row) && (row >= 0 && row < boardSize.row + distanceBetweenLevels * distanceBetweenLevels) && ((row / distanceBetweenLevels + 1) <= Model.sharedInstance.countLevels) && (row % 3 == 0) {
                    
                    var randColumn = Int(arc4random_uniform(3)) + 1
                    if buttonsPositions != nil {
                        randColumn = buttonsPositions![row / distanceBetweenLevels]
                    }
                    
                    let buttonPos = pointFor(column: randColumn, row: row + 1)
                    
                    let button = UIButton(frame: CGRect(x: buttonPos.x - levelTileSize.width / 2, y: buttonPos.y - levelTileSize.height / 2, width: levelTileSize.width, height: levelTileSize.height))
                    
                    if row / 3 == Model.sharedInstance.getCountCompletedLevels() || ((row / 3) + 1 == Model.sharedInstance.countLevels && (Model.sharedInstance.countLevels == Model.sharedInstance.getCountCompletedLevels())) {
                        button.setBackgroundImage(UIImage(named: "Tile_center"), for: UIControlState.normal)
                    }
                    
                    var sizeLabel: CGFloat = 24
                    if Model.sharedInstance.isDeviceIpad() {
                        sizeLabel *= 2.5
                    }
                    
                    button.titleLabel?.font = UIFont(name: "Avenir Next", size: sizeLabel)
                    button.setTitle("\(row / distanceBetweenLevels + 1)", for: UIControlState.normal)
                    button.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
                    button.tag = row / distanceBetweenLevels + 1
                    button.adjustsImageWhenHighlighted = false
                    // Переворачиваем кнопку, т. к. перевернул весь слой
                    button.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi))
                    
                    if (row > 0) && ((row / distanceBetweenLevels + 1) % Model.sharedInstance.distanceBetweenSections == 0) {
                        let sizeBoss: CGFloat = (!Model.sharedInstance.isDeviceIpad() ? 17 : (17 * 2.5))
                        button.titleLabel?.font = UIFont(name: "Avenir Next", size: sizeBoss)
                        button.setTitle(NSLocalizedString("BOSS", comment: ""), for: UIControlState.normal)
                    }
                    
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
                    
                    if (row > 0) && ((row / distanceBetweenLevels) % Model.sharedInstance.distanceBetweenSections == 0) && (row > Model.sharedInstance.getCountCompletedLevels()) {
                        /// Количество пройденных уровней [0; ближайшая граница секции]
                        let completedLevels = countCompletedLevelsForPreviousSection(row / distanceBetweenLevels - 1)
                        
                        /// Кол-во уровней, которое разблокирует новую секцию
                        let needCompleteLevelsPreviousSection = getCountCompleteLevelsForNextSection(row / distanceBetweenLevels)
                        
                        // Если не пройдено достаточное кол-во уровней, чтобы разблокировать или босс не пройден
                        if completedLevels < needCompleteLevelsPreviousSection {
                            isLevelsAfterSectionDisabled = true
                            
                            if Model.sharedInstance.getCountCompletedLevels() >= (row / distanceBetweenLevels - 1) {
                                isNextSectionDisabled = true
                                nearestBossPos = row / distanceBetweenLevels
                                characterPointStart = levelButtonsPositions.last!
                            }
                            
                            let textAboutLevels = "\(NSLocalizedString("at least", comment: "")) \(needCompleteLevelsPreviousSection - completedLevels) \(NSLocalizedString("more levels", comment: ""))"
                            let disabledSectionText = "\(NSLocalizedString("Complete", comment: "")) \(textAboutLevels)\(NSLocalizedString("to unlock next section", comment: ""))"
                            
                            presentInfoBlock(point: Point(column: 1, row: row - 2), message: disabledSectionText)
                        }
                    }
                    
                    // Если последний уровень пройден, то выводим надпись о том, что новые уровни разрабатываются
                    if ((row / distanceBetweenLevels + 1) == Model.sharedInstance.getCountCompletedLevels()) && (Model.sharedInstance.getCountCompletedLevels() == Model.sharedInstance.countLevels) {
                        presentInfoBlock(point: Point(column: 1, row: row + 1), message: NSLocalizedString("New levels are coming. We are already designing new levels. Wait for updates", comment: ""), isRateApp: true)
                    }
                    
                    if (row / distanceBetweenLevels) <= Model.sharedInstance.getCountCompletedLevels() + 1 && !isLevelsAfterSectionDisabled {
                        if Model.sharedInstance.emptySavedLevelsLives() == false {
                            // Если на уровне не осталось жизней, то добавляем соответствующую метку
                            if Model.sharedInstance.getLevelLives(row / distanceBetweenLevels + 1) <= 0 && (row / distanceBetweenLevels + 1) % Model.sharedInstance.distanceBetweenSections != 0 {
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
        
        /// Последняя ячейка, от которой отрисовывается путь
        var lastPos = Point(column: buttonsPositions!.first!, row: -15)
        
        let koefForDisabledSection = isNextSectionDisabled ? (2 - (nearestBossPos % Model.sharedInstance.getCountCompletedLevels())) : 0
        
        /// Y-координата
        var row = 1
        for pos in buttonsPositions! {
            
            var to = Point(column: pos, row: row * 3 - 2)
            if isNextSectionDisabled && row == Model.sharedInstance.getCountCompletedLevels() + 2 - koefForDisabledSection + 1 {
                to = Point(column: lastPos.column, row: lastPos.row + 1)
            }
            else {
                if row > Model.sharedInstance.getCountCompletedLevels() + 2 - koefForDisabledSection {
                    break
                }
            }
            
            var sizeCircle = CGSize(width: levelTileSize.width / 1.625, height: levelTileSize.height / 1.625)
            
            if row % Model.sharedInstance.distanceBetweenSections == 0 {
                sizeCircle = CGSize(width: levelTileSize.width, height: levelTileSize.height)
            }
            
            let pinkCircleLevelTile = UIView(frame: CGRect(origin: pointFor(column: to.column, row: to.row), size: sizeCircle))
            pinkCircleLevelTile.frame.origin.x -= sizeCircle.width / 2
            pinkCircleLevelTile.frame.origin.y -= sizeCircle.height / 2
            
            pinkCircleLevelTile.layer.backgroundColor = UIColor.init(red: 250 / 255, green: 153 / 255, blue: 137 / 255, alpha: 1).cgColor
            
            if row % Model.sharedInstance.distanceBetweenSections != 0 {
                pinkCircleLevelTile.layer.cornerRadius = pinkCircleLevelTile.frame.size.width / 2
            }
            else {
                pinkCircleLevelTile.layer.cornerRadius = pinkCircleLevelTile.frame.size.width / 7
            }
            
            if !isNextSectionDisabled || row < nearestBossPos {
                scrollView.insertSubview(pinkCircleLevelTile, at: 3)
            }

            /// Путь от последней кнопки до текущей
            let path2point = pathToPoint(from: lastPos, to: to)
            lastPos = Point(column: pos, row: row * 3 - 2)
            row += 1
            
            let layer = CAShapeLayer()
            
            layer.path = path2point.bezier.cgPath
            layer.strokeColor = UIColor.init(red: 250 / 255, green: 153 / 255, blue: 137 / 255, alpha: 1).cgColor
            layer.fillColor = UIColor.clear.cgColor
            layer.lineCap = kCALineCapRound
            layer.lineJoin = kCALineJoinRound
            layer.lineWidth = 7
            
            if Model.sharedInstance.isDeviceIpad() {
                layer.lineWidth *= 2
            }
            
            scrollView.layer.insertSublayer(layer, at: 4)
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
    
    /// Найти ГП
    @IBAction func findCharacter(_ sender: UIButton) {
        SKTAudio.sharedInstance().playSoundEffect(filename: "Click.wav")
        
        let koefIfLastLevel = Model.sharedInstance.countLevels == Model.sharedInstance.getCountCompletedLevels() || isNextSectionDisabled ? 1 : 0
        let point = CGPoint(x: 0, y: CGFloat((Model.sharedInstance.getCountCompletedLevels() - 1 - koefIfLastLevel) * distanceBetweenLevels) * levelTileSize.height)
        scrollView.setContentOffset(point, animated: true)
    }
    
    func presentMenu(dismiss: Bool = false) {
        if let storyboard = storyboard {
            let menuViewController = storyboard.instantiateViewController(withIdentifier: "MenuViewController") as! MenuViewController
            menuViewController.isDismissed = dismiss
            navigationController?.pushViewController(menuViewController, animated: true)
        }
    }
    
    /// Окно на scrollView, которое выводит какое-либо сообщение
    func presentInfoBlock(point: Point, message: String, isRateApp: Bool = false) {
        let pointOnScrollView = pointFor(column: point.column, row: point.row)
        let infoBlockBgView = UIView(frame: CGRect(x: pointOnScrollView.x - levelTileSize.width, y: pointOnScrollView.y + 3 * levelTileSize.height / 4, width: levelTileSize.width * 4, height: levelTileSize.height * 1.5))
        infoBlockBgView.backgroundColor = UIColor.init(red: 0, green: 109 / 255, blue: 240 / 255, alpha: 1)
        infoBlockBgView.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi))
        
        infoBlockBgView.layer.cornerRadius = 15
        infoBlockBgView.layer.shadowColor = UIColor.black.cgColor
        infoBlockBgView.layer.shadowOffset = CGSize.zero
        infoBlockBgView.layer.shadowOpacity = 0.35
        infoBlockBgView.layer.shadowRadius = 10
        scrollView.addSubview(infoBlockBgView)
        
        let infoBlockLabel = UILabel(frame: CGRect(x: 10, y: 0, width: infoBlockBgView.frame.width - 20, height: infoBlockBgView.frame.height))
        
        let textAboutFinishedLastLevel = message
        
        infoBlockLabel.text = textAboutFinishedLastLevel
        infoBlockLabel.textAlignment = NSTextAlignment.center
        infoBlockLabel.numberOfLines = 3
        
        var scaleFactorForIpad: CGFloat = 1
        
        if Model.sharedInstance.isDeviceIpad() {
            scaleFactorForIpad = 2
        }
        
        infoBlockLabel.font = UIFont(name: "AvenirNext-DemiBold", size: 17 * scaleFactorForIpad)
        infoBlockLabel.textColor = UIColor.white
        infoBlockBgView.addSubview(infoBlockLabel)
        
        if isRateApp {
            infoBlockBgView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(rateApp(_:))))
        }
    }
    
    @objc func rateApp(_ sender: UITapGestureRecognizer) {
        Flurry.logEvent("Rate_app_levels")
        
        if #available(iOS 10.3,*) {
            SKStoreReviewController.requestReview()
        }
        else {
            let appId = 1351841309
            let url = URL(string: "itms-apps:itunes.apple.com/app/apple-store/id\(appId)?mt=8&action=write-review")!
            UIApplication.shared.open(url, options: ["mt": 8, "action": "write-review"], completionHandler: nil)
        }
    }
    
    @objc func extraLifeForAd(_ sender: UIButton) {
        presentClaimFreeLifeAD()
    }
    
    func stringFromTimeInterval(_ interval: TimeInterval) -> String {
        let time = Int(interval)
        
        let minutes = (time / 60) % 60
        let seconds = time % 60
        
        var leadingZero = ""
        if seconds / 10 == 0 {
            leadingZero = "0"
        }
        
        return "\(minutes):\(leadingZero)\(seconds)"
    }
    
    func labelToGetFreeLifeTime(buttonExtraLifeForAd: UILabel?, customLevel: Int? = nil) {
        
        let level = customLevel == nil ? Model.sharedInstance.currentLevel : customLevel!
        
        if levelsOnTimer.contains(level) == false {
            let timeToClaimFreeLife = TIME_TO_CLAIM_FREE_LIFE - (Model.sharedInstance.getLastDateClaimFreeLife(level)!.timeIntervalSinceNow * -1)
            
            if Model.sharedInstance.currentLevel == level {
                countGemsModalWindowLabel?.text = String(stringFromTimeInterval(timeToClaimFreeLife))
            }
            
            timerToClaimFreeLife = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { (timer) in
                
                if Model.sharedInstance.getLastDateClaimFreeLife(level) != nil {

                    let timeToClaimFreeLife = TIME_TO_CLAIM_FREE_LIFE - (Model.sharedInstance.getLastDateClaimFreeLife(level)!.timeIntervalSinceNow * -1)
                    if Model.sharedInstance.getLevelLives(level) < 1 {
                        if timeToClaimFreeLife > 1 {
                            
                            if Model.sharedInstance.currentLevel == level {
                                if self.countGemsModalWindowLabel?.alpha == 0 {
                                    UIView.animate(withDuration: 0.25, animations: {
                                        self.countGemsModalWindowLabel?.alpha = 1
                                    })
                                }
                                
                                self.countGemsModalWindowLabel?.text = self.stringFromTimeInterval(timeToClaimFreeLife)
                            }
                        }
                        else {
                            if Model.sharedInstance.currentLevel == level {
                                self.countGemsModalWindowLabel?.isHidden = true
                            }
                            
                            self.removeLevelTileState(level)
                            
                            self.levelsOnTimer.remove(at: self.levelsOnTimer.index(of: level)!)
                            
                            if Model.sharedInstance.getLevelLives(level) < 1 {
                                let isRefreshModalWindow = Model.sharedInstance.currentLevel == level
                                
                                self.buyExtraLife(price: 0, addLives: Model.sharedInstance.getLevelLives(level) + 1, isRefreshModalWindow: isRefreshModalWindow, customLevel: level)
                            }
                            
                            timer.invalidate()
                        }
                    }
                    else {
                        timer.invalidate()
                    }
                }
            }
            levelsOnTimer.append(level)
        }
        
        
    }
    
    func buttonToClaimFreeLife() {
        // Если есть кнопка "Бесплатная жизнь", то немного поднимает модальное окно
        modalWindow.frame.origin.y += (modalWindow.frame.height / 4) / 2
        
        viewExtraLifeForAd = UIView(frame: CGRect(x: scrollView.frame.minX - modalWindow.frame.width, y: modalWindow.frame.minY - 10 - (modalWindow.frame.height / 4), width: modalWindow.frame.width, height: modalWindow.frame.height / 4))
        viewExtraLifeForAd.backgroundColor = UIColor.init(red: 0, green: 109 / 255, blue: 240 / 255, alpha: 1)
        viewExtraLifeForAd.clipsToBounds = true
        viewExtraLifeForAd.layer.cornerRadius = 15
        viewExtraLifeForAd.layer.shadowColor = UIColor.black.cgColor
        viewExtraLifeForAd.layer.shadowOffset = CGSize.zero
        viewExtraLifeForAd.layer.shadowOpacity = 0.35
        viewExtraLifeForAd.layer.shadowRadius = 10
        viewExtraLifeForAd.isUserInteractionEnabled = true
        viewExtraLifeForAd.restorationIdentifier = "viewExtraLifeForAd"
        viewExtraLifeForAd.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi))
        scrollView.addSubview(viewExtraLifeForAd)
        
        UIView.animate(withDuration: 0.215, animations: {
            self.viewExtraLifeForAd.frame.origin.x = self.modalWindow.frame.minX
        })
        
        let buttonExtraLifeForAd = UIButton(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: viewExtraLifeForAd.frame.size))
        buttonExtraLifeForAd.setTitleColor(UIColor.white, for: UIControlState.normal)
        
        buttonExtraLifeForAd.setTitle(NSLocalizedString("Free extra life", comment: ""), for: UIControlState.normal)
        buttonExtraLifeForAd.titleLabel?.textAlignment = NSTextAlignment.center
        buttonExtraLifeForAd.titleLabel?.font = UIFont(name: "AvenirNext-DemiBold", size: 24)
        viewExtraLifeForAd.addSubview(buttonExtraLifeForAd)
        
        buttonExtraLifeForAd.addTarget(self, action: #selector(extraLifeForAd), for: UIControlEvents.touchUpInside)
    }
    
    func loadClaimFreeLifeAD() {
        GADRewardBasedVideoAd.sharedInstance().delegate = self
        let request = GADRequest()
        GADRewardBasedVideoAd.sharedInstance().load(request, withAdUnitID: "ca-app-pub-3811728185284523/1179286082")
    }
    
    func presentClaimFreeLifeAD() {
        if GADRewardBasedVideoAd.sharedInstance().isReady == true {
            GADRewardBasedVideoAd.sharedInstance().present(fromRootViewController: self)
        }
        else {
            let eventParams = ["level": Model.sharedInstance.currentLevel, "countGems": Model.sharedInstance.getCountGems()]
            
            loadClaimFreeLifeAD()
            
            let title = NSLocalizedString("FAIL", comment: "")
            let message = NSLocalizedString("Rewarded video was not ready, try again or check your Internet connection", comment: "")
            
            let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
            let actionOk = UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: UIAlertActionStyle.default)
            alert.addAction(actionOk)
            self.present(alert, animated: true, completion: nil)
            
            Flurry.logEvent("Ad_wasnt_ready_levels", withParameters: eventParams)
        }
    }
    
    func rewardBasedVideoAd(_ rewardBasedVideoAd: GADRewardBasedVideoAd, didRewardUserWith reward: GADAdReward) {
        let eventParams = ["level": Model.sharedInstance.currentLevel, "countGems": Model.sharedInstance.getCountGems()]
        
        if Model.sharedInstance.isActivatedSounds() {
            SKTAudio.sharedInstance().resumeBackgroundMusic()
        }
        
        Model.sharedInstance.setLastDateClaimFreeLife(Model.sharedInstance.currentLevel, value: Date())
        
        buyExtraLife(price: 0, addLives: Model.sharedInstance.getLevelLives(Model.sharedInstance.currentLevel) + Int(truncating: reward.amount), customLevel: Model.sharedInstance.currentLevel)
        
        Flurry.logEvent("Watch_ad_free_life_levels_success", withParameters: eventParams)
    }
    
    func rewardBasedVideoAdDidOpen(_ rewardBasedVideoAd: GADRewardBasedVideoAd) {
        if Model.sharedInstance.isActivatedSounds() {
            SKTAudio.sharedInstance().pauseBackgroundMusic()
        }
    }
    
    func rewardBasedVideoAdDidClose(_ rewardBasedVideoAd: GADRewardBasedVideoAd) {
        if Model.sharedInstance.isActivatedSounds() {
            SKTAudio.sharedInstance().resumeBackgroundMusic()
        }
        
        loadClaimFreeLifeAD()
    }
    
    func rewardBasedVideoAd(_ rewardBasedVideoAd: GADRewardBasedVideoAd, didFailToLoadWithError error: Error) {
        if Model.sharedInstance.isActivatedSounds() {
            SKTAudio.sharedInstance().resumeBackgroundMusic()
        }
        
        loadClaimFreeLifeAD()
    }
    
    /// Переход в "Достижения"
    @IBAction func goToAchives(_ sender: Any) {
        if let storyboard = storyboard {
            SKTAudio.sharedInstance().playSoundEffect(filename: "Click.wav")
            
            let achieveViewController = storyboard.instantiateViewController(withIdentifier: "AchieveViewController") as! AchieveViewContoller
            navigationController?.pushViewController(achieveViewController, animated: true)
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return Model.sharedInstance.isHiddenStatusBar()
    }
}
