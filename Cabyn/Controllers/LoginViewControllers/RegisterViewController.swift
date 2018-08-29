//
//  RegisterViewController.swift
//  Cabyn
//
//  Created by Lazar Vlaovic on 4/26/18.
//  Copyright © 2018 Lazar Vlaovic. All rights reserved.
//

import UIKit
import SwiftValidator
import Firebase

class RegisterViewController: BaseViewController {
    
    // MARK: - Outlets

    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var phoneNumberTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    //MARK: - Proporties
    
    var validator = Validator()
    var allTextFields = [UITextField]()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        clearNavBar()
        backBarButton()
        generateTextFieldRules()
    }
    
    // MARK: - Private functions
    
    private func generateTextFieldRules() {
        
        validator.registerField(nameTextField, rules: [RequiredRule(message: "Name is required.")])
        validator.registerField(emailTextField, rules: [RequiredRule(message: "Email is required."), EmailRule(message: "Email is invalid.")])
        validator.registerField(phoneNumberTextField, rules: [RequiredRule(message: "Phone Number is required.")])
        validator.registerField(passwordTextField, rules: [RequiredRule(message: "Password is required.")])
        
        allTextFields = [nameTextField ,emailTextField, phoneNumberTextField, passwordTextField]
    }
    
    private func emailLogin() {
        
        showProgressHUD(animated: true)
        
        Auth.auth().createUser(withEmail: emailTextField.text!, password: passwordTextField.text!, completion: { [weak self] (user, error) in
            
            guard let unwSelf = self else {
                self?.hideProgressHUD(animated: true)
                return
            }
            
            if error != nil {
                
                if let error = AuthErrorCode(rawValue: error!._code) {
                    
                    switch error {
                        
                    case .invalidEmail:
                        
                        unwSelf.hideProgressHUD(animated: true)
                        unwSelf.presentAlert(message: "This is an invalid email. Try another one.")
                    case .emailAlreadyInUse:
                        
                        unwSelf.hideProgressHUD(animated: true)
                        unwSelf.presentAlert(message: "This email is already in use.")
                    default:
                        
                        unwSelf.hideProgressHUD(animated: true)
                        unwSelf.presentAlert(message: "An unexpected error occured. Please try again.")
                    }
                }
            } else {
                
                if let user = user {
                    
                    guard let email = user.email else {
                        unwSelf.hideProgressHUD()
                        return
                    }
                    
                    unwSelf.hideProgressHUD()
                    
                    let dict = ["fullname": unwSelf.nameTextField.text ?? "",
                                "email": email,
                                "phoneNumber": unwSelf.phoneNumberTextField.text ?? ""]
                    
                    AppAPI.instance.registerUser(uid: user.uid, dict: dict)
                    
                    UserDefaultsMapper.save(true, forKey: UserDefaultKeys.isLoggedIn)
                    
                    guard let photoVC = unwSelf.storyboard?.instantiateViewController(withIdentifier: "AddPhotoViewController") as? AddPhotoViewController else { return }
                    unwSelf.navigationController?.pushViewController(photoVC, animated: true)
                }
            }
        })
    }
    
    // MARK: - Button Actions
    
    @IBAction func nextButtonAction(_ sender: UIButton) {
        validator.validate(self)
    }
    
}

// MARK: - Swift Validator Delegate

extension RegisterViewController: ValidationDelegate {
    
    func validationSuccessful() {
        
        if internetReachable {
            
             emailLogin()
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
