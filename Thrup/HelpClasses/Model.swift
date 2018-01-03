import Foundation
import SpriteKit

class Model {
    init() {
        if let arr = UserDefaults.standard.array(forKey: "countLives") as? [Int] {
            countLives = arr
        }
        else {
            countLives = [Int]()
        }
    }
    
    static let sharedInstance = Model()
    var gameViewControllerConnect: GameViewController!
    var gameScene: GameScene!
    
    /// Общее количество уровней
    var countLevels: Int = 5
    
    /// Текущий уровень
    var currentLevel: Int = 1
    
    /// Количество пройденных уровней (последний пройденный уровень)
    private var countCompletedLevels: Int = UserDefaults.standard.integer(forKey: "countCompletedLevels")
    
    /// Количество жизней на каждом уровне
    private var countLives: [Int]!
    
    /// Функция, которая проверяет наличие сохранённых данных
    func emptySavedLevelsLives() -> Bool {
        return countLives.isEmpty
    }
    
    /// Функция, которая возвращает количество жизней на уровне
    func getLevelLives(_ level: Int) -> Int {
        return countLives[level - 1]
    }
    
    /// Функция, которая изменяет значение количества жизней на уровне
    func setLevelLives(level: Int, newValue: Int = -1) {
        countLives.remove(at: level - 1)
        countLives.insert(newValue, at: level - 1)
        UserDefaults.standard.set(countLives, forKey: "countLives")
    }
    
    func getCountCompletedLevels() -> Int {
        return countCompletedLevels
    }
    
    func setCountCompletedLevels(_ level: Int) {
        countCompletedLevels = level
        UserDefaults.standard.set(level, forKey: "countCompletedLevels")
    }
}
