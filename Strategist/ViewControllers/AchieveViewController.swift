import SpriteKit

class AchieveViewContoller: UIViewController {
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet var bgView: UIView!
    @IBOutlet weak var gemViewTop: UIImageView!
    @IBOutlet weak var countGemsTopLabel: UILabel!
    @IBOutlet weak var sectionTitle: UILabel!
    
    var scrollViewMaxY: CGFloat = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sectionTitle.text = NSLocalizedString("ACHIEVEMENTS", comment: "")
        
        countGemsTopLabel.text = String(Model.sharedInstance.getCountGems())
        
        let completedLevels = countCompletedLevels(Model.sharedInstance.countLevels)
        let completedWithoutHelp = Model.sharedInstance.getCountLevelsCompletedWithoutHelp()
        let completedWithoutLosing = Model.sharedInstance.getCountLevelsCompletedWithoutLosing()
        let completedBonuses = countCompletedBonuses(Model.sharedInstance.countLevels)
        let collectedFreeGems = Model.sharedInstance.getCountCollectedGems()
        let collectedStarsOnBonusLevels = Model.sharedInstance.getCollectedStarsOnBonusLevels()
        
        let gotGemsForAchieves = Model.sharedInstance.getGotGemsForAchieves()
        
        var isAchieveLocked = true
        if Model.sharedInstance.getCountCompletedLevels() >= 1 {
            isAchieveLocked = false
        }
        
        let achieveId = "Complete basic tutorial"
        let text = NSLocalizedString(achieveId, comment: "")
        
        achieveCell(achieveId: achieveId, yKoef: 0, text: text, rewardCount: 1, countCompleted: Model.sharedInstance.getCountCompletedLevels(), countToComplete: 2, isAchieveLocked: isAchieveLocked, isAchieved: gotGemsForAchieves.contains(achieveId), isTopBorder: true, isBottomBorder: false)
        
        let completedLevelsValues = [5, 25, 50, 100]
        let completedLevelsGems = [1, 3, 5, 10]
        var yKoefNextSection = 1
        
        for index in 0...3 {
            
            var isAchieveLocked = true
            if completedLevels >= completedLevelsValues[index] {
                isAchieveLocked = false
            }
            let achieveId = "Complete \(completedLevelsValues[index]) levels"
            let text = "\(NSLocalizedString("Complete", comment: "")) \(completedLevelsValues[index]) \(NSLocalizedString("levels", comment: ""))"
            
            achieveCell(achieveId: achieveId, yKoef: 81 * (index + yKoefNextSection), text: text, rewardCount: completedLevelsGems[index], countCompleted: completedLevels, countToComplete: completedLevelsValues[index], isAchieveLocked: isAchieveLocked, isAchieved: gotGemsForAchieves.contains(achieveId), isTopBorder: false, isBottomBorder: index == 3)
        }
        yKoefNextSection += 4
        
        let completedLevelsWithoutHelpValues = [5, 10, 25, 50]
        let completedLevelsWithoutHelpGems = [2, 3, 5, 10]
        for index in 0...3 {
            
            var isAchieveLocked = true
            if completedWithoutHelp >= completedLevelsWithoutHelpValues[index] {
                isAchieveLocked = false
            }
            
            let achieveId = "Complete \(completedLevelsWithoutHelpValues[index]) levels without winning path"
            let text = "\(NSLocalizedString("Complete", comment: "")) \(completedLevelsWithoutHelpValues[index]) \(NSLocalizedString("levels", comment: "")) \(NSLocalizedString("without winning path", comment: ""))"
            
            achieveCell(achieveId: achieveId, yKoef: 81 * (index + yKoefNextSection) + 20, text: text, rewardCount: completedLevelsWithoutHelpGems[index], countCompleted: completedWithoutHelp, countToComplete: completedLevelsWithoutHelpValues[index], isAchieveLocked: isAchieveLocked, isAchieved: gotGemsForAchieves.contains(achieveId), isTopBorder: index == 0, isBottomBorder: index == 3)
        }
        yKoefNextSection += 4
        
        let completedLevelsFirstAttempValues = [5, 10, 25, 50]
        let completedLevelsFirstAttempGems = [2, 3, 5, 10]
        for index in 0...3 {
            
            var isAchieveLocked = true
            if completedWithoutLosing >= completedLevelsFirstAttempValues[index] {
                isAchieveLocked = false
            }
            
            let achieveId = "Complete \(completedLevelsFirstAttempValues[index]) levels on the first try"
            let text = "\(NSLocalizedString("Complete", comment: "")) \(completedLevelsFirstAttempValues[index]) \(NSLocalizedString("levels", comment: "")) \(NSLocalizedString("on the first try", comment: ""))"
            
            achieveCell(achieveId: achieveId, yKoef: 81 * (index + yKoefNextSection) + 40, text: text, rewardCount: completedLevelsFirstAttempGems[index], countCompleted: completedWithoutLosing, countToComplete: completedLevelsFirstAttempValues[index], isAchieveLocked: isAchieveLocked, isAchieved: gotGemsForAchieves.contains(achieveId), isTopBorder: index == 0, isBottomBorder: index == 3)
        }
        yKoefNextSection += 4
        
        let completedBonusLevelsValues = [1, 3, 5, 10]
        let completedBonusLevelsGems = [1, 5, 10, 15]
        for index in 0...3 {
            
            var isAchieveLocked = true
            if completedBonuses >= completedBonusLevelsValues[index] {
                isAchieveLocked = false
            }
            
            let achieveId = "Complete \(completedBonusLevelsValues[index]) bonus levels"
            let text = "\(NSLocalizedString("Complete", comment: "")) \(completedBonusLevelsValues[index]) \(NSLocalizedString("bonus levels", comment: ""))"
            
            achieveCell(achieveId: achieveId, yKoef: 81 * (index + yKoefNextSection) + 60, text: text, rewardCount: completedBonusLevelsGems[index], countCompleted: completedBonuses, countToComplete: completedBonusLevelsValues[index], isAchieveLocked: isAchieveLocked, isAchieved: gotGemsForAchieves.contains(achieveId), isTopBorder: index == 0, isBottomBorder: index == 3)
        }
        yKoefNextSection += 4
        
        let collectedGemsValues = [5, 25, 50, 100]
        let collectedGemsGems = [1, 3, 5, 10]
        for index in 0...3 {
            
            var isAchieveLocked = true
            if collectedFreeGems >= collectedGemsValues[index] {
                isAchieveLocked = false
            }
            
            let achieveId = "Collect \(collectedGemsValues[index]) daily gems"
            let text = "\(NSLocalizedString("Collect", comment: "")) \(collectedGemsValues[index]) \(NSLocalizedString("daily gems", comment: ""))"
            
            achieveCell(achieveId: achieveId, yKoef: 81 * (index + yKoefNextSection) + 80, text: text, rewardCount: collectedGemsGems[index], countCompleted: collectedFreeGems, countToComplete: collectedGemsValues[index], isAchieveLocked: isAchieveLocked, isAchieved: gotGemsForAchieves.contains(achieveId), isTopBorder: index == 0, isBottomBorder: index == 3)
        }
        yKoefNextSection += 4
        
        let collectedStarsOnBonusLevelsValues = [15, 100, 250, 500]
        let collectedStarsOnBonusLevelsGems = [1, 2, 3, 5]
        for index in 0...3 {
            
            var isAchieveLocked = true
            if collectedStarsOnBonusLevels >= collectedStarsOnBonusLevelsValues[index] {
                isAchieveLocked = false
            }
            
            let achieveId = "Collect \(collectedGemsValues[index]) stars on bonus levels"
            let text = "\(NSLocalizedString("Collect", comment: "")) \(collectedStarsOnBonusLevelsValues[index]) \(NSLocalizedString("stars on bonus levels", comment: ""))"
            
            achieveCell(achieveId: achieveId, yKoef: 81 * (index + yKoefNextSection) + 100, text: text, rewardCount: collectedStarsOnBonusLevelsGems[index], countCompleted: collectedStarsOnBonusLevels, countToComplete: collectedStarsOnBonusLevelsValues[index], isAchieveLocked: isAchieveLocked, isAchieved: gotGemsForAchieves.contains(achieveId), isTopBorder: index == 0, isBottomBorder: index == 3)
            
            if index == 3 {
                scrollViewMaxY = CGFloat(81 * (3 + yKoefNextSection) + 100 + 81)
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        bgView.backgroundColor = UIColor.init(red: 149/255, green: 201/255, blue: 45/255, alpha: 0.1)
        
        scrollView.contentSize = CGSize(width: self.view.bounds.width, height: scrollViewMaxY + 81)
        scrollView.showsVerticalScrollIndicator = false
    }
    
    func achieveCell(achieveId: String, yKoef: Int, text: String, rewardCount: Int, countCompleted: Int, countToComplete: Int, isAchieveLocked: Bool = true, isAchieved: Bool, isTopBorder: Bool = false, isBottomBorder: Bool = false) {
        let view = UIView(frame: CGRect(origin: CGPoint(x: 0, y: yKoef + 81), size: CGSize(width: self.view.frame.width, height: 81)))
        view.backgroundColor = UIColor.init(red: 149/255, green: 201/255, blue: 45/255, alpha: 1)
        
        scrollView.addSubview(view)
        
        let achieveText = UILabel(frame: CGRect(x: 16, y: 0, width: view.frame.width - 135, height: view.frame.height))
        achieveText.text = text
        achieveText.textColor = UIColor.white
        achieveText.font = UIFont(name: "AvenirNext-DemiBold", size: 18)
        achieveText.numberOfLines = 3
        achieveText.textAlignment = NSTextAlignment.left
        
        if isTopBorder {
            let topViewBorder = UIImageView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 6))
            
            if Model.sharedInstance.isDeviceIpad() {
                topViewBorder.backgroundColor = UIColor.init(red: 146 / 255, green: 115 / 255, blue: 63 / 255, alpha: 1)
            }
            else {
                topViewBorder.image = UIImage(named: "TopMenuViewBorderDown")
            }
            
            view.addSubview(topViewBorder)
        }
        
        if isBottomBorder {
            let bottomViewBorder = UIImageView(frame: CGRect(x: 0, y: 81 - 6, width: self.view.frame.width, height: 6))
            
            if Model.sharedInstance.isDeviceIpad() {
                bottomViewBorder.backgroundColor = UIColor.init(red: 146 / 255, green: 115 / 255, blue: 63 / 255, alpha: 1)
            }
            else {
                bottomViewBorder.image = UIImage(named: "TopMenuViewBorderUp")
            }
            
            view.addSubview(bottomViewBorder)
        }
        else {
            let bottomViewBorder = UIImageView(frame: CGRect(x: 0, y: 81 - 2, width: scrollView.frame.width, height: 2))
            bottomViewBorder.backgroundColor = UIColor.init(red: 137 / 255, green: 75 / 255, blue: 38 / 255, alpha: 1)
            view.addSubview(bottomViewBorder)
        }
        
        view.addSubview(achieveText)
        
        let buttonView = UIView(frame: CGRect(x: view.frame.width - 100 - 16, y: 24, width: 100, height: 33))
        buttonView.backgroundColor = UIColor.white
        buttonView.layer.cornerRadius = 5
        buttonView.layer.borderWidth = 1
        buttonView.layer.borderColor = UIColor.init(red: 0, green: 109 / 255, blue: 240 / 255, alpha: 1).cgColor
        
        view.addSubview(buttonView)
        
        let offset: CGFloat = rewardCount > 9 ? 7 : 11
        
        let gemView = UIImageView(image: UIImage(named: "Gem_blue"))
        gemView.restorationIdentifier = "gemInButton"
        let gemWidthKoef = gemView.frame.height / (buttonView.frame.height - 16)
        gemView.frame = CGRect(x: buttonView.frame.width - gemView.frame.width / gemWidthKoef - offset, y: 8, width: gemView.frame.width / gemWidthKoef, height: buttonView.frame.height - 16)
        buttonView.addSubview(gemView)
        
        let button = UIButton(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: buttonView.frame.size))
        button.backgroundColor = UIColor.clear
        button.contentHorizontalAlignment = UIControlContentHorizontalAlignment.left
        button.titleEdgeInsets.left = offset
        button.setTitle("GET \(rewardCount)", for: UIControlState.normal)
        button.titleLabel?.font = UIFont(name: "AvenirNext-Medium", size: 18)
        
        button.tag = rewardCount
        button.restorationIdentifier = achieveId
        button.addTarget(self, action: #selector(getGemsForAchieve), for: UIControlEvents.touchUpInside)
        
        button.setTitleColor(UIColor.init(red: 0 / 255, green: 109 / 255, blue: 240 / 255, alpha: 1), for: UIControlState.normal)
        buttonView.addSubview(button)
        
        if isAchieved == false {
            
        }
        else {
            buttonView.alpha = 0
            
            let checked = UIImageView(frame: CGRect(x: view.frame.width - 24 - 10 - 16, y: 28.5, width: 24, height: 24))
            checked.image = UIImage(named: "Checked")
            view.addSubview(checked)
        }
        
        if isAchieveLocked {
            let lockedView = UIView(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: view.frame.size))
            view.isUserInteractionEnabled = false
            lockedView.backgroundColor = UIColor.black.withAlphaComponent(0.25)
            view.alpha = 0.75
            view.addSubview(lockedView)
            
            gemView.alpha = 0
            button.titleEdgeInsets.left = 0
            button.contentHorizontalAlignment = UIControlContentHorizontalAlignment.center
            button.setTitle("\(countCompleted) / \(countToComplete)", for: UIControlState.normal)
        }
    }
    
    @objc func getGemsForAchieve(_ sender: UIButton) {
        let button = sender
        
        let countGems = button.tag
        let achieveId = button.restorationIdentifier!
        
        button.isUserInteractionEnabled = false
        scrollView.isScrollEnabled = false
        
        Model.sharedInstance.setGotGemsForAchieves(id: achieveId)
        
        var gemView: UIView?
        for subview in (button.superview?.subviews)! {
            if subview.restorationIdentifier == "gemInButton" {
                gemView = subview
                break
            }
        }
        
        var koefForIphoneX: CGFloat = 0
        
        if #available(iOS 11.0, *) {
            koefForIphoneX = UIApplication.shared.keyWindow!.safeAreaInsets.top
        }
        
        for index in 1...countGems {
            let gem = UIImageView(image: UIImage(named: "Gem_blue"))
            gem.frame.origin = self.view.convert((gemView?.frame.origin)!, from: button)
            gem.frame.size = (gemView?.frame.size)!
            
            self.view.addSubview(gem)
            gemView?.removeFromSuperview()
            
            Timer.scheduledTimer(withTimeInterval: TimeInterval(CGFloat(index) * 0.225), repeats: false, block: { (_) in

                if index == countGems {
                    let checked = UIImageView(frame: CGRect(x: (button.superview?.frame.width)! - 24 - 10, y: 3.5, width: 24, height: 24))
                    checked.image = UIImage(named: "Checked")
                    checked.alpha = 0
                    button.addSubview(checked)
                    button.setTitleColor(UIColor.clear, for: UIControlState.normal)
                    
                    UIView.animate(withDuration: 0.5, animations: {
                        button.superview?.backgroundColor = UIColor.clear
                        button.superview?.layer.borderWidth = 0
                        checked.alpha = 1
                    }, completion: { (_) in
//                        button.superview?.removeFromSuperview()
                        self.scrollView.isScrollEnabled = true
                    })
                }
                
                DispatchQueue.main.async {
                    UIView.animate(withDuration: TimeInterval(0.2 + 0.425), animations: {
                        gem.frame.origin = CGPoint(x: self.view.frame.width - 46 , y: 20 + koefForIphoneX)
                        gem.frame.size = self.gemViewTop.frame.size
                    }, completion: { (_) in
                        
                        SKTAudio.sharedInstance().playSoundEffect(filename: "PickUpCoin.mp3")
                        
                        self.addGems(amount: 1)

                        gem.removeFromSuperview()
                    })
                }
            })
        }
    }
    
    /// Функция, считает количество пройденных уровней в интервале [0; maxLevel]
    func countCompletedLevels(_ maxLevel: Int) -> Int {
        var level = maxLevel
        
        var countCompletedLevels = 0
        
        while level > 0 {
            if Model.sharedInstance.isCompletedLevel(level) && level % Model.sharedInstance.distanceBetweenSections != 0 {
                countCompletedLevels += 1
            }
            
            level -= 1
        }
        
        return countCompletedLevels
    }
    
    /// Кол-во пройденных бонусных уровней
    func countCompletedBonuses(_ maxLevel: Int) -> Int {
        var level = Model.sharedInstance.distanceBetweenSections
        
        var countCompletedLevels = 0
        
        while level <= maxLevel {
            if Model.sharedInstance.isCompletedLevel(level) && level % Model.sharedInstance.distanceBetweenSections == 0 {
                countCompletedLevels += 1
            }
            
            level += Model.sharedInstance.distanceBetweenSections
        }
        
        return countCompletedLevels
    }
    
    func addGems(amount: Int) {
        countGemsTopLabel.text = String(Model.sharedInstance.getCountGems() + amount)
        
        Model.sharedInstance.setCountGems(amountGems: amount)
    }
    
    @IBAction func goBack(sender: UIButton) {
        SKTAudio.sharedInstance().playSoundEffect(filename: "Click.wav")
        
        navigationController?.popViewController(animated: true)
        navigationController?.dismiss(animated: true, completion: nil)
    }
    
    override var prefersStatusBarHidden: Bool {
        return Model.sharedInstance.isHiddenStatusBar()
    }
}
