import Foundation
import SpriteKit

extension GameScene {
    func alphaBlackLayerPresent(alpha: CGFloat = 0.5) {
        mainBgTutorial = UIView(frame: CGRect(x: 0, y: 0, width: self.view!.frame.width, height: self.view!.frame.height))
        mainBgTutorial.tag = 0
        mainBgTutorial.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(mainBgClick(_:))))
        self.view!.addSubview(mainBgTutorial)
        
        let bgView = UIView(frame: CGRect(x: 0, y: 0, width: self.view!.frame.width, height: self.view!.frame.height))
        bgView.alpha = alpha
        bgView.backgroundColor = UIColor.black
        mainBgTutorial.addSubview(bgView)
        
        let tapIcon = UIImageView(frame: CGRect(x: mainBgTutorial.frame.maxX, y: 0, width: 42, height: 42))
        tapIcon.image = UIImage(named: "Tap")
        tapIcon.restorationIdentifier = "tapIcon"
        mainBgTutorial.addSubview(tapIcon)
        
        nextSlideInfo(slide: 0, sender: nil)
    }
    
    func getRectFromPoint(point: Point) -> CGRect {
        
        var pointConvertedForBoard = self.pointFor(column: point.column, row: point.row)
        
        pointConvertedForBoard.x += self.objectsLayer.position.x
        pointConvertedForBoard.y += self.objectsLayer.position.y
        
        let nextPointForSize = self.convertPoint(toView: CGPoint(x: pointConvertedForBoard.x + TileWidth, y: pointConvertedForBoard.y + TileHeight))
        
        let pointForBoard = Model.sharedInstance.gameScene.convertPoint(toView: pointConvertedForBoard)
        
        let size = CGSize(width: nextPointForSize.x - pointForBoard.x, height: pointForBoard.y - nextPointForSize.y)
        
        return CGRect(x: pointForBoard.x - size.width / 2, y: pointForBoard.y - size.height / 2, width: size.width, height: size.height)
    }
    
    func checkIfClickInsideRect(point: CGPoint, rect: CGRect) -> Bool {
        if point.x >= rect.origin.x && point.x <= (rect.origin.x + rect.size.width) &&
            point.y >= rect.origin.y && point.y <= (rect.origin.y + rect.size.height) {
            return true
        }
        else {
            return false
        }
    }
    
    func getTapPoints(index: Int) -> [Int: CGRect] {
        let tapPoints =
            [
                1:
                    [
                        2: getRectFromPoint(point: Point(column: 1, row: 1)),
                        3: getRectFromPoint(point: Point(column: 2, row: 1)),
                        4: getRectFromPoint(point: Point(column: 2, row: 2)),
                        5: CGRect(x: Model.sharedInstance.gameViewControllerConnect.startLevel.frame.origin.x, y: Model.sharedInstance.gameViewControllerConnect.startLevel.frame.origin.y, width: Model.sharedInstance.gameViewControllerConnect.startLevel.frame.size.width, height: Model.sharedInstance.gameViewControllerConnect.startLevel.frame.size.height - 7),
                        6: CGRect(x: self.view!.bounds.midX - 200 / 2 + 20, y: self.view!.bounds.midY - 200 / 2 + 75, width: 160, height: 50),
                        7: getRectFromPoint(point: Point(column: 2, row: 0)),
                        9: getRectFromPoint(point: Point(column: 0, row: 0)),
                        10: getRectFromPoint(point: Point(column: 1, row: 0)),
                        11: getRectFromPoint(point: Point(column: 2, row: 0)),
                        12: getRectFromPoint(point: Point(column: 2, row: 1)),
                        13: getRectFromPoint(point: Point(column: 2, row: 2)),
                        14: CGRect(x: Model.sharedInstance.gameViewControllerConnect.startLevel.frame.origin.x, y: Model.sharedInstance.gameViewControllerConnect.startLevel.frame.origin.y, width: Model.sharedInstance.gameViewControllerConnect.startLevel.frame.size.width, height: Model.sharedInstance.gameViewControllerConnect.startLevel.frame.size.height - 7)
                    ],
                2:
                    [
                        3: getRectFromPoint(point: Point(column: 1, row: 3)),
                    ],
                3:
                    [
                        1: CGRect(x: Model.sharedInstance.gameViewControllerConnect.startLevel.frame.origin.x, y: Model.sharedInstance.gameViewControllerConnect.startLevel.frame.origin.y, width: Model.sharedInstance.gameViewControllerConnect.startLevel.frame.size.width, height: Model.sharedInstance.gameViewControllerConnect.startLevel.frame.size.height - 7)
                    ],
                4:
                    [
                        0: self.view!.bounds
                    ],
                5:
                    [
                        0: self.view!.bounds
                    ],
                6:
                    [
                        0: self.view!.bounds
                    ],
                7:
                    [
                        0: self.view!.bounds
                    ],
                14:
                    [
                        0: self.view!.bounds
                    ],
                16: [
                        0: self.view!.bounds,
                        1: self.view!.bounds,
                        2: self.view!.bounds
                    ]
            ]
        
        return tapPoints[index]!
    }
    
    @objc func mainBgClick(_ sender: UITapGestureRecognizer) {
        let slideIndex = sender.view!.tag
        
        let tapPoints = getTapPoints(index: Model.sharedInstance.currentLevel)
        
            if sender.view?.superview === self.view {
                
            let tapLocationPos = sender.location(in: sender.view!)
                if tapPoints.index(forKey: slideIndex) != nil {
                    if checkIfClickInsideRect(point: tapLocationPos, rect: tapPoints[slideIndex]!) {
                    sender.view!.tag += 1
                    
                    if sender.view!.tag == 6 || sender.view!.tag == 8 {
                        for tapIconView in sender.view!.subviews {
                            if tapIconView.restorationIdentifier == "tapIcon" {
                                tapIconView.frame.origin = CGPoint(x: sender.view!.frame.maxX, y: 0)
                            }
                        }
                    }
                    
                    if sender.view!.tag == 6 {
                        removeObjectInfoView(toAlpha: 1)
                        self.extraActionForSlide(slide: slideIndex)
                        
                        DispatchQueue.main.async {
                            Timer.scheduledTimer(withTimeInterval: 1.25, repeats: false, block: { _ in
                                self.nextSlideInfo(slide: sender.view!.tag, sender: sender)
                            })
                        }
                    }
                    else {
                        extraActionForSlide(slide: slideIndex)
                        nextSlideInfo(slide: sender.view!.tag, sender: sender)
                    }
                }
            }
            else {
                sender.view!.tag += 1
                extraActionForSlide(slide: slideIndex)
                nextSlideInfo(slide: sender.view!.tag, sender: sender)
            }
        }
    }
    
    func nextSlideInfo(slide: Int, sender: UITapGestureRecognizer?) {
        
        let infoBlockTutorial: [Int: [String]] =
        [
            1:
                [
                "Hi. You have just got a promotion, now you are a STRATEGIST... [Tap somewhere to continue]",
                "Your main role is managing ordinary space alients and help them collecting gems. Let's begin!",
                "First click at the middle cell to choose alien's path...",
                "Now choose next point at column#2 and row#1 (right from the middle cell)...",
                "Then choose cell where GEM is...",
                "And finally tap at start button",
                "Oooppps.. Be careful, everything in this planet wants to kill us. Tap restart to try again...",
                "But we already know how each of them behaves itself. Tap at bee...",
                "That red line shows how bee moves. When a bee reaches last cell bee goes back and again...",
                "Now let's find right way to get GEM. Tap at column#1 and row#1 (left-bottom cell)...",
                "Next cell must be column#2 and row#1...",
                "Next cell must be column#3 and row#1...",
                "Next cell must be column#3 and row#2...",
                "And finally last cell must be column#3 and row#3...",
                "And as you guested tap at start button"
                ],
            2:
                [
                "For previous level you got 3 GEMS. You can look how many gems you have in settings...",
                "You can buy extra lives for GEMS...",
                "You can tap at any object to find out how it behaves itself or how it moves...",
                "Tap at the nearest star to find out what it is like...",
                ],
            3:
                [
                "If you did not choose path you can activate preview mode",
                "Click at 'Start' button to activate preview mode"
                ],
            4:
                [
                "You can click at last your path's point and delete it"
                ],
            5:
                [
                "Except tapping at screen you can slide along the game board"
                ],
            6:
                [
                "If label with maximum count of moves has red color you should use all moves"
                ],
            7:
                [
                "If you've already chosen path you can still look at enemy's info. Just tap long at it"
                ],
            14:
                [
                "To get some info about dynamic enemy just tap long at it"
                ],
            16:
                [
                "Now your managing is going to be different",
                "Use 'swipes' to control a space alien, just slide finger along your screen",
                "Collect 10 stars to win level and be careful you should avoid your enemies"
                ]
        ]
        
        if slide != infoBlockTutorial[Model.sharedInstance.currentLevel]!.count {
            removeObjectInfoView(toAlpha: 1)
            presentObjectInfoView(spriteName: "PlayerStaysFront", description: infoBlockTutorial[Model.sharedInstance.currentLevel]![slide])
            
            if sender != nil {
                
                let slideIndex = sender!.view!.tag
                
                let tapPoints = getTapPoints(index: Model.sharedInstance.currentLevel)
                
                if tapPoints.index(forKey: slideIndex) != nil {
                    
                    let nextMovePointForTapIcon = tapPoints[slide]

                    for tapIconView in sender!.view!.subviews {
                        if tapIconView.restorationIdentifier == "tapIcon" {
                            UIView.animate(withDuration: 0.25, animations: {
                                
                                var pointConvertedForBoard = nextMovePointForTapIcon
                                pointConvertedForBoard!.origin.x += nextMovePointForTapIcon!.size.width / 2 - 10
                                pointConvertedForBoard!.origin.y += nextMovePointForTapIcon!.size.height / 2 - 10

                                tapIconView.frame.origin = pointConvertedForBoard!.origin
                            }, completion: { (_) in
                                
                            })
                        }
                    }
                }
            }
        }
        else {
            removeObjectInfoView(toAlpha: 1)
            
            UIView.animate(withDuration: 0.25, animations: {
                sender!.view!.alpha = 1
            }, completion: { (_) in
                sender!.view!.removeFromSuperview()
            })
            
            extraActionForSlide(slide: slide)
            
            isLevelWithTutorial = false
        }
    }
    
    func drawPath(slide: Int) {
        
        let tapPoints = [
            2: Point(column: 1, row: 1),
            3: Point(column: 2, row: 1),
            4: Point(column: 2, row: 2),
            9: Point(column: 0, row: 0),
            10: Point(column: 1, row: 0),
            11: Point(column: 2, row: 0),
            12: Point(column: 2, row: 1),
            13: Point(column: 2, row: 2)]
        
        updateMoves(-1)
        self.character.moves.append(tapPoints[slide]!)
        self.character.path()
    }
    
    func extraActionForSlide(slide: Int) {
        switch Model.sharedInstance.currentLevel {
        case 1:
            switch slide {
                case 2, 3, 4, 9, 10, 11, 12, 13:
                    drawPath(slide: slide)
                case 5, 14:
                    startLevel()
                case 6:
                    restartingLevel()
                case 7:
                    for object in movingObjects {
                        if object.getPoint() == Point(column: 2, row: 0) {
                            object.path()
                        }
                    }
                case 8:
                    for object in movingObjects {
                        if object.getPoint() == Point(column: 2, row: 0) {
                            object.path(hide: true)
                        }
                    }
                default:
                    break
            }
        case 2:
            switch slide {
                case 4:
                    for object in staticObjects {
                        if object.point == Point(column: 1, row: 3) {
                            
                            presentObjectInfoView(spriteName: object.type.spriteName, description: object.type.description)
                            
                            objectTypeClickedLast = object.type
                            lastClickOnGameBoard = object.point
                        }
                    }
                default:
                    break
            }
        case 3:
            switch slide {
                case 2:
                    previewMainTimer()
                    isPreviewing = true
                    
                    presentObjectInfoView(spriteName: "PlayerStaysFront", description: "Preview mode is activated. To turn off this tap at 'Stop' button at right-top corner")
                
                    Model.sharedInstance.gameViewControllerConnect.goToMenuButton.isEnabled = false
                    Model.sharedInstance.gameViewControllerConnect.buyLevelButton.isEnabled = false
                    Model.sharedInstance.gameViewControllerConnect.startLevel.setImage(UIImage(named: "Menu_stop"), for: UIControlState.normal)
                default:
                    break
            }
        case 16:
            switch slide {
                case 2:
                    if bossLevel != nil {
                        self.isPaused = false
                        bossLevel?.isFinishedLevel = false
                        bossLevel?.prepareBossLevel()
                    }
            default:
                break
            }
        default:
            break
        }
    }
}
