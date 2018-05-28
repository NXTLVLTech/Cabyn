//
//  LoginViewController.swift
//  Cabyn
//
//  Created by Lazar Vlaovic on 4/3/18.
//  Copyright © 2018 Lazar Vlaovic. All rights reserved.
//

import UIKit
import SwiftValidator
import FirebaseAuth
import FBSDKLoginKit

class LoginViewController: BaseViewController {
    
    // MARK: - Outlets

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var signUpLabel: UILabel!
    
    // MARK: - Proporties
    
    var validator = Validator()
    var allTextFields = [UITextField]()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
    }
    
    private func setupUI() {
        clearNavBar()
        generateTextFieldRules()
        setupView()
    }
    
    private func generateTextFieldRules() {
        
        validator.registerField(emailTextField, rules: [RequiredRule(message: "Email is required."), EmailRule(message: "Email is invalid.")])
        validator.registerField(passwordTextField, rules: [RequiredRule(message: "Password is required.")])
        
        allTextFields = [emailTextField, passwordTextField]
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
    // MARK: - Private functions
    
    private func setupView() {
        
        signUpLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(signUpButtonAction(_:))))
        signUpLabel.isUserInteractionEnabled = true
    }
    
    private func loginWithEmail() {
        
        guard
            let email = emailTextField.text,
            let password = passwordTextField.text
            else {
                return
        }
        
        showProgressHUD()
        
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] (user, error) in
            
            guard let unwSelf = self else {
                self?.hideProgressHUD()
                return
            }
            
            if error == nil {
                
                unwSelf.hideProgressHUD()
                UserDefaultsMapper.save(true, forKey: UserDefaultKeys.isLoggedIn)
                unwSelf.mainTabViewController()
            } else {
                
                guard let error = AuthErrorCode(rawValue: error!._code) else {
                    unwSelf.hideProgressHUD()
                    return
                }
                
                switch error {
                    
                case .wrongPassword:
                    unwSelf.hideProgressHUD(animated: true, completionHandler: {
                        unwSelf.presentAlert(message: "Whoops! That was the wrong password.")
                    })
                case .userNotFound:
                    unwSelf.hideProgressHUD(animated: true, completionHandler: {
                        unwSelf.presentAlert(message: "User with that email doesn't exist.")
                    })
                case .invalidEmail:
                    unwSelf.hideProgressHUD(animated: true, completionHandler: {
                        unwSelf.presentAlert(message: "Your email address is invalid. Please enter a valid address.")
                    })
                    
                default:
                    unwSelf.hideProgressHUD(animated: true, completionHandler: {
                        unwSelf.presentAlert(message: "An unexpected error occured. Please try again.")
                    })
                }
            }
        }
    }
    
    private func facebookLogin() {
        
        let facebookLogin = FBSDKLoginManager()
        
        facebookLogin.logOut()
        
        facebookLogin.logIn(withReadPermissions: ["email"], from: self) { [weak self] (result, error) in
            
            self?.showProgressHUD()
            
            guard let unwSelf = self else {
                self?.hideProgressHUD()
                return
            }
            
            if error != nil {
                
                
                unwSelf.hideProgressHUD()
                unwSelf.presentAlert(message: "Unable to authenticate with Facebook. Please try again.")
            } else if result?.isCancelled == true {
                
                unwSelf.hideProgressHUD()
            } else {
                
                FacebookDataService.firebaseCredentialRequest(success: { (fbUser) in
                    
                    
                    let credential = FacebookAuthProvider.credential(withAccessToken: FBSDKAccessToken.current().tokenString)
                    
                    unwSelf.firebaseCredentialFacebookLogin(credential: credential, facebookUserModel: fbUser)
                }, failure: { (error) in
                    
                    unwSelf.hideProgressHUD()
                    unwSelf.presentAlert(message: error)
                })
            }
        }
    }
    
    private func firebaseCredentialFacebookLogin(credential: AuthCredential, facebookUserModel: User) {
        
        Auth.auth().signIn(with: credential) { [weak self] (user, error) in
            
            guard let unwSelf = self else {
                self?.hideProgressHUD()
                return
            }
            
            if error != nil {
                
                unwSelf.hideProgressHUD(animated: true, completionHandler: {
                    unwSelf.presentAlert(message: "\(error?.localizedDescription ??  "Error")")
                })
                
            } else {
                
                guard let userUID = user?.uid else {
                    unwSelf.hideProgressHUD()
                    return
                }
                
                AppAPI.instance.userRefrence.observeSingleEvent(of: .value, with: { (snapshot) in
                    
                    //If User is registered with facebook for the first time
                    if !snapshot.hasChild(userUID) {
                        
                        unwSelf.hideProgressHUD()
                        
                        guard
                            let email = user?.email,
                            let uid = user?.uid
                            else {
                                return
                        }
                        
                        let dict = ["fullname": facebookUserModel.name,
                                    "email": email,
                                    "profileLink": facebookUserModel.imageURL]
                        
                        AppAPI.instance.registerUser(uid: uid, dict: dict)
                        
                        let objects: [(object: Any, key: UserDefaultKeys)] = [
                            (object: true, key: .isLoggedIn),
                            (object: true, key: .facebookAccount)
                        ]
                        
                         UserDefaultsMapper.saveMultiple(objects)
                        
                        unwSelf.mainTabViewController()
                    } else {
                        
                        unwSelf.hideProgressHUD()
                        
                        let objects: [(object: Any, key: UserDefaultKeys)] = [
                            (object: true, key: .isLoggedIn),
                            (object: true, key: .facebookAccount)
                        ]
                        
                        unwSelf.view.endEditing(true)
                        
                        UserDefaultsMapper.saveMultiple(objects)
                        unwSelf.mainTabViewController()
                    }
                })
            }
        }
    }
    
    // MARK: - Button Actions
    
    @IBAction func signInButtonAction(_ sender: UIButton) {
        validator.validate(self)
    }
    
    @IBAction func facebookButtonAction(_ sender: UIButton) {
        facebookLogin()
    }
    
    @IBAction func forgotPasswordButtonAction(_ sender: UIButton) {
        
        guard let forgotVC = storyboard?.instantiateViewController(withIdentifier: "ForgotPasswordViewController") else { return }
        navigationController?.pushViewController(forgotVC, animated: true)
    }
    
    @objc func signUpButtonAction(_ sender: UITapGestureRecognizer) {
        
        guard let signVC = storyboard?.instantiateViewController(withIdentifier: "RegisterViewController") else { return }
        navigationController?.pushViewController(signVC, animated: true)
    }
    
}

// MARK: - Swift Validator Delegate

extension LoginViewController: ValidationDelegate {
    
    func validationSuccessful() {
        
        if internetReachable {
            
            loginWithEmail()
        } else {
            
            noInternetAlert()
        }
    }
    
    func validationFailed(_ errors: [(Validatable, ValidationError)]) {
        
        for field in allTextFields {
            for error in errors where error.1.field === field {
                self.presentAlert(message: error.1.errorMessage)
                return
            }
        }
    }
}
