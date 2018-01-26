import UIKit
import SpriteKit

class MenuViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    /// При нажатии на Switch, удаление сохранённых данных
    @IBAction func resetData(sender: UISwitch) {
        UserDefaults.standard.removeObject(forKey: "countLives")
        UserDefaults.standard.removeObject(forKey: "completedLevels")
        UserDefaults.standard.removeObject(forKey: "countCompletedLevels")
        UserDefaults.standard.removeObject(forKey: "countGems")
        UserDefaults.standard.synchronize()
        
        exit(0)
    }
    
    @IBAction func goBack(sender: UIButton) {
        if let storyboard = storyboard {
            let chooseLevelViewController = storyboard.instantiateViewController(withIdentifier: "ChooseLevelViewController") as! ChooseLevelViewController
            chooseLevelViewController.characterPosLevelFromScene = Model.sharedInstance.currentLevel
            
            navigationController?.pushViewController(chooseLevelViewController, animated: true)
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
}
