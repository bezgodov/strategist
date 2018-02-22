import Foundation
import SpriteKit

/// Класс, который описывает основную механику перемещения главного персонажа (ГП)
class Character: SKSpriteNode {
    
    /// Все ходы ГП
    var moves = [Point]()
    
    /// Node, который содержит UIBezier, которая отображает ходы объекта
    var pathNode = SKShapeNode()
    
    /// Функция, которая отрисовывает/скрывает траекторию перемещающегося объекта
    ///
    /// - Parameter hide: если true, то показаться траекторию
    func path(hide: Bool = false) {
        
        self.pathNode.removeFromParent()
        
        if !hide {
            if moves.count > 1 {
                let path = UIBezierPath()
                
                let firstPoint = Model.sharedInstance.gameScene.pointFor(column: moves[0].column, row: moves[0].row)
                path.move(to: firstPoint)
                
                for index in 0...moves.count - 1 {
                    let point = Model.sharedInstance.gameScene.pointFor(column: moves[index].column, row: moves[index].row)
                    path.addLine(to: point)
                }
                
                pathNode = SKShapeNode(path: path.cgPath)
                pathNode.strokeColor = UIColor.init(red: 139 / 255, green: 203 / 255, blue: 249 / 255, alpha: 1)
                pathNode.zPosition = 3
                pathNode.lineCap = CGLineCap.round
                pathNode.lineJoin = CGLineJoin.round
                pathNode.lineWidth = 9
                
                if Model.sharedInstance.isDeviceIpad() {
                    pathNode.lineWidth *= 2
                }
                
                Model.sharedInstance.gameScene.objectsLayer.addChild(pathNode)
            }
        }
    }
}
