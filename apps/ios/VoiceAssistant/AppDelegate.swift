import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        
        let homeViewController = ViewController()
        homeViewController.view.backgroundColor = UIColor.white
        window!.rootViewController = homeViewController
        
        window?.makeKeyAndVisible()
        return true
    }
}
