import UIKit
import SpriteKit

class MenuViewController: UIViewController {
    
    @IBOutlet weak var countOfGems: UILabel!
    @IBOutlet weak var showTipsSwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Выводим кол-во собранных драг. камней
        countOfGems.text = String(Model.sharedInstance.getCountGems())
        
        // Стандартное положение для "показывать подсказки№
        showTipsSwitch.setOn(Model.sharedInstance.getShowTips(), animated: false)
    }
    
    /// При нажатии на Switch, удаление сохранённых данных
    @IBAction func resetData(sender: UISwitch) {
        let alert = UIAlertController(title: "Erasing data", message: "Pressing 'OK' will erase all your saved game data", preferredStyle: UIAlertControllerStyle.alert)
        
        let actionOk = UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: {_ in
            UserDefaults.standard.removeObject(forKey: "countLives")
            UserDefaults.standard.removeObject(forKey: "completedLevels")
            UserDefaults.standard.removeObject(forKey: "countCompletedLevels")
            UserDefaults.standard.removeObject(forKey: "countGems")
            UserDefaults.standard.removeObject(forKey: "showTips")
            UserDefaults.standard.removeObject(forKey: "levelsCompletedWithHelp")
            UserDefaults.standard.synchronize()
            
            exit(0)
        })
        
        let actionCancel = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil)
        
        alert.addAction(actionOk)
        alert.addAction(actionCancel)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    /// Функция, которая включает или выключает подсказки при клике на объекты на игровом поле
    @IBAction func showTips(sender: UISwitch) {
        Model.sharedInstance.setShowTips(val: sender.isOn)
    }
    
    @IBAction func buyGems(sender: UIButton) {
        addGems(amount: sender.tag)
    }
    
    func addGems(amount: Int) {
        // Анимация увеличения кол-ва драг. камней
        let previousValue = Model.sharedInstance.getCountGems()
        let newValue = previousValue + amount
        let duration: Double = 0.75
        DispatchQueue.global().async {
            for index in previousValue...newValue {
                let sleepTime = UInt32(duration / Double(newValue - previousValue) * 1000000.0)
                usleep(sleepTime)
                
                DispatchQueue.main.async {
                    self.countOfGems.text = String(index)
                }
            }
        }
        
        Model.sharedInstance.setCountGems(amountGems: amount)
    }
    
    @IBAction func goBack(sender: UIButton) {
//        if let storyboard = storyboard {
//            let chooseLevelViewController = storyboard.instantiateViewController(withIdentifier: "ChooseLevelViewController") as! ChooseLevelViewController
//            chooseLevelViewController.characterPosLevelFromScene = Model.sharedInstance.currentLevel
//
//            navigationController?.pushViewController(chooseLevelViewController, animated: true)
//        }
        navigationController?.popViewController(animated: true)
        navigationController?.dismiss(animated: true, completion: nil)
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
}
