import SpriteKit
import GoogleMobileAds
import Flurry_iOS_SDK

class MenuViewController: UIViewController, GADRewardBasedVideoAdDelegate {
    
    @IBOutlet weak var countOfGems: UILabel!
    @IBOutlet weak var showTipsSwitch: UISwitch!
    @IBOutlet var buyBtnBgView: [UIView]!
    @IBOutlet weak var soundsSwitch: UISwitch!
    @IBOutlet weak var bgMusicSwitch: UISwitch!
    @IBOutlet weak var mainScrollView: UIScrollView!
    @IBOutlet weak var lastViewForScrollView: UIView!
    @IBOutlet weak var watchAdButton: UIButton!
    @IBOutlet var viewTopMenuBorder: [UIImageView]!
    @IBOutlet weak var sectionTitle: UILabel!
    @IBOutlet weak var highScoreLabel: UILabel!
    
    var isDismissed: Bool = false
    
    /// Кол-во секунд между просмотрами рекламы за вознаграждение
    let TIME_REWARD_VIDEO: Double = 300
    
    /// Таймер, которые отсчитываем время до возможности просмотра рекламы за вознаграждение
    var timeToWatchAd = Timer()
    
    /// затемнённый экран когда завершаем покупку
    var viewToIAP: UIView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Model.sharedInstance.menuViewController = self
        
        sectionTitle.text = NSLocalizedString("MENU", comment: "")
        
        highScoreLabel.text = "\(NSLocalizedString("HIGH SCORE", comment: "")): \(Model.sharedInstance.getHighScoreBonusLevel())"
        
        /// При клике в любое место, необходимо закрыть клавиатуру
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        IAPSettings()
        
        gadRewardVideoSettings()
        
        // Выводим кол-во собранных драг. камней
        countOfGems.text = String(Model.sharedInstance.getCountGems())
        
        // Стандартное положение для "показывать подсказки"
        showTipsSwitch.setOn(Model.sharedInstance.getShowTips(), animated: false)
        
        // Стандартное положение для "воспроизводить звуки"
        soundsSwitch.setOn(Model.sharedInstance.isActivatedSounds(), animated: false)
        
        // Стандартное положение для "воспроизводить музыку на заднем фоне"
        bgMusicSwitch.setOn(Model.sharedInstance.isActivatedBgMusic(), animated: false)
        
        if Model.sharedInstance.getLastTimeClickToRewardVideo() != nil {
            timeToWatchAd.invalidate()
            timerToAbleWatchRewardVideo()
        }
        
        // Если устройство Ipad, то заменяет border (ёлочку-шипы) на обычный цвет
        if Model.sharedInstance.isDeviceIpad() {
            for borderTop in viewTopMenuBorder {
                borderTop.image = nil
                borderTop.backgroundColor = UIColor.init(red: 146 / 255, green: 115 / 255, blue: 63 / 255, alpha: 1)
            }
        }
    }
    
    func IAPSettings() {
        IAPHandler.sharedInstance.fetchAvailableProducts()
    }
    
    func gadRewardVideoSettings() {
        GADRewardBasedVideoAd.sharedInstance().delegate = self
        let request = GADRequest()
        GADRewardBasedVideoAd.sharedInstance().load(request, withAdUnitID: "ca-app-pub-3811728185284523/8355721492")
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
    
    /// Конвертировать TimeInterval в минуты:секунды
    func stringFromTimeInterval(_ interval: TimeInterval) -> String {
        let time = Int(interval)
        
        let minutes = (time / 60) % 60
        let seconds = time % 60
        
        var leadingZero = ""
        if seconds / 10 == 0 {
            leadingZero = "0"
        }
        
        return "\(minutes):\(leadingZero)\(seconds)"
    }
    
    func timerToAbleWatchRewardVideo() {
        watchAdButton.isEnabled = false
        
        if Model.sharedInstance.getLastTimeClickToRewardVideo() == nil {
            Model.sharedInstance.setLastTimeClickToRewardVideo(Date())
        }
        else {
            let time = self.TIME_REWARD_VIDEO - (Model.sharedInstance.getLastTimeClickToRewardVideo()!.timeIntervalSinceNow * -1)
            
            if time > 1 {
                self.watchAdButton.setTitle(self.stringFromTimeInterval(time), for: UIControlState.normal)
            }
        }
        
        timeToWatchAd = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { (timer) in
            if Model.sharedInstance.getLastTimeClickToRewardVideo() != nil {
                
                let time = self.TIME_REWARD_VIDEO - (Model.sharedInstance.getLastTimeClickToRewardVideo()!.timeIntervalSinceNow * -1)
                if time > 1 {
                    self.watchAdButton.setTitle(self.stringFromTimeInterval(time), for: UIControlState.normal)
                    
                    if time < 15 {
                        if GADRewardBasedVideoAd.sharedInstance().isReady == false {
                            self.gadRewardVideoSettings()
                        }
                    }
                }
                else {
                    self.watchAdButton.isEnabled = true
                    self.watchAdButton.setTitle(NSLocalizedString("WATCH AD", comment: ""), for: UIControlState.normal)
                    Model.sharedInstance.setLastTimeClickToRewardVideo(nil)
                    
                    timer.invalidate()
                }
            }
        }
    }
    
    /// Функция, которая включает или выключает подсказки при клике на объекты на игровом поле
    @IBAction func showTips(sender: UISwitch) {
        SKTAudio.sharedInstance().playSoundEffect(filename: "Switch.wav")
        
        if !sender.isOn {
            let alert = UIAlertController(title: NSLocalizedString("CAUTION", comment: ""), message: NSLocalizedString("If you turn off tips you won't be able to look at new enemies' descriptions", comment: ""), preferredStyle: UIAlertControllerStyle.alert)
            
            let actionOk = UIAlertAction(title: NSLocalizedString("Ok", comment: ""), style: UIAlertActionStyle.default, handler: { (_) in
                Model.sharedInstance.setShowTips(val: sender.isOn)
            })
            let actionCancel = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: UIAlertActionStyle.cancel, handler: { (_) in
                self.showTipsSwitch.setOn(!sender.isOn, animated: true)
            })
            
            alert.addAction(actionOk)
            alert.addAction(actionCancel)
            
            self.present(alert, animated: true, completion: nil)
        }
        else {
            Model.sharedInstance.setShowTips(val: sender.isOn)
        }
    }
    
    @IBAction func buyGems(sender: UIButton) {
        SKTAudio.sharedInstance().playSoundEffect(filename: "Click.wav")
        
        let amount = sender.tag
        
        if amount == 50 || amount == 300 || amount == 500 {
            IAPHandler.sharedInstance.purchaseProduct(id: "Bezgodov.Strategist.\(amount)GEMS_new")
            
            let eventParams = ["countGems": Model.sharedInstance.getCountGems()]
            Flurry.logEvent("Buy_gems_\(amount)", withParameters: eventParams)
        }
    }
    
    func presentViewIAP(remove: Bool = false) {
        if remove && viewToIAP?.superview != nil {
            viewToIAP!.removeFromSuperview()
            viewToIAP = nil
        }
        
        if remove == false {
            if viewToIAP?.superview != nil {
                viewToIAP?.removeFromSuperview()
                viewToIAP = nil
            }
            
            if viewToIAP?.superview == nil {
                viewToIAP = UIView(frame: self.view.bounds)
                viewToIAP!.backgroundColor = UIColor.black.withAlphaComponent(0.65)
                
                let indicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.white)
                indicator.center = viewToIAP!.center
                indicator.startAnimating()
                
                viewToIAP!.addSubview(indicator)
                
                let viewInfoAboutLongPurchasing = UILabel(frame: CGRect(x: 0, y: viewToIAP!.frame.maxY - 65, width: viewToIAP!.frame.width, height: 65))
                viewInfoAboutLongPurchasing.textAlignment = NSTextAlignment.center
                viewInfoAboutLongPurchasing.textColor = UIColor.white
                viewInfoAboutLongPurchasing.backgroundColor = UIColor.black.withAlphaComponent(0.35)
                viewInfoAboutLongPurchasing.text = NSLocalizedString("Purchasing can take long time. Please wait at least 1 minute", comment: "")
                viewInfoAboutLongPurchasing.numberOfLines = 3
                viewToIAP?.addSubview(viewInfoAboutLongPurchasing)
                
                self.view.addSubview(viewToIAP!)
            }
        }
    }
    
    func addGems(amount: Int, animation: Bool = true) {
        if animation {
            // Анимация увеличения кол-ва драг. камней
            let previousValue = Model.sharedInstance.getCountGems()
            let newValue = previousValue + amount
            let duration: Double = 0.75
            DispatchQueue.global().async {
                if previousValue <= newValue {
                    for index in previousValue...newValue {
                        let sleepTime = UInt32(duration / Double(newValue - previousValue) * 1000000.0)
                        usleep(sleepTime)
                        
                        DispatchQueue.main.async {
                            self.countOfGems.text = String(index)
                        }
                    }
                }
                else {
                    var index = previousValue
                    while index >= newValue {
                        let sleepTime = UInt32(duration / Double(previousValue - newValue) * 1000000.0)
                        usleep(sleepTime)
                        
                        DispatchQueue.main.async {
                            self.countOfGems.text = String(index)
                        }
                        index -= 1
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
        
        timeToWatchAd.invalidate()
    }
    
    /// Функция, которая предназначена для оценки игры
    @IBAction func rateApp(sender: UIButton) {
        SKTAudio.sharedInstance().playSoundEffect(filename: "Click.wav")
        
        Flurry.logEvent("Rate_app_menu")
        
        if #available(iOS 10.3,*) {
            SKStoreReviewController.requestReview()
        }
        else {
            let appId = 1351841309
            let url = URL(string: "itms-apps:itunes.apple.com/app/apple-store/id\(appId)?mt=8&action=write-review")!
            UIApplication.shared.open(url, options: ["mt": 8, "action": "write-review"], completionHandler: nil)
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
        
        if GADRewardBasedVideoAd.sharedInstance().isReady == true {
            GADRewardBasedVideoAd.sharedInstance().present(fromRootViewController: self)
            
            let eventParams = ["countGems": Model.sharedInstance.getCountGems()]
            
            Flurry.logEvent("Watch_ad", withParameters: eventParams)
        }
        else {
            let title = NSLocalizedString("FAIL", comment: "")
            let message = NSLocalizedString("Rewarded video was not ready, try again or check your Internet connection", comment: "")
            
            let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
            let actionOk = UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: UIAlertActionStyle.default)
            alert.addAction(actionOk)
            self.present(alert, animated: true, completion: nil)
            
            gadRewardVideoSettings()
            Flurry.logEvent("Ad_wasnt_ready_menu")
        }
    }
    
    func rewardBasedVideoAd(_ rewardBasedVideoAd: GADRewardBasedVideoAd, didRewardUserWith reward: GADAdReward) {
        addGems(amount: Int(truncating: reward.amount), animation: false)
        
        if Model.sharedInstance.isActivatedSounds() {
            SKTAudio.sharedInstance().resumeBackgroundMusic()
        }
        
        let eventParams = ["countGems": Model.sharedInstance.getCountGems()]
        
        Flurry.logEvent("Watch_ad_success", withParameters: eventParams)
        
        timerToAbleWatchRewardVideo()
    }
    
    func rewardBasedVideoAdDidOpen(_ rewardBasedVideoAd: GADRewardBasedVideoAd) {
        if Model.sharedInstance.isActivatedSounds() {
            SKTAudio.sharedInstance().pauseBackgroundMusic()
        }
    }
    
    func rewardBasedVideoAdDidClose(_ rewardBasedVideoAd: GADRewardBasedVideoAd) {
        if Model.sharedInstance.isActivatedSounds() {
            SKTAudio.sharedInstance().resumeBackgroundMusic()
        }
        
        gadRewardVideoSettings()
    }
    
    func rewardBasedVideoAd(_ rewardBasedVideoAd: GADRewardBasedVideoAd, didFailToLoadWithError error: Error) {
        if Model.sharedInstance.isActivatedSounds() {
            SKTAudio.sharedInstance().resumeBackgroundMusic()
        }
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    
    @IBAction func playBonus(_ sender: UIButton) {
        Model.sharedInstance.currentLevel = 32
        if let storyboard = storyboard {
            let gameViewController = storyboard.instantiateViewController(withIdentifier: "GameViewController") as! GameViewController
            gameViewController.isHighScoreBonusLevel = true
            navigationController?.pushViewController(gameViewController, animated: true)
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return Model.sharedInstance.isHiddenStatusBar()
    }
}
