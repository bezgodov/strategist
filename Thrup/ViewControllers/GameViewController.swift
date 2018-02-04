import UIKit
import SpriteKit

class GameViewController: UIViewController {

    @IBOutlet weak var backgroundBlurEffect: UIVisualEffectView!
    @IBOutlet weak var stackViewLoseLevel: UIStackView!
    @IBOutlet weak var menuButtonTopRight: UIButton!
    @IBOutlet weak var startLevel: UIButton!
    @IBOutlet weak var movesRemainLabel: UILabel!
    @IBOutlet weak var buyLevelButton: UIButton!
    @IBOutlet weak var viewHearts: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        stackViewLoseLevel.isHidden = true
        
        let view = self.view as! SKView

        view.ignoresSiblingOrder = true
        
        Model.sharedInstance.gameScene = GameScene(fileNamed: "GameScene")
        Model.sharedInstance.gameScene.scaleMode = .aspectFill
        
        Model.sharedInstance.gameViewControllerConnect = self
        
        Model.sharedInstance.gameScene.anchorPoint = CGPoint(x: 0.5, y: 0.5)

        view.showsFPS = true
        view.showsPhysics = true
        view.showsNodeCount = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
            view.presentScene(Model.sharedInstance.gameScene)
        })
    }

    override var shouldAutorotate: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    // При нажатии "Start" в верхней части экрана (запуск уровня)
    @IBAction func startLevel(sender: UIButton) {
        // Либо использовать все ходы обязательно и они использованы (тогда начало уровня), либо можно не использовать все ходы на уровне
        if (Model.sharedInstance.gameScene.isNecessaryUseAllMoves == true && Model.sharedInstance.gameScene.moves == 0) || Model.sharedInstance.gameScene.isNecessaryUseAllMoves == false {
            Model.sharedInstance.gameScene.startLevel()
            // Скрываем подсказку об объекте, если она открыта
            Model.sharedInstance.gameScene.removeObjectInfoView(toAlpha: 0)
        }
        else {
            Model.sharedInstance.gameScene.shakeView(movesRemainLabel, repeatCount: 2, amplitude: 4.25)
        }
    }
    
    /// При нажатии на "Restart" после проигранного раунда
    @IBAction func restartLevel(sender: UIButton) {
        if Model.sharedInstance.getLevelLives(Model.sharedInstance.currentLevel) > 0 {
            Model.sharedInstance.gameViewControllerConnect = self
            Model.sharedInstance.gameScene.restartLevel()
        }
    }
    
    /// При нажатии на "Menu" после проигранного раунда
    @IBAction func goToMenu(sender: UIButton) {
        goToMenuCurrentLevel()
    }
    
    @IBAction func buyLevel(sender: UIButton) {
        Model.sharedInstance.gameScene.buyLevel()
    }
    
    func goToMenuCurrentLevel(presentModalWindow: Bool = false) {
        if let storyboard = storyboard {
            let chooseLevelViewController = storyboard.instantiateViewController(withIdentifier: "ChooseLevelViewController") as! ChooseLevelViewController
            chooseLevelViewController.characterPosLevelFromScene = Model.sharedInstance.currentLevel
            
            if presentModalWindow == true {
                chooseLevelViewController.presentModalWindowByDefault = true
            }
            
            navigationController?.pushViewController(chooseLevelViewController, animated: true)
        }
        
        Model.sharedInstance.gameScene.cleanLevel()
    }
    
    func goToNextLevel(moveCharacterFlag: Bool = true) {
        if let storyboard = storyboard {
            let chooseLevelViewController = storyboard.instantiateViewController(withIdentifier: "ChooseLevelViewController") as! ChooseLevelViewController
            chooseLevelViewController.moveCharacterToNextLevel = moveCharacterFlag
            
            navigationController?.pushViewController(chooseLevelViewController, animated: true)
        }
    }
    
    func presentMenu() {
        if let storyboard = storyboard {
            let menuViewController = storyboard.instantiateViewController(withIdentifier: "MenuViewController") as! MenuViewController
            navigationController?.pushViewController(menuViewController, animated: true)
        }
    }
}
