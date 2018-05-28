//
//  ListingViewController.swift
//  Cabyn
//
//  Created by Lazar Vlaovic on 4/28/18.
//  Copyright © 2018 Lazar Vlaovic. All rights reserved.
//

import UIKit
import Firebase

class ListingViewController: BaseViewController {
    
    // MARK: - Outlets
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var noListingsImageView: UIImageView!
    
    // MARK: - Proporties
    
    var listingArray = [Listing]()

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        getAllListings()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    // MARK: - Setup View
    
    private func setupUI() {
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        
        noListingsImageView.isHidden = true
    }
    
    private func handleNoListingUI() {
        if listingArray.isEmpty {
            noListingsImageView.isHidden = false
        } else {
            noListingsImageView.isHidden = true
        }
    }
    
    // MARK: - Web Services
    
    private func getAllListings() {
        
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        if internetReachable {
            showProgressHUD()
            
            AppAPI.instance.getAllListings(forUID: uid, success: { [weak self] (listingArray) in
                
                guard let unwSelf = self else {
                    self?.hideProgressHUD()
                    return
                }
                
                unwSelf.listingArray = listingArray.sorted(by: { $0.timestamp > $1.timestamp })
                unwSelf.hideProgressHUD()
                unwSelf.tableView.reloadData()
                unwSelf.handleNoListingUI()
                
            }) { [weak self] (error) in
                
                guard let unwSelf = self else {
                    self?.hideProgressHUD()
                    return
                }
                
                unwSelf.hideProgressHUD(animated: true, completionHandler: {
                    unwSelf.presentAlert(message: error)
                })
            }
        } else {
            noInternetAlert()
        }
    }
    
    // MARK: - Button Actions
    
    @IBAction func addNewListingButtonAction(_ sender: UIButton) {
        
        guard let createListingVC = storyboard?.instantiateViewController(withIdentifier: "CreateListingViewController") as? CreateListingViewController else { return }
        createListingVC.modalTransitionStyle = .crossDissolve
        present(createListingVC, animated: true, completion: nil)
    }

}

extension ListingViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return listingArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard
            let cell = tableView.dequeueReusableCell(withIdentifier: "ListingTableViewCell", for: indexPath) as? ListingTableViewCell,
            let uid = Auth.auth().currentUser?.uid
            else { return UITableViewCell() }
        
        cell.collectionView.tag = indexPath.row
        cell.updateCell(listing: listingArray[indexPath.row], uid: uid)
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let cell = cell as? ListingTableViewCell else { return }
        cell.collectionView.delegate = self
        cell.collectionView.dataSource = self
        cell.collectionView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let createListingVC = storyboard?.instantiateViewController(withIdentifier: "CreateListingViewController") as? CreateListingViewController else { return }
        createListingVC.modalTransitionStyle = .crossDissolve
        createListingVC.listing = listingArray[indexPath.row]
        createListingVC.controllerType = .edit
        present(createListingVC, animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 300
    }
}

extension ListingViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return listingArray[collectionView.tag].imageURLs.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ListingCollectionViewCell", for: indexPath) as? ListingCollectionViewCell,
            let uid = Auth.auth().currentUser?.uid
            else { return UICollectionViewCell() }
        
        cell.index = indexPath.row
        cell.updateCell(listing: listingArray[collectionView.tag], uid: uid)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let createListingVC = storyboard?.instantiateViewController(withIdentifier: "CreateListingViewController") as? CreateListingViewController else { return }
        createListingVC.modalTransitionStyle = .crossDissolve
        createListingVC.listing = listingArray[collectionView.tag]
        createListingVC.controllerType = .edit
        present(createListingVC, animated: true, completion: nil)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: collectionView.frame.height)
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        
        let pageIndex = round(scrollView.contentOffset.x / view.frame.width)
        guard
            let collectionView = scrollView as? UICollectionView,
            let tableViewCell = tableView.cellForRow(at: IndexPath(item: collectionView.tag, section: 0)) as? ListingTableViewCell
            else { return }
        listingArray[collectionView.tag].selectedIndex = Int(pageIndex)
        tableViewCell.pageControl.currentPage = listingArray[collectionView.tag].selectedIndex
    }
}
