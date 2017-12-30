import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController {

    @IBOutlet weak var backgroundBlurEffect: UIVisualEffectView!
    @IBOutlet weak var stackViewLoseLevel: UIStackView!
    @IBOutlet weak var menuButtonTopRight: UIButton!
    @IBOutlet weak var startLevel: UIButton!
    @IBOutlet weak var showMoves: UIButton!
    @IBOutlet weak var movesRemainLabel: UILabel!
    
    
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
    
    // При нажатии "Start" в меню
    @IBAction func startLevel(sender: UIButton) {
        Model.sharedInstance.gameScene.startLevel()
    }
    
    /// При нажатии на "Restart" после проигранного раунда
    @IBAction func restartLevel(sender: UIButton) {
        Model.sharedInstance.gameViewControllerConnect = self
        Model.sharedInstance.gameScene.restartLevel()
    }
    
    /// При нажатии на "Menu" после проигранного раунда
    @IBAction func goToMenu(sender: UIButton) {
        navigationController?.popViewController(animated: true)
        navigationController?.dismiss(animated: true, completion: nil)
        Model.sharedInstance.gameScene.cleanLevel()
    }
    
    /// При нажатии на "Show moves" во время игрового цикла
    @IBAction func showMoves(sender: UIButton) {
        Model.sharedInstance.gameScene.showMoves()
    }
}
