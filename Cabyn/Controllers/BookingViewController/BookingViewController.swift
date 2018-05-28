//
//  BookingViewController.swift
//  Cabyn
//
//  Created by Lazar Vlaovic on 4/30/18.
//  Copyright © 2018 Lazar Vlaovic. All rights reserved.
//

import UIKit
import Firebase



class BookingViewController: BaseViewController {
    
    // MARK: - Outlets
    
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var noListingImageView: UIImageView!
    
    // MARK: - Variables
    
    var listingArray = [Listing]()
    var filteredArray = [Listing]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        getAllBookedListings()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    // MARK: - Private functions
    
    private func setupUI() {
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        
        noListingImageView.isHidden = true
        
        titleLabel.isHidden = false
        titleLabel.text = "BOOKINGS"
        segmentedControl.isHidden = false
    }
    
    private func handleNoListingUI() {
        
        if filteredArray.isEmpty {
            noListingImageView.isHidden = false
        } else {
            noListingImageView.isHidden = true
        }
    }
    
    private func getAllBookedListings() {
        
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        if internetReachable {
            showProgressHUD()
            
            AppAPI.instance.getAllBookedListings(forUID: uid, success: { [weak self] (listingArray) in
                
                self?.listingArray = listingArray.sorted(by: { $0.timestamp > $1.timestamp })
                self?.filteredArray = listingArray.filter({ $0.bookedDates?.last?.timeIntervalSince1970 ?? Date().timeIntervalSince1970 >= Date().timeIntervalSince1970 })
                self?.hideProgressHUD()
                self?.tableView.reloadData()
                self?.handleNoListingUI()
                
            }) { [weak self] (error) in
                
                self?.hideProgressHUD(animated: true, completionHandler: {
                    self?.presentAlert(message: error)
                })
            }
        } else {
            noInternetAlert()
        }
    }
        
    // MARK: - Button actions
    @IBAction func didChangeSegmentIndex(_ sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 {
            filteredArray = listingArray.filter({ $0.bookedDates?.last?.timeIntervalSince1970 ?? Date().timeIntervalSince1970 >= Date().timeIntervalSince1970 })
        } else {
            filteredArray = listingArray.filter({ $0.bookedDates?.last?.timeIntervalSince1970 ?? Date().timeIntervalSince1970 < Date().timeIntervalSince1970 })
        }
        handleNoListingUI()
        tableView.reloadData()
    }

}

extension BookingViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard
            let cell = tableView.dequeueReusableCell(withIdentifier: "BookingTableViewCell", for: indexPath) as? BookingTableViewCell,
            let uid = Auth.auth().currentUser?.uid
        else { return UITableViewCell() }
        
        cell.collectionView.tag = indexPath.row
        cell.updateCell(listing: filteredArray[indexPath.row], uid: uid)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let cell = cell as? BookingTableViewCell else { return }
        cell.collectionView.delegate = self
        cell.collectionView.dataSource = self
        cell.collectionView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let bookedDetailsViewController = storyboard?.instantiateViewController(withIdentifier: "BookedListingDetails") as? BookedListingDetails else { return }
        bookedDetailsViewController.listing = filteredArray[indexPath.row]
        navigationController?.pushViewController(bookedDetailsViewController, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 300
    }
}

extension BookingViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filteredArray[collectionView.tag].imageURLs.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "BookingCollectionViewCell", for: indexPath) as? BookingCollectionViewCell,
            let uid = Auth.auth().currentUser?.uid
            else { return UICollectionViewCell() }
        
        cell.index = indexPath.row
        cell.updateCell(listing: filteredArray[collectionView.tag], uid: uid)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let bookedDetailsViewController = storyboard?.instantiateViewController(withIdentifier: "BookedListingDetails") as? BookedListingDetails else { return }
        bookedDetailsViewController.listing = filteredArray[collectionView.tag]
        navigationController?.pushViewController(bookedDetailsViewController, animated: true)
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
        
        filteredArray[collectionView.tag].selectedIndex = Int(pageIndex)
        tableViewCell.pageControl.currentPage = filteredArray[collectionView.tag].selectedIndex
    }
}
