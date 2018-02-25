import GoogleMobileAds
import Flurry_iOS_SDK

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        if Model.sharedInstance.isDisabledAd() == false {
            GADMobileAds.configure(withApplicationID: "ca-app-pub-3811728185284523~6581984133")
        }
        
        Flurry.startSession("6Y9TM3QJN3BFHJBPD58R", with: FlurrySessionBuilder
            .init()
            .withCrashReporting(true)
            .withLogLevel(FlurryLogLevelAll))
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
        
        // Если босс-уровень и нажали кнопку "домой" (приложение попало в режиме неактивно), то открываем меню
        if Model.sharedInstance.gameScene != nil {
            if Model.sharedInstance.gameScene.bossLevel != nil {
                if Model.sharedInstance.gameScene.bossLevel!.timerStar != nil && Model.sharedInstance.gameScene.bossLevel!.timerEnemy != nil {
                    if Model.sharedInstance.gameScene.bossLevel!.timerStar.isValid && Model.sharedInstance.gameScene.bossLevel!.timerEnemy.isValid {
                        if Model.sharedInstance.gameScene.isModalWindowOpen == false {
                            Model.sharedInstance.gameScene.modalWindowPresent(type: GameScene.modalWindowType.menu)
                        }
                    }
                    else {
                        Model.sharedInstance.gameScene.isPaused = true
                    }
                }
                else {
                    Model.sharedInstance.gameScene.isPaused = true
                }
            }
        }
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
}

