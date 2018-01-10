import UIKit
import SpriteKit

class MenuViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    /// При нажатии на Switch, удаление сохранённых данных
    @IBAction func resetData(sender: UISwitch) {
        Model.sharedInstance.setCountCompletedLevels(0)
        for index in 1...Model.sharedInstance.countLevels {
            Model.sharedInstance.setLevelLives(level: index, newValue: 5)
            Model.sharedInstance.setCompletedLevel(index, value: false)
        }
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
