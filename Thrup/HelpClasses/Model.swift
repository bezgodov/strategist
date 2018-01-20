import Foundation
import SpriteKit

class Model {
    init() {
        /// Получаем значения жизней на каждом уровне
        if let countLivesArr = UserDefaults.standard.array(forKey: "countLives") as? [Int] {
            countLives = countLivesArr
        }
        else {
            countLives = [Int]()
        }
        
        /// Получаем коказатели пройденности ан каждом уровне
        if let completedLevelsArr = UserDefaults.standard.array(forKey: "completedLevels") as? [Bool] {
            completedLevels = completedLevelsArr
        }
        else {
            completedLevels = [Bool]()
        }
    }
    
    static let sharedInstance = Model()
    var gameViewControllerConnect: GameViewController!
    var gameScene: GameScene!
    
    /// Общее количество уровней
    var countLevels: Int = 7
    
    /// Текущий уровень
    var currentLevel: Int = 1
    
    /// Количество пройденных уровней (последний пройденный уровень)
    private var countCompletedLevels: Int = UserDefaults.standard.integer(forKey: "countCompletedLevels")
    
    /// Массив, содержащий уровни, которые пройдены или нет
    private var completedLevels: [Bool]!
    
    /// Количество жизней на каждом уровне
    private var countLives: [Int]!
    
    /// Функция, которая проверяет наличие сохранённых данных
    func emptySavedLevelsLives() -> Bool {
        return countLives.isEmpty
    }
    
    /// Функция, которая возвращает количество жизней на уровне
    func getLevelLives(_ level: Int) -> Int {
        return (level - 1 < countLives.count) ? countLives[level - 1] : 0
    }
    
    /// Функция, которая изменяет значение количества жизней на уровне
    func setLevelLives(level: Int, newValue: Int = -1) {
        if level - 1 < countLives.count {
            countLives.remove(at: level - 1)
        }
        countLives.insert(newValue, at: level - 1)
        UserDefaults.standard.set(countLives, forKey: "countLives")
    }
    
    /// Функция вовразает кол-во пройденных уровней
    func getCountCompletedLevels() -> Int {
        return countCompletedLevels
    }
    
    /// Функция устанавливает последний пройденный уровень
    func setCountCompletedLevels(_ level: Int) {
        countCompletedLevels = level
        UserDefaults.standard.set(level, forKey: "countCompletedLevels")
    }
    
    /// Функция возвращает true or false выбранного уровня, true - если уровень уже был пройден
    func isCompletedLevel(_ level: Int) -> Bool {
        return (level - 1 < completedLevels.count) ? completedLevels[level - 1] : false
    }
    
    /// Функция задаёт значение для выбранного уровня: пройден или нет
    func setCompletedLevel(_ level: Int, value: Bool = true) {
        if level - 1 < completedLevels.count {
            completedLevels.remove(at: level - 1)
        }
        completedLevels.insert(value, at: level - 1)
        UserDefaults.standard.set(completedLevels, forKey: "completedLevels")
    }
}
