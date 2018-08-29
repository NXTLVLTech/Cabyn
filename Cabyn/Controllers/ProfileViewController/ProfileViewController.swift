//
//  ProfileViewController.swift
//  Cabyn
//
//  Created by Lazar Vlaovic on 4/29/18.
//  Copyright © 2018 Lazar Vlaovic. All rights reserved.
//

import UIKit
import Firebase

class ProfileViewController: BaseViewController {
    
    // MARK: - Outlets
    
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var userFullnameLabel: UILabel!
    @IBOutlet weak var userEmailLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - Proporties
    
    var imagesArray = ["Edit", "Edit-3", "contract", "script", "Edit-4"]
    var titleArray = ["Edit Profile", "Favorites", "Privacy Policy", "Terms and Conditions", "Log out"]
    var user: User? {
        didSet {
            userImageView.setImage(url: URL(string: user!.imageURL ?? ""))
            userFullnameLabel.text = user!.name
            userEmailLabel.text = user!.email
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        getUserData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(true, animated: true)
        
        for (index, _) in tableView.visibleCells.enumerated() {
            tableView.deselectRow(at: IndexPath(row: index, section: 0), animated: true)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    // MARK: - Private functions
    
    private func setupUI() {
        
        userImageView.layer.cornerRadius = userImageView.frame.height / 2
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
    }
    
    // MARK: - Web Services
    
    private func getUserData() {
        
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        showProgressHUD()
        
        AppAPI.instance.getUserProfileData(uid: uid, success: { [weak self] (user) in
            
            guard let unwSelf = self else {
                self?.hideProgressHUD()
                return
            }
            
            unwSelf.user = user
            unwSelf.hideProgressHUD()
            
        }) { [weak self] (error) in
            
            guard let unwSelf = self else {
                self?.hideProgressHUD()
                return
            }
            
            unwSelf.presentAlert(message: error)
            unwSelf.hideProgressHUD()
        }
    }

}

extension ProfileViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return imagesArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "profileTableViewCell")
        cell.imageView!.image = UIImage(named: imagesArray[indexPath.row])
        cell.textLabel?.text = titleArray[indexPath.row]
        cell.textLabel?.font = UIFont(name: "Helvetica-Neue-Light", size: 16)
        cell.textLabel?.textColor = .darkGray
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            
            guard
                let editVC = storyboard?.instantiateViewController(withIdentifier: "EditProfileViewController") as? EditProfileViewController,
                let user = user
            else { return }
            editVC.user = user
            navigationController?.pushViewController(editVC, animated: true)
        } else if indexPath.row == 1 {
            
            guard let favoriteVC = storyboard?.instantiateViewController(withIdentifier: "FavoritesViewController") as? FavoritesViewController else { return }
            navigationController?.pushViewController(favoriteVC, animated: true)
        } else if indexPath.row == 2 {
            
            guard let termsVC = storyboard?.instantiateViewController(withIdentifier: "TermsViewController") as? TermsViewController else { return }
            termsVC.type = .privacy
            navigationController?.pushViewController(termsVC, animated: true)
            
        } else if indexPath.row == 3 {
            
            guard let termsVC = storyboard?.instantiateViewController(withIdentifier: "TermsViewController") as? TermsViewController else { return }
            termsVC.type = .terms
            navigationController?.pushViewController(termsVC, animated: true)
        } else if indexPath.row == 4 {
            
            if internetReachable {
                presentYesNoAlert(message: "Are you sure you want to logout?", yesHandler: { (action) in
                    
                    self.showProgressHUD()
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: {
                        self.logoutFromFirebase()
                    })
                })
            } else {
                noInternetAlert()
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 55
    }
}
