//
//  EditProfileViewController.swift
//  Cabyn
//
//  Created by Lazar Vlaovic on 4/30/18.
//  Copyright © 2018 Lazar Vlaovic. All rights reserved.
//

import UIKit
import SwiftValidator
import Firebase
import KVNProgress

class EditProfileViewController: BaseViewController {
    
    // MARK: - Outlets
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var fullnameTextField: UITextField!
    @IBOutlet weak var phoneNumberTextField: UITextField!
    @IBOutlet weak var dateOfBirthTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    
    var user: User!
    var allTextFields = [UITextField]()
    let validator = Validator()
    var isAdded: Bool = false
    
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        fillUI()
        generateRulesForFields()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.tintColor = .darkGray
    }
    
    // MARK: - Private functions

    private func setupUI() {
        
        darkBarButton()
    }
    
    private func fillUI() {
        
        imageView.setImage(url: URL(string: user.imageURL ?? ""))
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(imageTapped)))
        
        fullnameTextField.text = user.name
        emailTextField.text = user.email
        phoneNumberTextField.text = user.phoneNumber
        dateOfBirthTextField.text = user.dateOfBirth
    }
    
    private func generateRulesForFields() {
        
        validator.registerField(fullnameTextField, rules: [RequiredRule(message: "Fullname is required")])
        validator.registerField(phoneNumberTextField, rules: [RequiredRule(message: "Phone Number is required")])
        validator.registerField(dateOfBirthTextField, rules: [RequiredRule(message: "Date of Birth is required")])
        
        allTextFields = [fullnameTextField, phoneNumberTextField, dateOfBirthTextField]
    }
    
    @objc func imageTapped(tapGestureRecognizer: UITapGestureRecognizer) {
        presentCameraPhotoLibraryAlert(camera: { (_) in
            
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                
                let imagePicker = UIImagePickerController()
                imagePicker.delegate = self
                imagePicker.sourceType = .camera
                imagePicker.cameraDevice = .front
                imagePicker.allowsEditing = true
                self.present(imagePicker, animated: true, completion: nil)
            } else {
                
                self.presentAlert(message: "Camera is not available.")
            }
        }, library: { (_) in
            
            if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
                
                let imagePicker = UIImagePickerController()
                imagePicker.delegate = self
                imagePicker.sourceType = .photoLibrary;
                imagePicker.allowsEditing = true
                self.present(imagePicker, animated: true, completion: nil)
            }
        })
    }
    
    // MARK: - Web Services
    
    private func saveUserData() {
        
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let dict = ["fullname": fullnameTextField.text ?? "",
                    "dateOfBirth": dateOfBirthTextField.text ?? "",
                    "phoneNumber": phoneNumberTextField.text ?? ""]
        
        AppAPI.instance.saveUserData(uid: uid, dict: dict as [String : AnyObject])
        
        KVNProgress.showSuccess(withStatus: "Successfully update profile informations!", completion: {
            self.navigationController?.popViewController(animated: true)
        })
    }
    
    private func saveImageToFirebase() {
        
        guard
            let img = imageView.image,
            isAdded == true,
            let imgData = UIImageJPEGRepresentation(img, 0.5) else {
                return
        }
        
        showProgressHUD(animated: true)
        
        let metadata = StorageMetadata() ; metadata.contentType = "image/jpeg"
        
        if internetReachable {
            
            guard let uid = Auth.auth().currentUser?.uid else {
                hideProgressHUD()
                return
            }
            
            AppAPI.instance.storageProfileRef.child(uid).putData(imgData, metadata: metadata, completion: { [weak self] (metadata, error) in
                
                guard let unwSelf = self else {
                    self?.hideProgressHUD(animated: true)
                    return
                }
                
                if error != nil {
                    
                    unwSelf.hideProgressHUD(completionHandler: {
                        unwSelf.presentAlert(message: "Error with uploading an image to Firebase Storage.")
                    })
                } else {
                    
                    guard let downloadUrl = metadata?.downloadURL()?.absoluteString else { return }
                    
                    AppAPI.instance.saveUserData(uid: uid, dict: ["profileLink": downloadUrl as AnyObject])
                    
                    KVNProgress.show(withStatus: "Successfully updated profile picture!")
                }
            })
        } else {
            
            noInternetAlert()
        }
    }
    
    // MARK: - Button Actions
    
    @IBAction func saveUserData(_ sender: UIButton) {
        if internetReachable {
            validator.validate(self)
        } else {
            noInternetAlert()
        }
    }
}

// MARK: - Swift Validator Delegate

extension EditProfileViewController: ValidationDelegate {
    
    func validationSuccessful() {
        
        if internetReachable {
            
            saveUserData()
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

extension EditProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // MARK: - Image Delegates
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info[UIImagePickerControllerEditedImage] as? UIImage {
            
            imageView.image = image
            isAdded = true
            dismiss(animated:true, completion: nil)
            
            saveImageToFirebase()
        } else {
            
            self.presentAlert(message: "Error with picking up image. Please choose another one.")
        }
    }
}
