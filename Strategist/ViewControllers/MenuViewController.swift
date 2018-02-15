import UIKit
import SpriteKit
import StoreKit

class MenuViewController: UIViewController {
    
    @IBOutlet weak var countOfGems: UILabel!
    @IBOutlet weak var showTipsSwitch: UISwitch!
    @IBOutlet var buyBtnBgView: [UIView]!
    @IBOutlet weak var soundsSwitch: UISwitch!
    @IBOutlet weak var bgMusicSwitch: UISwitch!
    @IBOutlet weak var mainScrollView: UIScrollView!
    @IBOutlet weak var lastViewForScrollView: UIView!
    
    var isDismissed: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Выводим кол-во собранных драг. камней
        countOfGems.text = String(Model.sharedInstance.getCountGems())
        
        // Стандартное положение для "показывать подсказки"
        showTipsSwitch.setOn(Model.sharedInstance.getShowTips(), animated: false)
        
        // Стандартное положение для "воспроизводить звуки"
        soundsSwitch.setOn(Model.sharedInstance.isActivatedSounds(), animated: false)
        
        // Стандартное положение для "воспроизводить музыку на заднем фоне"
        bgMusicSwitch.setOn(Model.sharedInstance.isActivatedBgMusic(), animated: false)
    }
    
    override func viewDidLayoutSubviews() {
        for btn in buyBtnBgView {
            btn.layer.cornerRadius = 5
            btn.layer.borderWidth = 1
            btn.layer.borderColor = UIColor.init(red: 0, green: 109 / 255, blue: 240 / 255, alpha: 1).cgColor
        }
        
        mainScrollView.backgroundColor = UIColor.init(red: 149/255, green: 201/255, blue: 45/255, alpha: 0.1)
        mainScrollView.contentSize = CGSize(width: self.view.bounds.width, height: lastViewForScrollView.frame.maxY)
        mainScrollView.showsVerticalScrollIndicator = false
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
            UserDefaults.standard.removeObject(forKey: "isActivatedSounds")
            UserDefaults.standard.removeObject(forKey: "isActivatedBgMusic")
            UserDefaults.standard.removeObject(forKey: "levelsTilesPositions")
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
        SKTAudio.sharedInstance().playSoundEffect(filename: "Switch.wav")
        
        Model.sharedInstance.setShowTips(val: sender.isOn)
    }
    
    @IBAction func buyGems(sender: UIButton) {
        SKTAudio.sharedInstance().playSoundEffect(filename: "Click.wav")
        
        addGems(amount: sender.tag)
    }
    
    func addGems(amount: Int, animation: Bool = true) {
        if animation {
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
        }
        else {
            countOfGems.text = String(Model.sharedInstance.getCountGems() + amount)
        }
        
        Model.sharedInstance.setCountGems(amountGems: amount)
    }
    
    @IBAction func goBack(sender: UIButton) {
        SKTAudio.sharedInstance().playSoundEffect(filename: "Click.wav")
        
        if isDismissed {
            navigationController?.popViewController(animated: true)
            navigationController?.dismiss(animated: true, completion: nil)
        }
        else {
            if let storyboard = storyboard {
                let chooseLevelViewController = storyboard.instantiateViewController(withIdentifier: "ChooseLevelViewController") as! ChooseLevelViewController

                navigationController?.pushViewController(chooseLevelViewController, animated: true)
            }
        }
    }
    
    /// Функция, которая предназначена для оценки игры
    @IBAction func rateApp(sender: UIButton) {
        SKTAudio.sharedInstance().playSoundEffect(filename: "Click.wav")
        
        if #available(iOS 10.3,*) {
            SKStoreReviewController.requestReview()
        }
        else {
            let appId = 123
            let url = URL(string: "itms-apps:itunes.apple.com/us/app/apple-store/id\(appId)?mt=8&action=write-review")!
            UIApplication.shared.openURL(url)
        }
    }
    
    /// Включаем/выключаем звуки
    @IBAction func switchSounds(sender: UISwitch) {
        SKTAudio.sharedInstance().playSoundEffect(filename: "Switch.wav")
        
        Model.sharedInstance.setActivatedSounds(sender.isOn)
        
        // Если звуки были выключены, то при клике на switch звуки включаются и воспроизводим звук (1-ый не воспроизводится, т.к. звуки были выключены)
        if Model.sharedInstance.isActivatedSounds() {
            SKTAudio.sharedInstance().playSoundEffect(filename: "Switch.wav")
        }
    }
    
    /// Включаем/выключаем музыку на заднем фоне
    @IBAction func switchBgMusic(sender: UISwitch) {
        SKTAudio.sharedInstance().playSoundEffect(filename: "Switch.wav")
        
        Model.sharedInstance.setActivatedBgMusic(sender.isOn)
    }
    
    /// Просмотр рекламы
    @IBAction func watchAdv(sender: UIButton) {
        SKTAudio.sharedInstance().playSoundEffect(filename: "Click.wav")
        
        addGems(amount: sender.tag, animation: false)
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
}
