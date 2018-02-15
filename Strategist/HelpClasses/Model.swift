import Foundation
import SpriteKit

/// Цена в драг. камнях доп. жизни
let EXTRA_LIFE_PRICE = 10

/// Цена в драг. камнях выйгрышного пути
let WINNING_PATH_PRICE = 25

class Model {
    init() {
        // Получаем значения жизней на каждом уровне
        if let countLivesArr = UserDefaults.standard.array(forKey: "countLives") as? [Int] {
            countLives = countLivesArr
        }
        else {
            countLives = [Int]()
        }
        
        // Получаем коказатели пройденности ан каждом уровне
        if let completedLevelsArr = UserDefaults.standard.array(forKey: "completedLevels") as? [Bool] {
            completedLevels = completedLevelsArr
        }
        else {
            completedLevels = [Bool]()
        }
        
        // Получаем уровни, которые были пройдены с помощью кнопки "Help"
        if let levelsCompletedWithHelpArr = UserDefaults.standard.array(forKey: "levelsCompletedWithHelp") as? [Int] {
            levelsCompletedWithHelp = levelsCompletedWithHelpArr
        }
        else {
            levelsCompletedWithHelp = [Int]()
        }
        
        // Если нет сохранённых уровней, то задаём кол-во пройденных уровней равным 0 и показываем подсказки по умолчанию
        if emptySavedLevelsLives() == true {
            // Инициализируем все данные для уровней
            setCountCompletedLevels(0)
            setShowTips(val: true)
            setActivatedSounds(true)
            setActivatedBgMusic(true)
        }
        
        // Если были добавлены новые уровни (т.е. выделенное кол-во элементов в массиве для пройденных уровней не соответствует текущему кол-ву уровней)
        if countLevels > completedLevels.count {
            for index in completedLevels.count + 1...countLevels {
                setLevelLives(level: index, newValue: 5)
                setCompletedLevel(index, value: false)
                generateTilesPosition()
            }
        }
        
        currentLevel = getCountCompletedLevels() + 1
        
        if isActivatedBgMusic() {
            SKTAudio.sharedInstance().playBackgroundMusic(filename: "BgMusic.mp3")
        }
    }
    
    static let sharedInstance = Model()
    var gameViewControllerConnect: GameViewController!
    var gameScene: GameScene!
    
    /// Общее количество уровней
    var countLevels: Int = 16
    
    /// Текущий уровень
    var currentLevel: Int = 1
    
    /// Количество собранных драгоценных камней
    private var countGems: Int = UserDefaults.standard.integer(forKey: "countGems")
    
    /// Показывать ли подсказки при клике на объекты на сцене?
    private var showTips = UserDefaults.standard.bool(forKey: "showTips")
    
    /// Количество пройденных уровней (последний пройденный уровень)
    private var countCompletedLevels: Int = UserDefaults.standard.integer(forKey: "countCompletedLevels")
    
    /// Массив, содержащий уровни, которые пройдены или нет
    private var completedLevels: [Bool]!
    
    /// Количество жизней на каждом уровне
    private var countLives: [Int]!
    
    /// Массив, который содержит номера уровней, которые были пройдены с помощью кнопки "Help"
    private var levelsCompletedWithHelp: [Int]!
    
    /// Включены ли звуки
    private var isActivatedSoundsVal = UserDefaults.standard.bool(forKey: "isActivatedSounds")
    
    /// Включена ли музыка на заднем фоне
    private var isActivatedBgMusicVal = UserDefaults.standard.bool(forKey: "isActivatedBgMusic")
    
    /// Последняя позиция, на которой находился пользователь, когда заходил на уровень или в меню
    var lastYpositionLevels: CGFloat?
    
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
            countLives[level - 1] = newValue
        }
        else {
            countLives.append(newValue)
        }
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
            completedLevels[level - 1] = value
        }
        else {
            completedLevels.append(value)
        }
        UserDefaults.standard.set(completedLevels, forKey: "completedLevels")
    }
    
    /// Функция задаёт новое значение количества драгоценных камней
    ///
    /// - Parameter amountGems: значение, которое необходимо прибать к текущему кол-ву драг. камней
    func setCountGems(amountGems: Int) {
        countGems += amountGems
        
        UserDefaults.standard.set(countGems, forKey: "countGems")
    }
    
    /// Функция возвращает общее кол-во драгоценных камней
    func getCountGems() -> Int {
        return countGems
    }
    
    /// Функция, которая устанавливает флаг, которые отвечает за показ подсказок при клике на объекты
    func setShowTips(val: Bool) {
        showTips = val
        
        UserDefaults.standard.set(showTips, forKey: "showTips")
    }
    
    func getShowTips() -> Bool {
        return showTips
    }
    
    /// Запомнить уровень, который был пройден с помощью кнопки "Help"
    func setLevelsCompletedWithHelp(_ level: Int) {
        if !isLevelsCompletedWithHelp(level) {
            levelsCompletedWithHelp.append(level)
            UserDefaults.standard.set(levelsCompletedWithHelp, forKey: "levelsCompletedWithHelp")
        }
    }
    
    /// Если уровень был пройден с помощью кнопки "Help"
    func isLevelsCompletedWithHelp(_ level: Int) -> Bool {
        return levelsCompletedWithHelp.contains(level)
    }
    
    func setActivatedSounds(_ val: Bool) {
        isActivatedSoundsVal = val
        UserDefaults.standard.set(isActivatedSoundsVal, forKey: "isActivatedSounds")
    }
    
    func isActivatedSounds() -> Bool {
        return isActivatedSoundsVal
    }
    
    func setActivatedBgMusic(_ val: Bool) {
        isActivatedBgMusicVal = val
        UserDefaults.standard.set(isActivatedBgMusicVal, forKey: "isActivatedBgMusic")
        
        if !isActivatedBgMusic() {
            SKTAudio.sharedInstance().pauseBackgroundMusic()
        }
        else {
            if SKTAudio.sharedInstance().backgroundMusicPlayer != nil {
                SKTAudio.sharedInstance().resumeBackgroundMusic()
            }
            else {
                SKTAudio.sharedInstance().playBackgroundMusic(filename: "BgMusic.mp3")
            }
        }
    }
    
    func isActivatedBgMusic() -> Bool {
        return isActivatedBgMusicVal
    }
    
    /// Функцию генерирует случайную позицию для иконок уровней
    func generateTilesPosition() {
        var buttonsPositions = [Int]()
        
        if let buttonsPositionsArr = UserDefaults.standard.array(forKey: "levelsTilesPositions") as? [Int] {
            buttonsPositions = buttonsPositionsArr
        }
        
        let lastRandColumn = buttonsPositions.last
        
        var randColumn = Int(arc4random_uniform(3) + 1)
        
        if randColumn == lastRandColumn {
            if randColumn + 1 <= 3 {
                randColumn += 1
            }
            else {
                randColumn -= 1
            }
        }
        
        buttonsPositions.append(randColumn)
        
        UserDefaults.standard.set(buttonsPositions, forKey: "levelsTilesPositions")
    }
}
