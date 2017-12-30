import UIKit
import SpriteKit

class ChooseLevelViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        for index in 0...Model.sharedInstance.countLevels - 1 {
            
            let halfSize = self.view.frame.width / 2 - (60 * 5 / 2)
            let button = UIButton(frame: CGRect(x: CGFloat(60 * Int(index % 5) + Int(halfSize)), y: CGFloat(60 * (Int(index / 5) + 1)), width: 50, height: 50))
            button.backgroundColor = UIColor.green
            button.setTitle("\(index + 1)", for: UIControlState.normal)
            button.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
            button.tag = index + 1
            self.view.addSubview(button)
        }
    }
    
//    @IBAction func chooseLevel(sender: UIButton) {
//
//    }
    
    @objc func buttonAction(sender: UIButton!) {
        let buttonSenderAction: UIButton = sender
        
        Model.sharedInstance.currentLevel = buttonSenderAction.tag
        
        if Model.sharedInstance.countLives![String(Model.sharedInstance.currentLevel)]! > 0 {
            if let storyboard = storyboard {
                let gameViewController = storyboard.instantiateViewController(withIdentifier: "GameViewController") as! GameViewController
                navigationController?.pushViewController(gameViewController, animated: true)
            }
            
            if Model.sharedInstance.gameScene != nil {
                Model.sharedInstance.gameScene.cleanLevel()
                Model.sharedInstance.gameScene.createLevel()
                Model.sharedInstance.gameScene.startLevel()
            }
        }
    }
    
    /// При нажатии на Label "Back"
    @IBAction func goBack(sender: UIButton) {
        navigationController?.popViewController(animated: true)
        navigationController?.dismiss(animated: true, completion: nil)
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
}
