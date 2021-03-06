import Foundation
import SpriteKit

extension GameScene {
    
    // Функция, которая считывает JSON с текущего уровня
    func goToLevel(_ level: Int) {
        
        guard let dictionary = Dictionary<String, AnyObject>.loadJSONFromBundle(filename: "Level_\(level)") else { return }
        
        let movingObjects = dictionary["movingObjects"] as? NSArray
        
        let staticObjects = dictionary["staticObjects"] as? NSArray
        
        /// Позиция финишного блока
        guard let finishVal = dictionary["finish"] as? [Int] else { return }
        
        /// Начальная позиция ГП
        guard let characterStartVal = dictionary["character"] as? [Int] else { return }
        
        /// Размеры игрового поля
        guard let boardSizeVal = dictionary["boardSize"] as? [Int] else { return }
        
        /// Количество ходов на уровень
        guard let movesVal = dictionary["moves"] as? Int else { return }
        
        /// Обязательно ли использовать все ходы на уровне?
        let isNecessaryUseAllMovesVal = dictionary["isNecessaryUseAllMoves"] as? Bool
        
        /// Количество драгоценных камней, которые можно получить за уровень
        let gemsForLevelVal = dictionary["gems"] as? Int
        
        /// Если вначале уровня необходимо показать обучение
        let isLevelWithTutorialVal = dictionary["isLevelWithTutorial"] as? Bool
        
        /// Путь, с помощью которого можно пройти уровень
        let winningPathVal = dictionary["winningPath"] as? [[Int]]
        
        /// Кол-во звёзд, которые необходимо собрать на последнем уровне в секции
        let bossLevelStarsVal = dictionary["bossLevelStars"] as? Int
        
        // Размер игрового поля
        boardSize = Point(column: boardSizeVal[0], row: boardSizeVal[1])
        
        // Координаты финишного блока
        finish = Point(column: finishVal[0], row: finishVal[1])
        /*
        assert(finish.column >= 0 && finish.column < boardSize.column, "Finish is out of board")
        assert(finish.row >= 0 && finish.row < boardSize.row, "Finish is out of board")
        */
        // Первоначальные координаты ГП
        characterStart = Point(column: characterStartVal[0], row: characterStartVal[1])
        assert(characterStart.column >= 0 && characterStart.column < boardSize.column, "Character startPos is out of board")
        assert(characterStart.row >= 0 && characterStart.row < boardSize.row, "Character startPos is out of board")
        
        // Ширина игровой клетки
        TileWidth = self.frame.width / CGFloat(boardSize.column)
        TileHeight = TileWidth
        
        // Кол-во ходов, за которые необходимо выиграть уровень
        moves = movesVal
        
        // Устанавливаем кол-во звёзд в label (т.к он не используется), которые необходимо собрать на последнем уровне в секции
        if bossLevelStarsVal != nil {
            moves = bossLevelStarsVal ?? 10
        }
        
        if isNecessaryUseAllMovesVal != nil {
            isNecessaryUseAllMoves = isNecessaryUseAllMovesVal!
        }
        
        if gemsForLevelVal != nil {
            gemsForLevel = gemsForLevelVal!
        }
        
        if isLevelWithTutorialVal != nil {
            isLevelWithTutorial = isLevelWithTutorialVal!
        }
        
        if winningPathVal != nil {
            // Если уже был куплен выйгрышный путь, то сначала очистим его
            if !winningPath.isEmpty {
                winningPath.removeAll()
            }
            
            winningPath.append(characterStart)
            
            for pointsForPoint in winningPathVal! {
                let point = Point(column: pointsForPoint[0], row: pointsForPoint[1])
                winningPath.append(point)
            }
        }
        
        Model.sharedInstance.gameViewControllerConnect.movesRemainLabel.text = String(moves)
        
        // Если есть хотя бы один перемещающийся объект
        if movingObjects != nil {
            for object in movingObjects! {
                if let object = object as? [String: AnyObject] {
                    
                    let type = ObjectType.enumFromString(string: object["type"] as! String)
                    
                    var moves = [Point]()
                    
                    guard let movement = object["move"] as? [[Int]] else { return }
                    
                    for step in movement {
                        assert(step[0] >= 0 && step[0] < boardSize.column, "Object is out of board")
                        assert(step[1] >= 0 && step[1] < boardSize.row, "Object is out of board")
                        moves.append(Point(column: step[0], row: step[1]))
                    }
                    
                    let newObj = Object(type: type!)
                    newObj.moves = moves
                    
                    self.movingObjects.insert(newObj)
                }
            }
        }
        
        // Если есть хотя бы один статичный объект
        if staticObjects != nil {
            for object in staticObjects! {
                if let object = object as? [String: AnyObject] {
                    
                    let type = ObjectType.enumFromString(string: object["type"] as! String)
                    
                    guard let pointVal = object["point"] as? [Int] else { return }
                    
                    let point = Point(column: pointVal[0], row: pointVal[1])
                    
                    let newObj = StaticObject(type: type!, point: point, size: CGSize(width: TileWidth, height: TileHeight))
                    
                    // Если объект "бомба", то считываем кол-во ходов до взрыва
                    if type == ObjectType.bomb {
                        let movesToExplode = object["movesToExplode"] as? Int
                        newObj.movesToExplode = movesToExplode
                    }
                    
                    // Если объект "мост" или "стрелка", то считываем направление его или ставим по умолчанию (top)
                    if type == ObjectType.bridge || type == ObjectType.arrow {
                        let rotate = object["rotate"] as? Int
                        
                        if rotate != nil && rotate! < 4 {
                            newObj.rotate = RotationDirection(rawValue: rotate!)!
                        }
                        else {
                            // Устанавливаем случайные поворот моста на уровень
                            let randomAngle = arc4random_uniform(4)
                            newObj.rotate = RotationDirection(rawValue: Int(randomAngle))!
                        }
                    }
                    
                    if type == ObjectType.spikes {
                        let spikesActive = object["spikesActive"] as? Bool
                        
                        newObj.spikesActive = spikesActive == nil ? false : spikesActive!
                    }
                    
                    // Если объект "звезда", то увеличиваем кол-во звёзд, которые необходимо собрать на уровне
                    if type == ObjectType.star {
                        stars += 1
                    }
                    
                    if type == ObjectType.lock || type == ObjectType.key {
                        let lockKeyColor = object["color"] as? Int
                        newObj.lockKeyColor = LockKeyColor(rawValue: lockKeyColor!)
                        
                        let color = newObj.lockKeyColor!
                        
                        if type == ObjectType.lock {
                            newObj.setTexture(spriteName: "Lock_\(color)", size: CGSize(width: TileWidth * 0.7, height: TileHeight * 0.7))
                        }
                        else {
                            newObj.setTexture(spriteName: "Key_\(color)", size: nil)
                        }
                    }
                    
                    if type == ObjectType.button {
                        let isPressed = object["isPressed"] as? Bool
                        newObj.active = isPressed!
                        
                        let buttonColor = object["color"] as? Int
                        newObj.lockKeyColor = LockKeyColor(rawValue: buttonColor!)
                        
                        let color = newObj.lockKeyColor!
                        
                        if isPressed! {
                            newObj.setTexture(spriteName: "Button_\(color)_pressed", size: nil)
                        }
                        else {
                            newObj.setTexture(spriteName: "Button_\(color)", size: nil)
                        }
                    }
                    
                    self.staticObjects.insert(newObj)
                }
            }
        }
    }
}
