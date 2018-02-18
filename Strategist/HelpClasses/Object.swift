import Foundation
import SpriteKit

/// Enumeration для перемещающихся объектов
///
/// - unknown: неизвестный объект
/// - bee: пчела, которая уничтожает ГП, если оба находятся на одной поле;
/// - spinner: объект, который не перемещается, если ГП попадает на его позицию, то ГП погибает;
/// - bomb: бомба, которая уничтожает ГП, если тот попадает в радиус вокруг бомбы;
/// - stopper: остановщик, который останавливает ГП на 1 ход;
/// - alarmclock: будильник, который останавливает все объекты на игровом поле кроме ГП
/// - bridge: мост, который вращается каждый ход. При несоответствии траекторий ГП погибает;
/// - spikes: шипы - блок, который попеременно вытаскивает и убирает шипы вокруг себя (ортогонально), каждое действие за один ход
/// - electric: электрический блок, который уничтожает ГП, если тот попадает в радиус вокруг блока;
/// - star: звезда, которую ГП должен собрать. Если ГП не собрал все звёзды за уровень, то он погибает;
/// - rotator: поворот (неготовый блок);
/// - rotatorPointer: поворот со стрелкой (неготовый блок);
enum ObjectType: Int {
    case unknown = 0, spaceAlien, gem, bee, spinner, bomb, stopper, alarmclock, bridge, spikes, electric, star, snail
    
    /// Свойство для получения имя спрайта перемещающегося блока;
    var spriteName: String {
        let spriteNames = [
            "PlayerStaysFront",
            "Gem_blue",
            "Bee",
            "Spinner",
            "Bomb",
            "StopSign",
            "AlarmClock",
            "Bridge",
            "SpikesBox",
            "Donut",
            "Star",
            "Snail"
        ]
        
        return spriteNames[rawValue - 1]
    }
    
    /// Описание объекта
    var description: String {
        let descriptions = [
            "A cute space alien",
            "You should pick up a gem to win. Space aliens need much gems",
            "Bee moves one cell by one game's move. If your and bee's positions are same you lose",
            "Spinner never changes its position. If you get at spinner's position you lose",
            "Bomb will destroy you if you are around its in N moves. You can't get at bomb's position",
            "Stop sing stops you for one move",
            "Alarm Clock stops all objects for one move except a space alien",
            "Bridge is rotated each move. You can tap bridge to change its direction",
            "Spikes appear one move and disappear next one. If you get at them you lose",
            "Eletro destroys you if you get at any position around its",
            "Star doesn't destroy you and never moves. You should collect all stars to win",
            "Snail moves one move per two game's moves. Alarmclock can cause double freeze"
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
            case ObjectType.bee:
                size = 0.65
            case ObjectType.snail:
                size = 0.75
            default:
                size = 0.65
        }
        
        super.init(texture: texture, color: UIColor.white, size: CGSize(width: TileWidth * size, height: texture.size().height / (texture.size().width / (TileWidth * size))))
        
        self.type = type
        self.zPosition = 7
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
        
        pathLayer.run(SKAction.fadeOut(withDuration: 0.25), completion: {
            self.pathLayer.removeFromParent()
        })
        
        if !hide {
            
            let path = UIBezierPath()
            
            let firstPoint = Model.sharedInstance.gameScene.pointFor(column: moves[move].column, row: moves[move].row)

            path.move(to: firstPoint)
            
            for index in move + 1...moves.count - 1 {
                let point = Model.sharedInstance.gameScene.pointFor(column: moves[index].column, row: moves[index].row)
                path.addLine(to: CGPoint(x: point.x, y: point.y))
            }
            
            pathLayer = SKShapeNode(path: path.cgPath)
            pathLayer.strokeColor = UIColor.init(red: 250 / 255, green: 153 / 255, blue: 137 / 255, alpha: 1)
            pathLayer.lineWidth = 9
            pathLayer.lineCap = CGLineCap.round
            pathLayer.lineJoin = CGLineJoin.round
            pathLayer.fillColor = UIColor.clear
            pathLayer.zPosition = 3
            pathLayer.alpha = 0.0
            pathLayer.run(SKAction.fadeIn(withDuration: 0.5))
            Model.sharedInstance.gameScene.objectsLayer.addChild(pathLayer)
        }
    }
}
