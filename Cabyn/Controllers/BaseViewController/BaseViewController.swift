//
//  BaseViewController.swift
//  Cabyn
//
//  Created by Lazar Vlaovic on 4/25/18.
//  Copyright © 2018 Lazar Vlaovic. All rights reserved.
//

import UIKit
import FirebaseAuth
import KVNProgress

class BaseViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    // MARK: - Root Controllers
    
    func showTutorialScreen() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Login", bundle: nil)
        let mainVC = mainStoryboard.instantiateViewController(withIdentifier: "TutorialVC")
        
        appDelegate.window?.switchRootViewController(mainVC)
    }
    
    func loginRootViewController() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Login", bundle: nil)
        let mainVC = mainStoryboard.instantiateViewController(withIdentifier: "LoginNavVC")
        
        appDelegate.window?.switchRootViewController(mainVC)
    }
    
    func mainTabViewController() {
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let mainVC = mainStoryboard.instantiateViewController(withIdentifier: "MainTabVC")
        
        appDelegate.window?.switchRootViewController(mainVC)
    }
    
    // MARK: - Progress
    func showProgressHUD(animated: Bool = true, withText text: String? = nil) {
        
        DispatchQueue.main.async {
            KVNProgress.show()
        }
    }
    
    func hideProgressHUD(animated: Bool = true, completionHandler: (() -> Void)? = nil) {
        
        DispatchQueue.main.async {
            KVNProgress.dismiss(completion: completionHandler)
        }
    }
    
    func hideProgressHUDWithSuccess() {
        
        KVNProgress.showSuccess()
    }
    
    // MARK: - No Internet Alert
    
    func noInternetAlert() {
        hideProgressHUD()
        presentAlert(title: "No internet", message: "No internet connection, please try again..", confirmation: nil)
    }
    
    // MARK: - Navigation Setup
    
    func clearNavBar() {
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.isTranslucent = true
    }
    
    func backBarButton() {
        let yourBackImage = UIImage(named: "back")
        self.navigationController?.navigationBar.backIndicatorImage = yourBackImage
        self.navigationController?.navigationBar.backIndicatorTransitionMaskImage = yourBackImage
    }
    
    func darkBarButton() {
        let yourBackImage = UIImage(named: "darkArrow")
        self.navigationController?.navigationBar.backIndicatorImage = yourBackImage
        self.navigationController?.navigationBar.backIndicatorTransitionMaskImage = yourBackImage
    }
    
    // MARK: - Logout
    func logoutFromFirebase() {
        do {
            try Auth.auth().signOut()
            hideProgressHUD()
            UserDefaultsMapper.removeObjects(keys: [.isLoggedIn, .facebookAccount])
            loginRootViewController()
            
        } catch {
            hideProgressHUD()
            //  presentAlert(message: "Error signing out: \(signOutError)")
        }
    }
}
