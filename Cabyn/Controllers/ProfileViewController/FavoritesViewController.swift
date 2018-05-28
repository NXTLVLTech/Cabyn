//
//  FavoritesViewController.swift
//  Cabyn
//
//  Created by Lazar Vlaovic on 5/5/18.
//  Copyright © 2018 Lazar Vlaovic. All rights reserved.
//

import UIKit
import Firebase

class FavoritesViewController: BaseViewController {
    
    // MARK: - UI outlets
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - Private variables
    var listingArray = [Listing]()

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        getAllFavoritedListings()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.tintColor = .darkGray
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.navigationBar.tintColor = .white
    }
    
    // MARK: - Private functions
    private func setupUI() {
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        
        title = "FAVORITES"
    }
    
    // MARK: - Private methods
    private func getAllFavoritedListings() {
        
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        if internetReachable {
            showProgressHUD()
            
            AppAPI.instance.getAllAvailableListings(success: { [weak self] (listingArray) in
                
                guard let unwSelf = self else {
                    self?.hideProgressHUD()
                    return
                }
                
                unwSelf.listingArray = listingArray.sorted(by: { $0.timestamp > $1.timestamp }).filter({ $0.favoritedUIDs.contains(uid)})
                
                unwSelf.hideProgressHUD()
                unwSelf.tableView.reloadData()
                
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
}

extension FavoritesViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return listingArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard
            let cell = tableView.dequeueReusableCell(withIdentifier: "BookingTableViewCell", for: indexPath) as? BookingTableViewCell,
            let uid = Auth.auth().currentUser?.uid
            else { return UITableViewCell() }
        
        cell.collectionView.tag = indexPath.row
        cell.updateCell(listing: listingArray[indexPath.row], uid: uid)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let cell = cell as? BookingTableViewCell else { return }
        cell.collectionView.delegate = self
        cell.collectionView.dataSource = self
        cell.collectionView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let detailsVC = storyboard?.instantiateViewController(withIdentifier: "ListingDetailsViewController") as? ListingDetailsViewController else { return }
        let listing =  listingArray[indexPath.row]
        detailsVC.listing = listing
        navigationController?.pushViewController(detailsVC, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 300
    }
}

extension FavoritesViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return listingArray[collectionView.tag].imageURLs.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "BookingCollectionViewCell", for: indexPath) as? BookingCollectionViewCell,
            let uid = Auth.auth().currentUser?.uid
            else { return UICollectionViewCell() }
        
        cell.index = indexPath.row
        cell.updateCell(listing: listingArray[collectionView.tag], uid: uid)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let detailsVC = storyboard?.instantiateViewController(withIdentifier: "ListingDetailsViewController") as? ListingDetailsViewController else { return }
        let listing =  listingArray[collectionView.tag]
        detailsVC.listing = listing
        navigationController?.pushViewController(detailsVC, animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: collectionView.frame.height)
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        
        let pageIndex = round(scrollView.contentOffset.x / view.frame.width)
        guard
            let collectionView = scrollView as? UICollectionView,
            let tableViewCell = tableView.cellForRow(at: IndexPath(item: collectionView.tag, section: 0)) as? BookingTableViewCell
            else { return }
        
        listingArray[collectionView.tag].selectedIndex = Int(pageIndex)
        tableViewCell.pageControl.currentPage = listingArray[collectionView.tag].selectedIndex
    }
}

