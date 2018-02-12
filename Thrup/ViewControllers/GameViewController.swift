import UIKit
import SpriteKit

class GameViewController: UIViewController {
    @IBOutlet weak var goToMenuButton: UIButton!
    @IBOutlet weak var startLevel: UIButton!
    @IBOutlet weak var movesRemainLabel: UILabel!
    @IBOutlet weak var buyLevelButton: UIButton!
    @IBOutlet weak var viewTopMenu: UIView!
    @IBOutlet weak var moveRemainCircleBg: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let view = self.view as! SKView

        view.ignoresSiblingOrder = true
        
        Model.sharedInstance.gameScene = GameScene(fileNamed: "GameScene")
        Model.sharedInstance.gameScene.scaleMode = .resizeFill
        
        Model.sharedInstance.gameViewControllerConnect = self
        
        Model.sharedInstance.gameScene.anchorPoint = CGPoint(x: 0.5, y: 0.5)

//        view.showsFPS = true
//        view.showsPhysics = true
//        view.showsNodeCount = true
        
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
            
            SKTAudio.sharedInstance().playSoundEffect(filename: "Click.wav")
            
            Model.sharedInstance.gameScene.startLevel()
            // Скрываем подсказку об объекте, если она открыта
            Model.sharedInstance.gameScene.removeObjectInfoView(toAlpha: 0)
        }
        else {
            Model.sharedInstance.gameScene.shakeView(moveRemainCircleBg, repeatCount: 2, amplitude: 2.25)
            Model.sharedInstance.gameScene.shakeView(movesRemainLabel, repeatCount: 2, amplitude: 4.25)
            SKTAudio.sharedInstance().playSoundEffect(filename: "NoStart.mp3")
        }
    }
    
    /// При нажатии на "Уровни"
    @IBAction func goToLevels(sender: UIButton) {
        SKTAudio.sharedInstance().playSoundEffect(filename: "Click.wav")
        
        Model.sharedInstance.gameScene.modalWindowPresent(type: GameScene.modalWindowType.menu)
    }
    
    @IBAction func buyLevel(sender: UIButton) {
        SKTAudio.sharedInstance().playSoundEffect(filename: "Click.wav")
        
        Model.sharedInstance.gameScene.buyLevel()
    }
    
    func goToLevels(moveCharacterFlag: Bool = false) {
        if let storyboard = storyboard {
            let chooseLevelViewController = storyboard.instantiateViewController(withIdentifier: "ChooseLevelViewController") as! ChooseLevelViewController

            
            chooseLevelViewController.moveCharacterToNextLevel = moveCharacterFlag
            
            navigationController?.pushViewController(chooseLevelViewController, animated: true)
        }
    }
    
    func presentMenu(dismiss: Bool = false) {
        if let storyboard = storyboard {
            let menuViewController = storyboard.instantiateViewController(withIdentifier: "MenuViewController") as! MenuViewController
            menuViewController.isDismissed = dismiss
            navigationController?.pushViewController(menuViewController, animated: true)
        }
    }
}
