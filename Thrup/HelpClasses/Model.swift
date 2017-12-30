import Foundation
import SpriteKit


/// Вспомогательный класс, в основном служит для соединения остальных классов
class Model {
    static let sharedInstance = Model()
    
    var gameViewControllerConnect: GameViewController!
    var gameScene: GameScene!
}
