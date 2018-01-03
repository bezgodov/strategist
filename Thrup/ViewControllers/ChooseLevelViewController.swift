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
    
    /// Модальное окно
    var modalWindow: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        menuSettings()
        
        characterInitial()
        
        // Если перешли в меню после прохождения уровня, то запускаем анимацию перехода на след. уровень
        if moveCharacterToNextLevel {
            moveToPoint(from: levelButtonsPositions[Model.sharedInstance.currentLevel - 1 - 1], to: levelButtonsPositions[Model.sharedInstance.currentLevel - 1], delay: 0.5)
        }
    }
    
    func characterInitial() {
        /// Задаём анимацию для ГП
        let playerAnimatedAtlas = SKTextureAtlas(named: "PlayerWalks")
        walkFrames = [UIImage]()
        let numImages = playerAnimatedAtlas.textureNames.count
        for i in 1...numImages {
            let playerTextureName = "PlayerPinkWalks_\(i)"
            walkFrames.append(UIImage(cgImage: playerAnimatedAtlas.textureNamed(playerTextureName).cgImage()))
        }
        
        let pointCharacter = pointFor(column: characterPointStart.column, row: characterPointStart.row)
        let textureCharacter = playerAnimatedAtlas.textureNamed("PlayerPinkWalks_1").cgImage()
        let sizeCharacter = CGSize(width: levelTileSize.width * 0.5, height: CGFloat(textureCharacter.height) / (CGFloat(textureCharacter.width) / (levelTileSize.width * 0.5)))
        
        character = UIImageView(frame: CGRect(x: pointCharacter.x - sizeCharacter.width / 2, y: pointCharacter.y - sizeCharacter.height / 2, width: sizeCharacter.width, height: sizeCharacter.height))
        character.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi))
        character.image = UIImage(cgImage: playerAnimatedAtlas.textureNamed("PlayerPinkWalks_2").cgImage())
        
        scrollView.addSubview(character)
    }
    
    func menuSettings() {
        // Если текущий уровень меньше 1, то добавляем к просмотру ещё одну ячейку
        if countCompletedLevels < 1 {
            extraCountForExtremeLevels = 1
        }
        // Если нахожимся на последних уровнях, то подфиксиваем так, чтобы последний уровень фиксировался по центру и не уходил дальше
        if countLevels - countCompletedLevels < distanceBetweenLevels {
            extraCountForExtremeLevels = countLevels - countCompletedLevels - distanceBetweenLevels + 1
        }
        
        boardSize.row = (countCompletedLevels + distanceBetweenLevels + extraCountForExtremeLevels) * distanceBetweenLevels
        
        levelTileSize.width = self.view.bounds.width / CGFloat(boardSize.column)
        levelTileSize.height = levelTileSize.width
        
        tilesLayer = UIView(frame: CGRect(x: -levelTileSize.width * CGFloat(boardSize.column) / 2, y: 0, width: self.view.bounds.width, height: CGFloat(boardSize.row) * levelTileSize.height))
        
        scrollView.addSubview(tilesLayer)
        addTiles()
        
        if moveCharacterToNextLevel {
            characterPointStart = levelButtonsPositions[Model.sharedInstance.currentLevel - 1 - 1]
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
        
        if moveCharacterToNextLevel {
            scrollView.contentOffset.y = CGFloat((Model.sharedInstance.currentLevel - 1 - 1) * distanceBetweenLevels) * levelTileSize.height
        }
    }
    
//    @IBAction func chooseLevel(sender: UIButton) {
//
//    }
    
    @objc func buttonAction(sender: UIButton!) {
        let buttonSenderAction: UIButton = sender
        
        Model.sharedInstance.currentLevel = buttonSenderAction.tag
        
        // Анимации ходьбы ГП
        character.animationImages = walkFrames
        character.animationRepeatCount = 0
        character.animationDuration = TimeInterval(0.05 * Double(walkFrames.count))
        character.startAnimating()
        
        /// Точка, на которую ГП будет перемещаться
        let nextPoint = convertPoint(point: CGPoint(x: buttonSenderAction.frame.origin.x + levelTileSize.width / 2, y: buttonSenderAction.frame.origin.y + levelTileSize.height / 2))
        moveToPoint(from: convertPoint(point: self.character.layer.position).point, to: nextPoint.point)
    }
    
    /// Функция, которая вызывает анимацию следования ГП по кривой Безье
    func moveToPoint(from: Point, to: Point, delay: CFTimeInterval = 0) {
        // Второе -1, т.к. массив кнопок уровней начинается с 0
        let path = pathToPoint(from: from, to: to)
        
        // Если предыдущая анимация ещё не закончилась
        if character.layer.animation(forKey: "movement") == nil {
            let movement = CAKeyframeAnimation(keyPath: "position")
            
            CATransaction.begin()
            
            CATransaction.setCompletionBlock({
                self.character.layer.position = self.pointFor(column: to.column, row: to.row)
                self.character.layer.removeAnimation(forKey: "movement")
                self.character.stopAnimating()
                
                self.modalWindowPresent()
            })
            
            movement.beginTime = CACurrentMediaTime() + delay
            movement.path = path.bezier.cgPath
            movement.fillMode = kCAFillModeForwards
            movement.isRemovedOnCompletion = false
            movement.duration = 0.35 * Double(path.count)
//            movement.rotationMode = kCAAnimationRotateAuto
            
            character.layer.add(movement, forKey: "movement")
            
            CATransaction.commit()
        }
    }
    
    /// Функция показывает модальное окно с информацией об уровне
    func modalWindowPresent() {
        // Добавляем бг, чтобы при клике на него закрыть всё модальное окно
        modalWindow = UIView(frame: scrollView.bounds)
        modalWindow.backgroundColor = UIColor.clear
        modalWindow.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.bgClick(_:))))
        modalWindow.isUserInteractionEnabled = true
        scrollView.addSubview(modalWindow)
        scrollView.isScrollEnabled = false
        
        // Добавляем модальное окно
        let levelInfoView = UIView(frame: CGRect(x: self.view.bounds.midX - 100, y: self.view.bounds.midY - 100, width: 200, height: 200))
        levelInfoView.backgroundColor = UIColor.blue
        levelInfoView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.bgClick(_:))))
        modalWindow.addSubview(levelInfoView)
        
        // Кнопка "старт" в модальном окне, которая переносит на выбранный уровень
        let btnStart = UIButton(frame: CGRect(x: levelInfoView.bounds.midX - 100 / 2, y: levelInfoView.bounds.midY - 100 / 2, width: 100, height: 100))
        btnStart.backgroundColor = UIColor.red
        btnStart.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi))
        btnStart.addTarget(self, action: #selector(startLevel), for: .touchUpInside)
        btnStart.setTitle("START", for: UIControlState.normal)
        levelInfoView.addSubview(btnStart)
    }
    
    @objc func startLevel() {
        self.goToLevel()
    }
    
    @objc func bgClick(_ sender: UITapGestureRecognizer) {
        if sender.view?.superview === scrollView {
            modalWindow.removeFromSuperview()
            scrollView.isScrollEnabled = true
        }
    }
    
    func goToLevel() {
        if Model.sharedInstance.getLevelLives(Model.sharedInstance.currentLevel) > 0 {
            if Model.sharedInstance.gameScene != nil {
                Model.sharedInstance.gameScene.cleanLevel()
                Model.sharedInstance.gameScene.createLevel()
                Model.sharedInstance.gameScene.startLevel()
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
                    // Переворачиваем кнопку, т. к. перевернул весь слой
                    button.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi))
                    
                    // Если уровень (который отображает кнопка) равен тому уровню, который был пройден последним, то запомнить координаты этой позиции, чтобы вывести туда персонажа
                    
                    let koefForLastLevel = (countLevels == countCompletedLevels) ? 0 : 1
                    
                    if row / distanceBetweenLevels + 1 == countCompletedLevels + koefForLastLevel {
                        characterPointStart = Point(column: randColumn, row: row + 1)
                    }
                    
                    if (row / distanceBetweenLevels) <= countCompletedLevels {
                        if Model.sharedInstance.emptySavedLevelsLives() == false {
                            if Model.sharedInstance.getLevelLives(row / distanceBetweenLevels + 1) <= 0 {
                                button.isEnabled = false
                                button.alpha = 0.5
                            }
                        }
                    }
                    else {
                        button.isEnabled = false
                        button.alpha = 0.5
                    }
                    
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
    
    /// При нажатии на Label "Back"
    @IBAction func goBack(sender: UIButton) {
        navigationController?.popViewController(animated: true)
        navigationController?.dismiss(animated: true, completion: nil)
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
}
