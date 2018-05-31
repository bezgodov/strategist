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
        
        var koefForIphoneX: CGFloat = 0
        
        if #available(iOS 11.0, *) {
            koefForIphoneX = UIApplication.shared.keyWindow!.safeAreaInsets.top
        }
        
        let tapPoints =
            [
                1:
                    [
                        2: getRectFromPoint(point: Point(column: 1, row: 1)),
                        3: getRectFromPoint(point: Point(column: 2, row: 1)),
                        4: getRectFromPoint(point: Point(column: 2, row: 2)),
                        5: CGRect(x: Model.sharedInstance.gameViewControllerConnect.startLevel_wrapper.frame.origin.x, y: Model.sharedInstance.gameViewControllerConnect.startLevel_wrapper.frame.origin.y + koefForIphoneX, width: Model.sharedInstance.gameViewControllerConnect.startLevel_wrapper.frame.size.width, height: Model.sharedInstance.gameViewControllerConnect.startLevel_wrapper.frame.size.height),
                        6: CGRect(x: self.view!.bounds.midX - 200 / 2 + 20, y: self.view!.bounds.midY - 200 / 2 + 75, width: 160, height: 50),
                        7: getRectFromPoint(point: Point(column: 2, row: 0)),
                        9: getRectFromPoint(point: Point(column: 0, row: 0)),
                        10: getRectFromPoint(point: Point(column: 1, row: 0)),
                        11: getRectFromPoint(point: Point(column: 2, row: 0)),
                        12: getRectFromPoint(point: Point(column: 2, row: 1)),
                        13: getRectFromPoint(point: Point(column: 2, row: 2)),
                        14: CGRect(x: Model.sharedInstance.gameViewControllerConnect.startLevel_wrapper.frame.origin.x, y: Model.sharedInstance.gameViewControllerConnect.startLevel_wrapper.frame.origin.y + koefForIphoneX, width: Model.sharedInstance.gameViewControllerConnect.startLevel_wrapper.frame.size.width, height: Model.sharedInstance.gameViewControllerConnect.startLevel_wrapper.frame.size.height)
                    ],
                2:
                    [
                        2: getRectFromPoint(point: Point(column: 1, row: 3)),
                    ],
                3:
                    [
                        1: CGRect(x: Model.sharedInstance.gameViewControllerConnect.startLevel_wrapper.frame.origin.x, y: Model.sharedInstance.gameViewControllerConnect.startLevel_wrapper.frame.origin.y + koefForIphoneX, width: Model.sharedInstance.gameViewControllerConnect.startLevel_wrapper.frame.size.width, height: Model.sharedInstance.gameViewControllerConnect.startLevel_wrapper.frame.size.height)
                    ],
                5:
                    [
                        0: self.view!.bounds
                    ],
                7:
                    [
                        0: self.view!.bounds
                    ],
                8:
                    [
                        0: self.view!.bounds
                    ],
                9:
                    [
                        0: self.view!.bounds
                    ],
                16: [
                        0: self.view!.bounds,
                        1: self.view!.bounds,
                        2: self.view!.bounds,
                        3: self.view!.bounds
                    ],
                17:
                    [
                        0: self.view!.bounds
                    ],
                26:
                    [
                        0: self.view!.bounds,
                        1: self.view!.bounds
                    ],
                32:
                    [
                        0: self.view!.bounds
                    ],
                35:
                    [
                        0: self.view!.bounds,
                        1: getRectFromPoint(point: Point(column: 0, row: 1)),
                        2: self.view!.bounds,
                        3: self.view!.bounds
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
                
                var tapIconOnScene: UIView?
                for tapIconView in sender.view!.subviews {
                    if tapIconView.restorationIdentifier == "tapIcon" {
                        tapIconOnScene = tapIconView
                    }
                }
                
                if checkIfClickInsideRect(point: tapLocationPos, rect: tapPoints[slideIndex]!) {
                    sender.view!.tag += 1
                    
                    if sender.view!.tag == 6 || sender.view!.tag == 8 {
                        tapIconOnScene?.frame.origin = CGPoint(x: sender.view!.frame.maxX, y: 0)
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
                else {
                    // Немного трясём указатель, чтобы на него обратили внимание (если клик был сделан не в то место)
                    shakeView(tapIconOnScene!)
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
                NSLocalizedString("Hi. You have just got a promotion, now you are a STRATEGIST... [Tap somewhere to continue]", comment: ""),
                NSLocalizedString("Your main role is managing ordinary space aliens and help them collecting gems. Let's begin!", comment: ""),
                NSLocalizedString("Firstly tap at the middle cell to choose alien's path...", comment: ""),
                NSLocalizedString("Now choose next cell at column#3 and row#2 (right from the middle cell)...", comment: ""),
                NSLocalizedString("Then choose cell where GEM is...", comment: ""),
                NSLocalizedString("And finally tap at start button", comment: ""),
                NSLocalizedString("Oooppps.. Be careful, everything in this planet wants to kill us. Tap restart to try again...", comment: ""),
                NSLocalizedString("But we already know how each of them behaves itself. Tap at bee...", comment: ""),
                NSLocalizedString("That red line shows how bee moves. When a bee reaches last cell bee goes back and again...", comment: ""),
                NSLocalizedString("Now let's find right way to get GEM. Tap at column#1 and row#1 (left-bottom cell)...", comment: ""),
                NSLocalizedString("Next cell must be column#2 and row#1...", comment: ""),
                NSLocalizedString("Next cell must be column#3 and row#1...", comment: ""),
                NSLocalizedString("Next cell must be column#3 and row#2...", comment: ""),
                NSLocalizedString("And finally last cell must be column#3 and row#3...", comment: ""),
                NSLocalizedString("And as you guessed tap at start button", comment: "")
                ],
            2:
                [
                NSLocalizedString("For previous level you got 3 GEMS. You can look how many gems you have in menu or settings...", comment: ""),
                NSLocalizedString("You can buy extra lives for GEMS or winning paths...", comment: ""),
                NSLocalizedString("Tap at the nearest star to find out what it is like...", comment: ""),
                ],
            3:
                [
                NSLocalizedString("If you still did not choose path you can activate preview mode...", comment: ""),
                NSLocalizedString("Tap at 'Start' button to activate preview mode", comment: "")
                ],
            5:
                [
                NSLocalizedString("You can tap at last your chosen path's point and delete it", comment: "")
                ],
            7:
                [
                NSLocalizedString("Except tapping at screen you can slide along the game board", comment: "")
                ],
            8:
                [
                NSLocalizedString("If label with maximum count of moves has red color you should use all moves", comment: "")
                ],
            9:
                [
                NSLocalizedString("If you've already chosen path you can still look at enemy's info. Just tap long at it", comment: "")
                ],
            16:
                [
                NSLocalizedString("Now your managing is going to be different...", comment: ""),
                NSLocalizedString("Use 'swipes' to control a space alien, just slide finger along your screen...", comment: ""),
                NSLocalizedString("You can try passing this level as many times as you wish", comment: ""),
                NSLocalizedString("Collect 10 stars to win level and be careful you should avoid your enemies", comment: "")
                ],
            17:
                [
                NSLocalizedString("To get some info about dynamic enemy just tap long at it", comment: "")
                ],
            26:
                [
                NSLocalizedString("Sometimes levels can contain lots of enemies but resolution can be very easy...", comment: ""),
                NSLocalizedString("Solve this level only for 7 moves", comment: "")
                ],
            32:
                [
                NSLocalizedString("Collect stars to get gems. 10 STARS = 1 GEM", comment: "")
                ],
            35:
                [
                NSLocalizedString("Press down all buttons to win the level and do not forget about stars...", comment: ""),
                NSLocalizedString("Tap at button to switch all other button...", comment: ""),
                NSLocalizedString("If an alien gets at button and that button was pressed down then nothing happens, but...", comment: ""),
                NSLocalizedString("If an alien gets at active button (button was not pressed down). Only that button is switched", comment: "")
            ],
        ]
        
        if slide != infoBlockTutorial[Model.sharedInstance.currentLevel]!.count {
            isOpenInfoView = true
            
            removeObjectInfoView(toAlpha: 1)
            presentObjectInfoView(spriteName: "PlayerStaysFront", description: infoBlockTutorial[Model.sharedInstance.currentLevel]![slide], isUserInteractionEnabled: false)
            
            if sender != nil {
                
                let slideIndex = sender!.view!.tag
                
                let tapPoints = getTapPoints(index: Model.sharedInstance.currentLevel)
                
                if tapPoints.index(forKey: slideIndex) != nil {
                    
                    let nextMovePointForTapIcon = tapPoints[slide]

                    for tapIconView in sender!.view!.subviews {
                        if tapIconView.restorationIdentifier == "tapIcon" {
                            if nextMovePointForTapIcon != self.view!.bounds {
                                tapIconView.alpha = 1
                                
                                if Model.sharedInstance.currentLevel == 3 {
                                    tapIconView.frame.origin = CGPoint(x: mainBgTutorial.frame.minX - tapIconView.frame.width, y: self.view!.frame.midY)
                                }
                                
                                UIView.animate(withDuration: 0.25, animations: {
                                    
                                    var pointConvertedForBoard = nextMovePointForTapIcon
                                    pointConvertedForBoard!.origin.x += nextMovePointForTapIcon!.size.width / 2 - 10
                                    pointConvertedForBoard!.origin.y += nextMovePointForTapIcon!.size.height / 2 - 10

                                    tapIconView.frame.origin = pointConvertedForBoard!.origin
                                }, completion: { (_) in
                                    
                                })
                            }
                            else {
                                tapIconView.alpha = 0
                            }
                        }
                    }
                }
            }
        }
        else {
            removeObjectInfoView(toAlpha: 1)
            
            sender!.view!.isUserInteractionEnabled = false
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
                case 3:
                    for object in staticObjects {
                        if object.point == Point(column: 1, row: 3) {
                            
                            presentObjectInfoView(spriteName: object.type.spriteName, description: object.type.description)
                            
                            lastClickOnGameBoard = object.point
                            
                            isOpenInfoView = true
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
                    
                    presentObjectInfoView(spriteName: "PlayerStaysFront", description: NSLocalizedString("Preview mode", comment: ""))
                
                    Model.sharedInstance.gameViewControllerConnect.goToMenuButton.isEnabled = false
                    Model.sharedInstance.gameViewControllerConnect.buyLevelButton.isEnabled = false
                    
                    for button in Model.sharedInstance.gameViewControllerConnect.interfaceButtons {
                        button.isEnabled = false
                    }
                    
                    Model.sharedInstance.gameViewControllerConnect.startLevel.setImage(UIImage(named: "Menu_stop"), for: UIControlState.normal)
                default:
                    break
            }
        case 16:
            switch slide {
                case 3:
                    if bossLevel != nil {
                        self.isPaused = false
                        bossLevel?.isFinishedLevel = false
                        bossLevel?.prepareBossLevel()
                    }
            default:
                break
            }
        case 32:
            switch slide {
            case 1:
                if bossLevel != nil {
                    self.isPaused = false
                    bossLevel?.isFinishedLevel = false
                    bossLevel?.prepareBossLevel()
                    
                    Model.sharedInstance.setCompletedTurorialBonusLevel()
                }
            default:
                break
            }
        case 35:
            switch slide {
            case 1:
                for object in staticObjects {
                    if object.type == ObjectType.button {
                        if object.point == Point(column: 0, row: 1) {
                            changeButtonsState(object)
                        }
                    }
                }
            default:
                break
            }
        default:
            break
        }
    }
}
