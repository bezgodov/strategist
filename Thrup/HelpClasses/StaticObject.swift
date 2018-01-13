import Foundation
import SpriteKit


/// Enumeration, который определяет содержит движения блока
enum RotationDirection: Int {
    case right = 0, top, left, bottom
    
    /// Свойство, которое содержит количество элементов в данном Enum
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
    
    init(type: ObjectType, point: Point, size: CGSize) {
        let texture = SKTexture(imageNamed: type.spriteName)
        var size: CGFloat = 0.65
        
        switch type {
        case ObjectType.star:
            size = 0.5
        case ObjectType.bomb:
            size = 0.5
        default:
            size = 0.65
        }
        
        super.init(texture: texture, color: UIColor.white, size: CGSize(width: TileWidth * size, height: texture.size().height / (texture.size().width / (TileWidth * size))))
        
        self.type = type
        self.point = point
        
        self.zPosition = 2
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

