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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        menuSettings()
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
    }
    
    override func viewDidLayoutSubviews() {
        // Тут костыль: почему-то было сложно сделать scroll снизу вверх, то просто перевернул на 180 слой, а потом все кнопки тоже на 180
        scrollView.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi))
        
        scrollView.contentSize = CGSize(width: self.view.bounds.width, height: CGFloat((countCompletedLevels + distanceBetweenLevels + extraCountForExtremeLevels) * distanceBetweenLevels) * levelTileSize.height)
        scrollView.contentOffset.y = CGFloat((countCompletedLevels + ((countLevels - countCompletedLevels < distanceBetweenLevels) ? extraCountForExtremeLevels : 0)) * distanceBetweenLevels) * levelTileSize.height
        
        scrollView.contentInset = UIEdgeInsets.zero
        scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentBehavior.never
        scrollView.scrollIndicatorInsets = UIEdgeInsets.zero
        
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = false
        
    }
    
//    @IBAction func chooseLevel(sender: UIButton) {
//
//    }
    
    @objc func buttonAction(sender: UIButton!) {
        let buttonSenderAction: UIButton = sender
        
        Model.sharedInstance.currentLevel = buttonSenderAction.tag
        
        if Model.sharedInstance.getLevelLives(Model.sharedInstance.currentLevel) > 0 {
            if let storyboard = storyboard {
                let gameViewController = storyboard.instantiateViewController(withIdentifier: "GameViewController") as! GameViewController
                navigationController?.pushViewController(gameViewController, animated: true)
            }
            
            if Model.sharedInstance.gameScene != nil {
                Model.sharedInstance.gameScene.cleanLevel()
                Model.sharedInstance.gameScene.createLevel()
                Model.sharedInstance.gameScene.startLevel()
            }
        }
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
                    button.setTitle("\(row / distanceBetweenLevels + 1)", for: UIControlState.normal)
                    button.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
                    button.tag = row / distanceBetweenLevels + 1
                    // Переворачиваем кнопку, т. к. перевернул весь слой
                    button.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi))
                    
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
    
    /// При нажатии на Label "Back"
    @IBAction func goBack(sender: UIButton) {
        navigationController?.popViewController(animated: true)
        navigationController?.dismiss(animated: true, completion: nil)
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
}
