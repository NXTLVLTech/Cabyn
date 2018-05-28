//
//  PaymentDetailsViewController.swift
//  Cabyn
//
//  Created by Lazar Vlaovic on 5/4/18.
//  Copyright © 2018 Lazar Vlaovic. All rights reserved.
//

import UIKit
import SwiftValidator

class PaymentDetailsViewController: BaseViewController {
    
    // MARK: - UI outlets
    @IBOutlet weak var cardNumberTextField: CustomTextField!
    @IBOutlet weak var expireDateTextField: CustomTextField!
    @IBOutlet weak var cvvTextField: CustomTextField!
    
    // MARK: - Private variables
    private var validator = Validator()
    private var allTextFields = [UITextField]()
    var listing: Listing?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        generateTextFieldRules()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.navigationBar.tintColor = .darkGray
    }
    
    // MARK: - Private methods
    private func generateTextFieldRules() {
        validator.registerField(cardNumberTextField, rules: [RequiredRule(message: "Card number is required.")])
        validator.registerField(expireDateTextField, rules: [RequiredRule(message: "Expire date is required.")])
        validator.registerField(cvvTextField, rules: [RequiredRule(message: "CVV is required.")])
        
        allTextFields = [cardNumberTextField, expireDateTextField, cvvTextField]
    }
    
    private func setupUI() {
        
    }
    
    @objc private func dateDidChange() {
        
    }
    
    // MARK: - Button actions
    @IBAction func payButtonAction() {
        validator.validate(self)
    }
}

// MARK: - Validator delegates
extension PaymentDetailsViewController: ValidationDelegate {
    
    func validationSuccessful() {
        if internetReachable {
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
