import Foundation
import SpriteKit


/// Enumeration, который определяет движения блока
enum RotationDirection: Int {
    case right = 0, top, left, bottom
    
    /// Свойство, которое вычисляет количество элементов в данном Enum
    static let count: Int = {
        var max: Int = 0
        
        while let _ = RotationDirection(rawValue: max) { max += 1 }
        
        return max
    }()
    
    /// Функция, которая возвращает следующее направление (против часовой стрелки)
    func nextPoint() -> RotationDirection {
        return RotationDirection(rawValue: (rawValue + 1) % RotationDirection.count)!
    }
}

enum LockKeyColor: Int {
    case red = 0, blue, green, yellow
}

/// Класс, который описывает основную механику перемещения статичного объекта
class StaticObject: SKSpriteNode {
    /// Тип блока
    var type: ObjectType!
    
    /// Точка, в которой блок находится
    var point: Point!
    
    /// Флаг, который указывает на активность блока
    var active: Bool = true
    
    /// Направление блока ("куда смотрит", по умолчания - наверх)
    var rotate: RotationDirection = RotationDirection.top
    
    /// Количество ходов до уничтожения (счетчик, который необходим для бомб)
    var movesToExplode: Int!
    
    /// Выдвинуты ли шипы или нет (флаг, который необходим для объекта "шип")
    var spikesActive = false
    
    /// Цвет ключа или замка
    var lockKeyColor: LockKeyColor!
    
    init(type: ObjectType, point: Point, size: CGSize) {
        let texture = SKTexture(imageNamed: type.spriteName)
        var size: CGFloat = 0.65
        
        switch type {
        case ObjectType.arrow, ObjectType.tulip, ObjectType.magnet:
            size = 0.5
        case ObjectType.star:
            size = 0.4
        case ObjectType.bomb:
            size = 0.625
        case ObjectType.alarmclock:
            size = 0.525
        case ObjectType.bridge:
            size = 0.7
        case ObjectType.spikes:
            size = 0.715
        case ObjectType.stopper:
            size = 0.75
        case ObjectType.cabbage:
            size = 0.35
        default:
            size = 0.65
        }
        
        super.init(texture: texture, color: UIColor.white, size: CGSize(width: TileWidth * size, height: texture.size().height / (texture.size().width / (TileWidth * size))))
        
        self.type = type
        self.point = point
        
        self.zPosition = 5
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setTexture(spriteName: String, size: CGSize?) {
        self.texture = SKTexture(imageNamed: spriteName)
        
        if size != nil {
            self.size = size!
        }
    }
    
}

