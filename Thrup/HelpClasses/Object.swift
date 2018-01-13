import Foundation
import SpriteKit

/// Enumeration для перемещающихся объектов
///
/// - unknown: неизвестный объект
/// - bee: пчела, которая уничтожает ГП, если оба находятся на одной поле;
/// - spinner: объект, который не перемещается, если ГП попадает на его позицию, то ГП погибает;
/// - bomb: бомба, которая уничтожает ГП, если тот попадает в радиус вокруг бомбы;
/// - stopper: остановщик, который останавливает ГП на 1 ход;
/// - accelerator: ускоритель, который перекидывает ГП на клетку, которая находится после ускорителя по траектории ГП (2 хода за 1);
/// - bridge: мост, который вращается каждый ход. При несоответствии траекторий ГП погибает;
/// - electric: электрический блок, который уничтожает ГП, если тот попадает в радиус вокруг блока;
/// - star: звезда, которую ГП должен собрать. Если ГП не собрал все звёзды за уровень, то он погибает;
/// - rotator: поворот (неготовый блок);
/// - rotatorPointer: поворот со стрелкой (неготовый блок);
enum ObjectType: Int {
    case unknown = 0, spaceAlien, gem, bee, spinner, bomb, stopper, accelerator, bridge, electric, star, rotator, rotatorPointer
    
    /// Свойство для получения имя спрайта перемещающегося блока;
    var spriteName: String {
        let spriteNames = [
            "PlayerStaysFront",
            "Gem_blue",
            "Bee",
            "Spinner",
            "Bomb",
            "StopSign",
            "Accelerator",
            "Stopper",
            "Donut",
            "Star",
            "Rotator",
            "Rotator"
        ]
        
        return spriteNames[rawValue - 1]
    }
    
    /// Описание объекта
    var description: String {
        let descriptions = [
            "A cute space alien",
            "You should pick up a gem to win. Space aliens like gems",
            "Bee moves one cell by one game's move. If your and bee's positions are same you lose",
            "Spinner never changes its position. If you get at spinner's position you lose",
            "Bomb will destroy everything around its in N moves. You can't get at bomb's position",
            "Stop sing stops you for one move",
            "Accelerator pushes you through one cell",
            "Bridge",
            "Eletro destroys you if you get at any position around its",
            "Star doesn't destroy you and never moves. You should collect all stars to win",
            "Rotator"
        ]
        
        return rawValue <= descriptions.count ? descriptions[rawValue - 1] : "No description"
    }
    
    /// Приведение к типу ObjectType из строки
    static func enumFromString(string: String) -> ObjectType? {
        var i = 0
        while let item = ObjectType(rawValue: i) {
            if String(describing: item) == string { return item }
            i += 1
        }
        return nil
    }
    
    /// Спрайт для выделенного объекта
    var highlightedSpriteName: String {
        return spriteName + "-Highlighted"
    }
}

/// Класс, который описывает основную механику перемещения перемещающегося объекта
class Object: SKSpriteNode {

    /// Тип блока
    var type: ObjectType!
    
    /// Текущий ход для перемещающегося объекта
    var move: Int = 0
    
    /// Массив всех ходов перемещающегося объекта
    var moves: [Point]!
    
    /// Флаг, который указывает в какую сторону движется объект. true - по возрастанию (от 0 до n)
    var countMovesAsc: Bool = true
    
    /// Node, который содержит UIBezier, которая отображает ходы объекта
    var pathLayer = SKShapeNode()
    
    init(type: ObjectType) {
        let texture = SKTexture(imageNamed: type.spriteName)
        
        var size: CGFloat = 0.65
        
        switch type {
        case ObjectType.star:
            size = 0.5
        default:
            size = 0.65
        }
        
        super.init(texture: texture, color: UIColor.white, size: CGSize(width: TileWidth * size, height: texture.size().height / (texture.size().width / (TileWidth * size))))
        
        self.type = type
        self.zPosition = 3
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// Функция, которая увеличивает/уменьшает текущий ход
    func setPoint() {
        if moves.count > 1 {
            if move == 0 {
                countMovesAsc = true
            }
        
            if move == moves.count - 1 {
                countMovesAsc = false
            }
        
            if countMovesAsc {
                move += 1
            }
            else {
                move -= 1
            }
        }
    }
    
    /// Функция, которая получает координаты текущего хода объекта
    func getPoint() -> Point {
        return moves[move]
    }
    
    /// Функция, которая отрисовывает/скрывает траекторию перемещающегося объекта
    ///
    /// - Parameter hide: если true, то показаться траекторию
    func path(hide: Bool = false) {
        
        pathLayer.run(SKAction.fadeOut(withDuration: 0.5), completion: {
            self.pathLayer.removeFromParent()
        })
        
        /*
        // На стеке говорят, что нельзя CALayer засунуть ниже/между объектами, не вижу причии им не верить, но ход пока оставлю, мало ли
         
        if hide {
            pathStateHide = true
            
            let pathRemoveAnimation = CABasicAnimation(keyPath: "strokeEnd")
//            pathRemoveAnimation.fromValue = 1.0
            pathRemoveAnimation.toValue = 0.0
            pathRemoveAnimation.duration = 0.25
            pathRemoveAnimation.repeatCount = 1
            pathRemoveAnimation.fillMode = kCAFillModeForwards
            pathRemoveAnimation.isRemovedOnCompletion = false
            pathRemoveAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
            pathLayer.add(pathRemoveAnimation, forKey: nil)
        }
        */
        
        if !hide {
            
            let path = UIBezierPath()
            
            let firstPoint = Model.sharedInstance.gameScene.pointFor(column: moves[move].column, row: moves[move].row)

            path.move(to: firstPoint)
            
            for index in move + 1...moves.count - 1 {
                let point = Model.sharedInstance.gameScene.pointFor(column: moves[index].column, row: moves[index].row)
                path.addLine(to: CGPoint(x: point.x, y: point.y))
            }
            
            pathLayer = SKShapeNode(path: path.cgPath)
            pathLayer.strokeColor = UIColor.red
            pathLayer.lineWidth = 18
            pathLayer.lineCap = CGLineCap.round
            pathLayer.lineJoin = CGLineJoin.round
            pathLayer.fillColor = UIColor.clear
            pathLayer.zPosition = 2
            pathLayer.alpha = 0.0
            pathLayer.run(SKAction.fadeIn(withDuration: 0.5))
            Model.sharedInstance.gameScene.objectsLayer.addChild(pathLayer)
            
            /*
            pathLayer.removeAllAnimations()
            pathLayer.removeFromSuperlayer()
            
            pathLayer = CAShapeLayer()
            pathLayer.zPosition = 0
            
            pathLayer.strokeEnd = 0.0
            
            pathLayer.frame = CGRect(x: 0, y: 0, width: (Model.sharedInstance.gameScene.view?.frame.width)!, height: (Model.sharedInstance.gameScene.view?.frame.height)!)
            
            pathLayer.path = path.cgPath
            pathLayer.anchorPoint = CGPoint(x: 0, y: 0)
            pathLayer.lineWidth = 10
            pathLayer.strokeColor = UIColor.red.cgColor
            pathLayer.fillColor = nil
            pathLayer.lineJoin = kCALineJoinRound
            
            Model.sharedInstance.gameScene.view?.layer.addSublayer(pathLayer)
            
            let pathAnimation = CABasicAnimation(keyPath: "strokeEnd")
            pathAnimation.fromValue = 0.0
            pathAnimation.toValue = 1.0
            pathAnimation.duration = 0.25
            pathAnimation.repeatCount = 1
            pathAnimation.fillMode = kCAFillModeForwards
            pathAnimation.isRemovedOnCompletion = false
            pathAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
            
            pathLayer.add(pathAnimation, forKey: nil)
            */
        }
    }
    
//    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//        if let touch = touches.first {
//            let touchLocation = touch.location(in: Model.sharedInstance.gameScene!)
//        }
//    }
//
//    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
//        if let touch = touches.first {
//            let touchLocation = touch.location(in: Model.sharedInstance.gameScene!)
//
//        }
//    }
//
//    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
//        if let touch = touches.first {
//        }
//    }
}
