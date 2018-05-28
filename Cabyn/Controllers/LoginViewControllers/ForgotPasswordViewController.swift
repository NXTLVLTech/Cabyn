//
//  ForgotPasswordViewController.swift
//  Cabyn
//
//  Created by Lazar Vlaovic on 4/26/18.
//  Copyright © 2018 Lazar Vlaovic. All rights reserved.
//

import UIKit
import SwiftValidator
import FirebaseAuth

class ForgotPasswordViewController: BaseViewController {

    
    //MARK: - Outlets
    
    @IBOutlet weak var emailTextField: UITextField!
    
    //MARK: - Proporties
    
    var validator = Validator()
    var allTextFields = [UITextField]()
    
    //MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        clearNavBar()
        backBarButton()
        generateTextFieldRules()
    }
    
    private func generateTextFieldRules() {
        
        validator.registerField(emailTextField, rules: [RequiredRule(message: "Email is required."),
                                                        EmailRule(message: "Your email address is invalid. Please enter a valid address.")])
        
        emailTextField.delegate = self
        
        allTextFields = [emailTextField]
    }
    
    //MARK: - Send password reset link
    
    private func sendPasswordResetEmail() {
        
        guard let email = emailTextField.text else { return }
        
        showProgressHUD()
        
        Auth.auth().sendPasswordReset(withEmail: email) { [weak self] error in
            
            guard let unwSelf = self else {
                self?.hideProgressHUD()
                return
            }
            
            if error != nil {
                
                unwSelf.hideProgressHUD(animated: true, completionHandler: {
                    unwSelf.presentAlert(message: "User with that email doesn't exist.")
                })
                
            } else {
                
                unwSelf.view.endEditing(true)
                unwSelf.hideProgressHUD(animated: true, completionHandler: {
                    unwSelf.presentAlert(title: nil, message: "Check your email to reset your password.", confirmation: { (_) in
                        unwSelf.dismiss(animated: true, completion: nil)
                    })
                })
            }
        }
    }
    
    //MARK: - Button Actions
    
    @IBAction func sendButtonAction(_ sender: UIButton) {
        
        if internetReachable {
            validator.validate(self)
        } else {
            noInternetAlert()
        }
    }
    
}

extension ForgotPasswordViewController: ValidationDelegate {
    
    func validationSuccessful() {
        
        if internetReachable {
            
            sendPasswordResetEmail()
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

//MARK: - TextField Delegates
extension ForgotPasswordViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        if let nextField = textField.superview?.superview?.viewWithTag(textField.tag + 1) as? UITextField {
            nextField.becomeFirstResponder()
        } else {
            
            textField.resignFirstResponder()
        }
        return false
    }
}
