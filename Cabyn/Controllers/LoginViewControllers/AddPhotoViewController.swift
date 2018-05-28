//
//  AddPhotoViewController.swift
//  Cabyn
//
//  Created by Lazar Vlaovic on 4/26/18.
//  Copyright © 2018 Lazar Vlaovic. All rights reserved.
//

import UIKit
import Firebase
import KVNProgress

class AddPhotoViewController: BaseViewController {
    
    // MARK: - Outlets
    
    @IBOutlet weak var imageView: UIImageView!
    
    // MARK: - Proporties
    
    var dict: [String: Any]!
    var isAdded: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()

        setupView()
    }
    
    // MARK: - Private functions
    
    private func setupView() {
        
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(imageTapped)))
        imageView.layer.cornerRadius = imageView.frame.height / 2
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
    
    // MARK: - Web Service
    
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
                    
                    unwSelf.mainTabViewController()
                }
            })
        } else {
            
            noInternetAlert()
        }
    }
    
    // MARK: - Button Actions
    
    @IBAction func saveButtonAction(_ sender: UIButton) {
        
        saveImageToFirebase()
    }
}

extension AddPhotoViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // MARK: - Image Delegates
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info[UIImagePickerControllerEditedImage] as? UIImage {
            
            imageView.image = image
            isAdded = true
            dismiss(animated:true, completion: nil)
        } else {
            
            self.presentAlert(message: "Error with picking up image. Please choose another one.")
        }
    }
}
