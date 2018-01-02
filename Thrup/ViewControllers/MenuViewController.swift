import UIKit
import SpriteKit

class MenuViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    
    /// При нажатии на Label "Levels"
    @IBAction func chooseLevel(sender: UIButton) {
        if let storyboard = storyboard {
            let chooseLevelViewController = storyboard.instantiateViewController(withIdentifier: "ChooseLevelViewController") as! ChooseLevelViewController
            navigationController?.pushViewController(chooseLevelViewController, animated: true)
        }
    }
    
    /// При нажатии на Label "Start"
    @IBAction func startGame(sender: UIButton) {
        
        Model.sharedInstance.currentLevel = Model.sharedInstance.getCountCompletedLevels() + 1
        
        if let storyboard = storyboard {
            let gameViewController = storyboard.instantiateViewController(withIdentifier: "GameViewController") as! GameViewController
            navigationController?.pushViewController(gameViewController, animated: true)
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
}
