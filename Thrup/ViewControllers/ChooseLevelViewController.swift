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

    /// Общее кол-во уровней
    var countLevels = Model.sharedInstance.countLevels
    
    /// Количество пройденных уровней (последний пройденный уровень)
    var countCompletedLevels = Model.sharedInstance.getCountCompletedLevels()
    
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
    
    /// Стартовая позиция ГП после перехода из уровня
    var characterPosLevelFromScene = -1
    
    /// Открыть модальное окно при открытии меню
    var presentModalWindowByDefault: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if Model.sharedInstance.getCountCompletedLevels() == 1 && !Model.sharedInstance.isCompletedLevel(2) {
            Model.sharedInstance.currentLevel = 2
        }
        
        menuSettings()
        
        characterInitial()
        
        if !presentModalWindowByDefault {
            if Model.sharedInstance.currentLevel - 1 < countLevels {
                // Если перешли в меню после прохождения уровня, то запускаем анимацию перехода на след. уровень
                if moveCharacterToNextLevel {
                    moveToPoint(from: levelButtonsPositions[Model.sharedInstance.currentLevel - 1 - 1], to: levelButtonsPositions[Model.sharedInstance.currentLevel - 1], delay: 0.5)
                }
            }
            
            if countCompletedLevels == 0 {
                moveToPoint(from: Point(column: levelButtonsPositions[Model.sharedInstance.currentLevel - 1].column, row: levelButtonsPositions[Model.sharedInstance.currentLevel - 1].row - distanceBetweenLevels), to: levelButtonsPositions[Model.sharedInstance.currentLevel - 1], delay: 0.5)
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        
        // Если необходимо открыть модальное окно по умолчанию (при переходе в меню)
        if presentModalWindowByDefault {
            modalWindowPresent()
        }
        else {
            // Если обучение было "прервано" после 1-ого уровня
            if !moveCharacterToNextLevel && Model.sharedInstance.currentLevel == 2 && Model.sharedInstance.getCountCompletedLevels() == 1 && !Model.sharedInstance.isCompletedLevel(2) {
                modalWindowPresent()
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
        
        let pointCharacter = pointFor(column: characterPointStart.column, row: characterPointStart.row - (countCompletedLevels == 0 ? distanceBetweenLevels : 0))
        let textureCharacter = playerAnimatedAtlas.textureNamed("PlayerWalks_2").cgImage()
        let sizeCharacter = CGSize(width: levelTileSize.width * 0.5, height: CGFloat(textureCharacter.height) / (CGFloat(textureCharacter.width) / (levelTileSize.width * 0.5)))
        
        character = UIImageView(frame: CGRect(x: pointCharacter.x - sizeCharacter.width / 2, y: pointCharacter.y - sizeCharacter.height / 2, width: sizeCharacter.width, height: sizeCharacter.height))
        character.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi))
        character.image = UIImage(cgImage: playerAnimatedAtlas.textureNamed("PlayerWalks_2").cgImage())
        
        scrollView.addSubview(character)
    }
    
    func menuSettings() {
        // Если текущий уровень меньше 1, то добавляем к просмотру ещё одну ячейку
        if countCompletedLevels < 1 {
            extraCountForExtremeLevels = 1
        }
        // Если нахожимся на последних уровнях, то подфиксиваем так, чтобы последний уровень фиксировался по центру и не уходил дальше
        if countLevels - (countCompletedLevels + 2) < distanceBetweenLevels {
            extraCountForExtremeLevels = countLevels - countCompletedLevels - distanceBetweenLevels + 1
        }
        
        boardSize.row = (countCompletedLevels + distanceBetweenLevels + extraCountForExtremeLevels) * distanceBetweenLevels
        
        levelTileSize.width = self.view.bounds.width / CGFloat(boardSize.column)
        levelTileSize.height = levelTileSize.width
        
        tilesLayer = UIView(frame: CGRect(x: -levelTileSize.width * CGFloat(boardSize.column) / 2, y: 0, width: self.view.bounds.width, height: CGFloat(boardSize.row) * levelTileSize.height))
        
        scrollView.addSubview(tilesLayer)
        addTiles()

        if moveCharacterToNextLevel {
            characterPointStart = levelButtonsPositions[Model.sharedInstance.currentLevel - 1 - (characterPosLevelFromScene != -1 ? 0 : 1)]
        }
    }
    
    override func viewDidLayoutSubviews() {
        // Почему-то было сложно сделать scroll снизу вверх, то просто перевернул на 180 слой, а потом все кнопки тоже на 180
        scrollView.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi))
        
        scrollView.contentSize = CGSize(width: self.view.bounds.width, height: CGFloat((countCompletedLevels + distanceBetweenLevels + extraCountForExtremeLevels) * distanceBetweenLevels) * levelTileSize.height)
        
        scrollView.contentOffset.y = CGFloat((countCompletedLevels + ((countLevels - countCompletedLevels < distanceBetweenLevels) ? extraCountForExtremeLevels : 0)) * distanceBetweenLevels) * levelTileSize.height
        
        scrollView.contentInset = UIEdgeInsets.zero
        scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentBehavior.never
        scrollView.scrollIndicatorInsets = UIEdgeInsets.zero
        
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = false
        
        if Model.sharedInstance.currentLevel - 1 != countLevels {
            if characterPosLevelFromScene != -1 {
                scrollView.contentOffset.y = CGFloat((characterPosLevelFromScene - 1 - (Model.sharedInstance.currentLevel == Model.sharedInstance.countLevels ? 1 : 0)) * distanceBetweenLevels) * levelTileSize.height
            }
            else {
                if moveCharacterToNextLevel {
                    scrollView.contentOffset.y = CGFloat((Model.sharedInstance.currentLevel - 1 - (Model.sharedInstance.currentLevel - 1 <= Model.sharedInstance.countLevels ? 1 : 0)) * distanceBetweenLevels) * levelTileSize.height
                }
            }
        }
    }
    
    @objc func buttonAction(sender: UIButton!) {
        let buttonSenderAction: UIButton = sender
        
        // Если уровень не заблокирован
        if buttonSenderAction.tag != -1 {
            Model.sharedInstance.currentLevel = buttonSenderAction.tag
            moveCharacterToNextLevel = false
            
            /// Точка, на которую ГП будет перемещаться
            let nextPoint = convertPoint(point: CGPoint(x: buttonSenderAction.frame.origin.x + levelTileSize.width / 2, y: buttonSenderAction.frame.origin.y + levelTileSize.height / 2))
            
            moveToPoint(from: convertPoint(point: self.character.layer.position).point, to: nextPoint.point, delay: 0.25)
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
            
                DispatchQueue.main.async {
                    if !self.moveCharacterToNextLevel {
                        var extremeKoef = (Model.sharedInstance.currentLevel - 1 == self.countCompletedLevels + 2 ? -1 : 0)
                        extremeKoef = ((self.characterPointStart.row - 1) / self.distanceBetweenLevels + 1) > self.countCompletedLevels + 2 ? -2 : extremeKoef
                        extremeKoef = (((self.characterPointStart.row - 1) / self.distanceBetweenLevels) - 1) < 0 ? 0 : -1
                        
                        UIView.animate(withDuration: 0.25, animations: {
                            self.scrollView.contentOffset.y = CGFloat((((self.characterPointStart.row - 1) / self.distanceBetweenLevels) + extremeKoef) * self.distanceBetweenLevels) * self.levelTileSize.height
                        }, completion: { (_) in
                            
                            var extremeKoef = (Model.sharedInstance.currentLevel - 1 == self.countCompletedLevels + 2 ? -2 : 0)
                            extremeKoef = (Model.sharedInstance.currentLevel - 1 - 1 < 0) ? 0 : -1
                            
                            
                            UIView.animate(withDuration: 0.25 * Double(path.count), delay: 0, options: UIViewAnimationOptions.curveLinear, animations: {
                                self.scrollView.contentOffset.y = CGFloat((Model.sharedInstance.currentLevel - 1 + extremeKoef) * self.distanceBetweenLevels) * self.levelTileSize.height
                            })
                        })
                    }
                    else {
                        let extremeKoef = (Model.sharedInstance.currentLevel >= self.countCompletedLevels + 2 || Model.sharedInstance.currentLevel >= self.countLevels) ? -1 : 0
                        
                        UIView.animate(withDuration: 0.25 * Double(path.count), delay: delay, options: UIViewAnimationOptions.curveLinear, animations: {
                            self.scrollView.contentOffset.y = CGFloat((Model.sharedInstance.currentLevel + extremeKoef - 1) * self.distanceBetweenLevels) * self.levelTileSize.height
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
        modalWindowBg.backgroundColor = UIColor.clear
        
        // Если уровни без начального обучения, то можно скрыть окно с выбором уровня
        if (Model.sharedInstance.currentLevel != 1 && Model.sharedInstance.currentLevel != 2) || Model.sharedInstance.getCountCompletedLevels() > 1 {
            modalWindowBg.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.bgClick(_:))))
        }
        modalWindowBg.isUserInteractionEnabled = true
        
        scrollView.addSubview(modalWindowBg)
        scrollView.isScrollEnabled = false
        
        // Добавляем модальное окно
        modalWindow = UIView(frame: CGRect(x: self.view.frame.minX - 200, y: self.view.bounds.midY - 200 / 2, width: 200, height: 200))
        modalWindow.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi))
        
        UIView.animate(withDuration: 0.215, animations: {
            self.modalWindow.frame.origin.x = self.view.bounds.midX - self.modalWindow.frame.size.width / 2
        })
        
        modalWindow.backgroundColor = UIColor.blue
        
        modalWindow.layer.cornerRadius = 10
        modalWindow.layer.shadowColor = UIColor.black.cgColor
        modalWindow.layer.shadowOffset = CGSize.zero
        modalWindow.layer.shadowOpacity = 0.35
        modalWindow.layer.shadowRadius = 10
        
        // Если уровни без начального обучения, то можно скрыть окно с выбором уровня
        if (Model.sharedInstance.currentLevel != 1 && Model.sharedInstance.currentLevel != 2) || Model.sharedInstance.getCountCompletedLevels() > 1 {
            modalWindow.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.bgClick(_:))))
        }
        
        modalWindowBg.addSubview(modalWindow)
        
        /// Название выбранного уровня
        let levelNumberLabel = UILabel(frame: CGRect(x: modalWindow.bounds.midX - modalWindow.frame.size.width / 2, y: 0 + 15, width: modalWindow.frame.size.width, height: 35))
        levelNumberLabel.text = "Level \(Model.sharedInstance.currentLevel)"
        levelNumberLabel.textAlignment = NSTextAlignment.center
        levelNumberLabel.font = UIFont(name: "Avenir Next", size: 24)
        levelNumberLabel.textColor = UIColor.white
        modalWindow.addSubview(levelNumberLabel)
        
        // Кнопка "старт" в модальном окне, которая переносит на выбранный уровень
        let btnStart = UIButton(frame: CGRect(x: modalWindow.bounds.midX - 100 / 2, y: modalWindow.bounds.midY - 50 / 2, width: 100, height: 50))
        btnStart.layer.cornerRadius = 5
        btnStart.backgroundColor = UIColor.red
        btnStart.addTarget(self, action: #selector(startLevel), for: .touchUpInside)
        btnStart.setTitle("START", for: UIControlState.normal)
        
        // Если количество жизенй на уровне меньше 0, то добавляем кнопку получения новой жизни
        if Model.sharedInstance.getLevelLives(Model.sharedInstance.currentLevel) <= 0 {
            btnStart.backgroundColor = UIColor(displayP3Red: 0.5, green: 0, blue: 0, alpha: 0.9)
            btnStart.removeTarget(self, action: nil, for: .allEvents)
            btnStart.addTarget(self, action: #selector(shakeBtnStart), for: .touchUpInside)
            // Кнопка "дополнительная жизнь" в модальном окне
            let btnExtraLives = UIButton(frame: CGRect(x: modalWindow.bounds.midX - 100 / 2, y: modalWindow.frame.size.height - 50 - 15, width: 100, height: 50))
            btnExtraLives.layer.cornerRadius = 5
            btnExtraLives.backgroundColor = UIColor.green
            btnExtraLives.setTitleColor(UIColor.black, for: UIControlState.normal)
            btnExtraLives.addTarget(self, action: #selector(addExtraLife), for: .touchUpInside)
            btnExtraLives.setTitle("EXTRA LIFE", for: UIControlState.normal)
            modalWindow.addSubview(btnExtraLives)
            
            let countOfGemsToUnlockImage = UIImageView(image: UIImage(named: "Gem_blue"))
            countOfGemsToUnlockImage.frame.size = CGSize(width: countOfGemsToUnlockImage.frame.size.width * 0.75, height: countOfGemsToUnlockImage.frame.size.height * 0.75)
            countOfGemsToUnlockImage.frame.origin = CGPoint(x: btnExtraLives.frame.size.width + 5, y: btnExtraLives.frame.size.height / 2 - countOfGemsToUnlockImage.frame.size.height / 2 - 5)
            btnExtraLives.addSubview(countOfGemsToUnlockImage)
            
            let countOfGemsToUnlockLabel = UILabel(frame: CGRect(x: countOfGemsToUnlockImage.frame.size.width / 2 - 35 / 2, y: countOfGemsToUnlockImage.frame.size.height + 7 - 50 / 2, width: 35, height: 50))
            countOfGemsToUnlockLabel.font = UIFont(name: "Avenir Next", size: 14)
            countOfGemsToUnlockLabel.text = "X10"
            countOfGemsToUnlockLabel.textAlignment = NSTextAlignment.center
            countOfGemsToUnlockLabel.textColor = UIColor.white
            countOfGemsToUnlockImage.addSubview(countOfGemsToUnlockLabel)
        }
        
        modalWindow.addSubview(btnStart)
        
        drawHearts(Model.sharedInstance.currentLevel)
    }
    
    @objc func startLevel() {
        self.goToLevel()
    }
    
    @objc func bgClick(_ sender: UITapGestureRecognizer) {
        if sender.view?.superview === scrollView {
            UIView.animate(withDuration: 0.215, animations: {
                self.modalWindow.frame.origin.x = self.view.bounds.minX - self.modalWindow.frame.size.width
            }, completion: { (_) in
                self.modalWindowBg.removeFromSuperview()
                self.scrollView.isScrollEnabled = true
            })
        }
    }
    
    @objc func shakeBtnStart(_ button: UIButton) {
        shakeView(button)
    }
    
    @objc func shakeScreen() {
        shakeView(self.view)
    }
    
    @objc func addExtraLife(_ sender: UIButton) {
        // Если больше 10 драг. камней, то добавляем новую жизнь
        if Model.sharedInstance.getCountGems() >= 10 {
            
            // Отнимаем 10 драг. камней
            Model.sharedInstance.setCountGems(amountGems: -10)
            
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
        else {
            presentMenu()
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
                
                let heartsStackView = UIView(frame: CGRect(x: 0, y: Int(modalWindow.frame.size.height - heartSize.height - 15), width: Int(modalWindow.frame.size.width), height: Int(heartSize.height)))
                
                for index in 0...allLivesPerLevel - 1 {
                    heartTexture = allLivesPerLevel - 1 - index < livesOnLevel ? SKTexture(imageNamed: "Heart") : SKTexture(imageNamed: "Heart_empty")
                    
                    let button = UIButton(frame: CGRect(x: 3 / 2 + (modalWindow.frame.size.width - (CGFloat((heartSize.width + 3) * CGFloat(allLivesPerLevel)))) / 2 + CGFloat((heartSize.width + 3) * CGFloat(index)), y: 0, width: heartSize.width, height: heartSize.height))
                    button.setBackgroundImage(UIImage(cgImage: heartTexture.cgImage()), for: UIControlState.normal)
                    button.isUserInteractionEnabled = false
//                    button.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
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
    
    func addTiles() {
        /// Флаг, который запоминает последнюю строку, на которой была вставлена кнопка уровня
        var lastRowWhereBtnAdded = Int.min
        
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
                
                if (lastRowWhereBtnAdded != row) && (row >= 0 && row < boardSize.row + distanceBetweenLevels * distanceBetweenLevels) && ((row / distanceBetweenLevels + 1) <= countLevels) && (row % 3 == 0) {
                    
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
                    
                    // Если уровень (который отображает кнопка) равен тому уровню, который был пройден последним, то запомнить координаты этой позиции, чтобы вывести туда персонажа
                    
                    let koefForLastLevel = (countLevels == countCompletedLevels) ? 0 : 1
                    
                    if characterPosLevelFromScene != -1 {
                        if (row / distanceBetweenLevels + 1 == characterPosLevelFromScene) {
                            characterPointStart = Point(column: randColumn, row: row + 1)
                        }
                    }
                    else {
                        if row / distanceBetweenLevels + 1 == countCompletedLevels + koefForLastLevel {
                            characterPointStart = Point(column: randColumn, row: row + 1)
                        }
                    }
                    
                    // Если уровень пройден, то добавляем соответствующую метку
                    if Model.sharedInstance.isCompletedLevel(row / distanceBetweenLevels + 1) {
                        addLevelImageState(spriteName: "Checked", buttonToPin: button)
                    }
                    
                    if (row / distanceBetweenLevels) <= countCompletedLevels + 2 {
                        if Model.sharedInstance.emptySavedLevelsLives() == false {
                            // Если на уровне не осталось жизней, то добавляем соответствующую метку
                            if Model.sharedInstance.getLevelLives(row / distanceBetweenLevels + 1) <= 0 {
//                                button.isEnabled = false
//                                button.alpha = 0.5
                                addLevelImageState(spriteName: "Heart_empty", buttonToPin: button, sizeKoef: CGSize(width: 0.275, height: 0.25))
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
        presentMenu()
    }
    
    func presentMenu() {
        if let storyboard = storyboard {
            let menuViewController = storyboard.instantiateViewController(withIdentifier: "MenuViewController") as! MenuViewController
            navigationController?.pushViewController(menuViewController, animated: true)
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
}
