//
//  UIViewController+PresentationExtension.swift
//  Cabyn
//
//  Created by Lazar Vlaovic on 4/25/18.
//  Copyright © 2018 Lazar Vlaovic. All rights reserved.
//

import UIKit
import FCAlertView

extension UIViewController {
    
    func presentFCAlert(title: String? = nil,
                        message: String,
                        confirmation: ((UIAlertAction) -> Void)? = nil,
                        delegate: FCAlertViewDelegate) {
        
        let alert = FCAlertView()
        alert.tintColor = .orange
        
        alert.showAlert(withTitle: title, withSubtitle: message, withCustomImage:UIImage(named: "logo"), withDoneButtonTitle: nil, andButtons: nil)
        
        alert.delegate = delegate
    }
    
    func presentAlert(title: String? = nil,
                      message: String,
                      confirmation: ((UIAlertAction) -> Void)? = nil,
                      delegate: FCAlertViewDelegate? = nil) {
        
        let alert = FCAlertView()
        alert.tintColor = .orange
        
        alert.showAlert(withTitle: title, withSubtitle: message, withCustomImage: #imageLiteral(resourceName: "logo"), withDoneButtonTitle: nil, andButtons: nil)
        
        alert.delegate = delegate
    }
    
    func presentCameraPhotoLibraryAlert(camera: @escaping(UIAlertAction) -> Void,
                                        library: @escaping(UIAlertAction) -> Void,
                                        cancel:((UIAlertAction) -> Void)? = nil,
                                        sender: AnyObject? = nil) {
        
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Camera", style: .default, handler: camera))
        alert.addAction(UIAlertAction(title: "Camera Roll", style: .default, handler: library))
        alert.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: cancel))
        alert.view.tintColor = .orange
        
        if let presenter = alert.popoverPresentationController, let button = sender as? UIView {
            presenter.sourceView = button
            presenter.sourceRect = button.bounds
        }
        
        self.present(alert, animated: true, completion: nil)
        
    }
    
    func presentShareAlert(email: @escaping(UIAlertAction) -> Void,
                           phone: @escaping(UIAlertAction) -> Void,
                           cancel:((UIAlertAction) -> Void)? = nil) {
        
        
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Email", style: .default, handler: email))
        alert.addAction(UIAlertAction(title: "Call", style: .default, handler: phone))
        alert.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: cancel))
        alert.view.tintColor = .orange
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func presentYesNoAlert(title: String? = nil,
                           message: String,
                           yesHandler: @escaping ((UIAlertAction) -> Void),
                           noHandler: ((UIAlertAction) -> Void)? = nil) {
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: yesHandler))
        alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: noHandler))
        alert.view.tintColor = .orange
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func presentShareAlert(facebook: @escaping(UIAlertAction) -> Void,
                           twitter: @escaping(UIAlertAction) -> Void,
                           cancel:((UIAlertAction) -> Void)? = nil) {
        
        
        let alert = UIAlertController(title: "Share your Hitstape profile", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Facebook", style: .default, handler: facebook))
        alert.addAction(UIAlertAction(title: "Twitter", style: .default, handler: twitter))
        alert.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: cancel))
        alert.view.tintColor = .orange
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func presentOKAlert(title: String? = nil, message: String, completion: @escaping ((UIAlertAction) -> Void)) {
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default, handler: completion)
        alert.addAction(action)
        alert.view.tintColor = .orange
        
        present(alert, animated: true, completion: nil)
    }
}
extension UIView {
    func fadeTo(alphaValue: CGFloat, withDuration duration: TimeInterval) {
        UIView.animate(withDuration: duration) {
            self.alpha = alphaValue
        }
    }
}
