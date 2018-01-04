import Foundation
import SpriteKit

extension GameScene {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let touchLocation = touch.location(in: objectsLayer)
            // Если не сделан ещё первый ход
            if move == 0 {
                let boardClick = convertPoint(point: touchLocation)
                // Если клик был сделан по игровому полю
                if boardClick.success {
                    // Сохраняем точку где был сделан первый клик, чтобы при Moved можно было удалять ходы в обратную сторону
                    checkChoosingPath = boardClick.point
                    // Сохраняем все уже выбранные ходы ГП, чтобы при Moved не удалить эти ходы
                    checkChoosingPathArray = character.moves
                }
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let touchLocation = touch.location(in: objectsLayer)
            
            if move == 0 {
                let boardClick = convertPoint(point: touchLocation)
                if boardClick.success {
                    // Если не исчерпали ещё все ходы
                    if moves > 0 {
                        // Если клик не был сделан по начальной точки ГП
                        if boardClick.point != characterStart {
                            // Если расстояние от последнего хода в траектории и нового хода равно 1 (принимает значение 1, когда новый блок находится строго сверху, справа, снизу или слева. В противном случае блок примет большее значение. Данная проверка запрещает ходы по вертикали)
                            if sqrt(pow(Double(character.moves.last!.column - boardClick.point.column), Double(2)) + pow(Double(character.moves.last!.row - boardClick.point.row), Double(2))) == 1 {
                                // Если точка ещё не находится в траектории (так как нельзя делать ход в поле, в которое уже был сделан ход заранее)
                                if !pointExists(points: character.moves, point: boardClick.point) {
                                    
                                    character.moves.append(boardClick.point)
                                    checkChoosingPath = boardClick.point
                                    checkChoosingPathArray = character.moves
                                    
                                    updateMoves(-1)
                                    character.path()
                                    
                                    // Так как мы начали строить траекторию ГП, то спрятать все траектории остальных объектов)
                                    for object in movingObjects {
                                        object.path(hide: true)
                                    }
                                    
                                    // Флаг, который указывает, что последний ход был сделан с помощью Move, но не с помощью Touched
                                    addedLastPointByMove = true
                                }
                            }
                        }
                    }
                    
                    // Следующие проверки предназначены для того, чтобы удостовериться, что позиция в траектории, которую уже выбрали для ГП существует
                    if checkChoosingPathArray.last != nil {
                        if checkChoosingPathArray.last! == checkChoosingPath {
                            if pointExists(points: character.moves, point: boardClick.point) {
                                if getMoveIndex(move: checkChoosingPath, moves: character.moves) - getMoveIndex(move: boardClick.point, moves: character.moves) == 1 {
                                    
                                    character.moves.remove(at: character.moves.count - 1)
                                    checkChoosingPathArray.removeLast()
                                    checkChoosingPath = character.moves[character.moves.count - 1]
                                    
                                    updateMoves(1)
                                    character.path()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            if move == 0 {
                let touchLocation = touch.location(in: objectsLayer)
                let boardClick = convertPoint(point: touchLocation)
                
                if boardClick.success {
                    if character.moves.count == 1 {
                        for object in movingObjects {
                            // Если клик был сделан по перемещающемуся объекту, то показываем его траекторию
                            if object.getPoint() == boardClick.point {
                                if object.pathLayer.parent != nil {
                                    object.path(hide: true)
                                }
                                else {
                                    object.path()
                                }
                            }
                            else {
                                object.path(hide: true)
                            }
                        }
                        
                        for object in staticObjects {
                            // Если клик был сделан по статичному объекту
                            if boardClick.point == object.point {
                                // Если клик был сделан по объекту "мост", то поворачиваем на 90 deg.
                                if object.type == ObjectType.bridge {
                                    if object.active {
                                        object.active = false
                                        object.run(SKAction.rotate(toAngle: object.zRotation - CGFloat(90 * Double.pi / 180), duration: 0.5), completion: {
                                            object.active = true
                                            object.rotate = object.rotate.nextPoint()
                                        })
                                    }
                                }
                            }
                        }
                    }
                    
                    if boardClick.point != characterStart {
                        // Если Touch был отпущен на поле, на которое первоначально и нажимали, то есть перемещения не было
                        if boardClick.point == checkChoosingPath {
                            // Если расстояние от последнего хода в траектории и нового хода равно 1 (принимает значение 1, когда новый блок находится строго сверху, справа, снизу или слева. В противном случае блок примет большее значение. Данная проверка запрещает ходы по вертикали)
                            if sqrt(pow(Double(character.moves.last!.column - boardClick.point.column), Double(2)) + pow(Double(character.moves.last!.row - boardClick.point.row), Double(2))) == 1 {
                                // Если не исчерпали ещё все ходы
                                if moves > 0 {
                                    // Если ещё не добавляли эту позицию в траеткорию
                                    if !pointExists(points: character.moves, point: boardClick.point) {
                                        character.moves.append(boardClick.point)
                                        
                                        updateMoves(-1)
                                        character.path()
                                        
                                        // Так как мы начали строить траекторию ГП, то спрятать все траектории остальных объектов)
                                        for object in movingObjects {
                                            object.path(hide: true)
                                        }
                                    }
                                }
                            }
                            // Если расстояние не равно 1, то есть новая позиция в траектории не находится справа, сверху, слева или снизу от последней точки траектории
                            else {
                                //Если новая позиция не равна последней позиции в существующей траектории и TouchedMoved не был вызван после TouchedMoved
                                if boardClick.point == character.moves.last! && !addedLastPointByMove {
                                    character.moves.remove(at: character.moves.count - 1)
                                    
                                    updateMoves(1)
                                    character.path()
                                }
                            }
                        }
                    }
                }
            }
        }
        addedLastPointByMove = false
    }
}
