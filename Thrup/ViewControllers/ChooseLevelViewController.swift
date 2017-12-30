import UIKit
import SpriteKit

class ChooseLevelViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
//    @IBAction func chooseLevel(sender: UIButton) {
//
//    }
    
    
    /// При нажатии на Label "Back"
    @IBAction func goBack(sender: UIButton) {
        navigationController?.popViewController(animated: true)
        navigationController?.dismiss(animated: true, completion: nil)
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
}
