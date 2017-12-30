import Foundation
import SpriteKit


/// Вспомогательный класс, в основном служит для соединения остальных классов
class Model {
    static let sharedInstance = Model()
    
    var gameViewControllerConnect: GameViewController!
    var gameScene: GameScene!
    
    var countLevels: Int = 5
    var countCompletedLevels: Int = UserDefaults.standard.integer(forKey: "countCompletedLevels")
    var currentLevel: Int = 1
    
    var countLives = UserDefaults.standard.dictionary(forKey: "countLives") as? [String: Int] ?? nil
}
