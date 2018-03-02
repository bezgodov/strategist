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
    @IBOutlet weak var buyPreviewModeView: UIView!
    @IBOutlet weak var buyPreviewModeButton: UIButton!
    @IBOutlet weak var watchAdButton: UIButton!
    @IBOutlet var viewTopMenuBorder: [UIImageView]!
    
    var isDismissed: Bool = false
    
    /// Кол-во секунд между просмотрами рекламы за вознаграждение
    let TIME_REWARD_VIDEO: Double = 300
    
    /// Таймер, которые отсчитываем время до возможности просмотра рекламы за вознаграждение
    var timeToWatchAd = Timer()
    
    var viewToIAP: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if Model.sharedInstance.menuViewController == nil {
            Model.sharedInstance.menuViewController = self
        }
        
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
        
        // Если режим предпросмотра куплен
        if Model.sharedInstance.isPaidPreviewMode() {
            buyPreviewModeButton.setTitle(NSLocalizedString("PURCHASED", comment: ""), for: UIControlState.normal)
            buyPreviewModeButton.isEnabled = false
            buyPreviewModeButton.setTitleColor(UIColor.white, for: UIControlState.normal)
        }
        
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
        
        // Если режим предпросмотра куплен
        if Model.sharedInstance.isPaidPreviewMode() {
            buyPreviewModeView.backgroundColor = UIColor.init(red: 0, green: 109 / 255, blue: 240 / 255, alpha: 1)
        }
        
        mainScrollView.backgroundColor = UIColor.init(red: 149/255, green: 201/255, blue: 45/255, alpha: 0.1)
        mainScrollView.contentSize = CGSize(width: self.view.bounds.width, height: lastViewForScrollView.frame.maxY)
        mainScrollView.showsVerticalScrollIndicator = false
    }
    
    /// Конвертировать TimeInterval в минуты:секунды
    func stringFromTimeInterval(_ interval: TimeInterval) -> String {
        let time = Int(interval)
        
        let seconds = time % 60
        let minutes = (time / 60) % 60
        
        return "\(minutes):\(seconds)"
    }
    
    func timerToAbleWatchRewardVideo() {
        watchAdButton.isEnabled = false
        
        if Model.sharedInstance.getLastTimeClickToRewardVideo() == nil {
            Model.sharedInstance.setLastTimeClickToRewardVideo(Date())
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
        }
    }
    
    func presentViewIAP(remove: Bool = false) {
        if remove && viewToIAP != nil {
            viewToIAP.removeFromSuperview()
        }
        
        if remove == false {
            viewToIAP = UIView(frame: self.view.bounds)
            viewToIAP.backgroundColor = UIColor.black
            viewToIAP.alpha = 0.5
            
            let indicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.white)
            indicator.center = viewToIAP.center
            indicator.startAnimating()
            
            viewToIAP.addSubview(indicator)
            
            self.view.addSubview(viewToIAP)
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
            let url = URL(string: "itms-apps:itunes.apple.com/us/app/apple-store/id\(appId)")!
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
            
            timerToAbleWatchRewardVideo()
        }
        else {
            gadRewardVideoSettings()
            Flurry.logEvent("Ad_wasnt_ready_menu")
        }
    }
    
    @IBAction func buyPreviewMode(sender: UIButton) {
        SKTAudio.sharedInstance().playSoundEffect(filename: "Click.wav")
        
        if Model.sharedInstance.getCountGems() >= PREVIEW_MODE_PRICE {
            let message = "\(NSLocalizedString("Buying preview mode for all time is worth", comment: "")) \(PREVIEW_MODE_PRICE) \(NSLocalizedString("GEMS", comment: "")) (\(NSLocalizedString("you have", comment: "")) \(Model.sharedInstance.getCountGems()) \(NSLocalizedString("GEMS", comment: "")))"
            
            let alert = UIAlertController(title: NSLocalizedString("Buying preview mode", comment: ""), message: message, preferredStyle: UIAlertControllerStyle.alert)
            
            let actionCancel = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: UIAlertActionStyle.cancel, handler: { (_) in
                let eventParams = ["countGems": Model.sharedInstance.getCountGems()]
                
                Flurry.logEvent("Cancel_buy_preview_mode_menu", withParameters: eventParams)
            })
            
            let actionOk = UIAlertAction(title: NSLocalizedString("Buy", comment: ""), style: UIAlertActionStyle.default, handler: { (_) in
                Model.sharedInstance.setValuePreviewMode(true)
                
                let eventParams = ["countGems": Model.sharedInstance.getCountGems()]
                
                self.addGems(amount: -PREVIEW_MODE_PRICE, animation: true)
                
                Flurry.logEvent("Buy_preview_mode_menu", withParameters: eventParams)
                
                self.buyPreviewModeButton.setTitle(NSLocalizedString("PURCHASED", comment: ""), for: UIControlState.normal)
                self.buyPreviewModeButton.isEnabled = false
                self.buyPreviewModeButton.setTitleColor(UIColor.white, for: UIControlState.normal)
                self.buyPreviewModeView.backgroundColor = UIColor.init(red: 0, green: 109 / 255, blue: 240 / 255, alpha: 1)
            })
            
            alert.addAction(actionOk)
            alert.addAction(actionCancel)
            
            self.present(alert, animated: true, completion: nil)
        }
        else {
            let message = "\(NSLocalizedString("Not enough gems to buy preview mode menu", comment: "")). \(NSLocalizedString("You need", comment: "")) \(PREVIEW_MODE_PRICE) \(NSLocalizedString("GEMS", comment: "")), \(NSLocalizedString("but you only have", comment: "")) \(Model.sharedInstance.getCountGems()) \(NSLocalizedString("GEMS", comment: ""))"
            
            let alert = UIAlertController(title: NSLocalizedString("Not enough GEMS", comment: ""), message: message, preferredStyle: UIAlertControllerStyle.alert)
            
            let actionCancel = UIAlertAction(title: NSLocalizedString("Ok", comment: ""), style: UIAlertActionStyle.cancel, handler: { (_) in
                let eventParams = ["countGems": Model.sharedInstance.getCountGems()]
                
                Flurry.logEvent("Cancel_buy_preview_mode_menu_not_enough_gems", withParameters: eventParams)
            })
            
            alert.addAction(actionCancel)
            
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func rewardBasedVideoAd(_ rewardBasedVideoAd: GADRewardBasedVideoAd,
                            didRewardUserWith reward: GADAdReward) {
        addGems(amount: Int(truncating: reward.amount), animation: false)
        
        if Model.sharedInstance.isActivatedSounds() {
            SKTAudio.sharedInstance().resumeBackgroundMusic()
        }
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
    }
    
    func rewardBasedVideoAd(_ rewardBasedVideoAd: GADRewardBasedVideoAd,
                            didFailToLoadWithError error: Error) {
        if Model.sharedInstance.isActivatedSounds() {
            SKTAudio.sharedInstance().resumeBackgroundMusic()
        }
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    override var prefersStatusBarHidden: Bool {
        return Model.sharedInstance.isHiddenStatusBar()
    }
}
