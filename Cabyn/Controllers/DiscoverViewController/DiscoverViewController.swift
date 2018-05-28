//
//  DiscoverViewController.swift
//  Cabyn
//
//  Created by Lazar Vlaovic on 4/26/18.
//  Copyright © 2018 Lazar Vlaovic. All rights reserved.
//

import UIKit
import Firebase
import GooglePlaces

class DiscoverViewController: BaseViewController {
    
    // MARK: - Outlets
    
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var noSpacesImageView: UIImageView!
    
    // MARK: - Variables
    
    var listingArray = [Listing]()
    var filteredArray = [Listing]()
    var inSearchMode = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        getAllListings()
        listenToNotification()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Private functions
    
    private func setupUI() {
        
        // Text Field Setup
        
        searchTextField.layer.cornerRadius = 4
        searchTextField.layer.shadowOpacity = 0.3
        searchTextField.layer.shadowOffset = CGSize(width: -1, height: 1)
        searchTextField.layer.shadowColor = UIColor.gray.cgColor
        let img = UIImageView(image: UIImage(named: "search-1"))
        img.frame = CGRect(x: 0, y: 0, width: 30, height: 20)
        img.contentMode = .left
        searchTextField.rightViewMode = .always
        searchTextField.rightView = img
        searchTextField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: searchTextField.frame.height))
        searchTextField.leftViewMode = .always
        searchTextField.delegate = self
        
        tableView.delegate = self
        tableView.dataSource = self
        
        noSpacesImageView.isHidden = true
    }
    
    private func listenToNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(presentSuccessViewController), name: NSNotification.Name.init(rawValue: "BookingNotification"), object: nil)
    }
    
    @objc private func presentSuccessViewController() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            guard let successViewController = self.storyboard?.instantiateViewController(withIdentifier: "CongratulationViewController") as? CongratulationViewController else { return }
            successViewController.modalTransitionStyle = .crossDissolve
            successViewController.modalPresentationStyle = .overFullScreen
            self.present(successViewController, animated: true, completion: nil)
        }
    }
    
    private func handleNoListingUI() {
        
        if inSearchMode {
            if filteredArray.isEmpty {
                noSpacesImageView.isHidden = false
            } else {
                noSpacesImageView.isHidden = true
            }
        } else {
            if listingArray.isEmpty {
                noSpacesImageView.isHidden = false
            } else {
                noSpacesImageView.isHidden = true
            }
        }
    }
    
    private func presentGoogleAutocomplete() {
        
        let autocompleteController = GMSAutocompleteViewController()
        autocompleteController.delegate = self
        
        // Set a filter to return only addresses.
        let filter = GMSAutocompleteFilter()
        filter.type = .city
        autocompleteController.autocompleteFilter = filter
        
        present(autocompleteController, animated: true, completion: nil)
    }
    
    // MARK: - Web Services
    
    private func getAllListings() {
        
        if internetReachable {
            showProgressHUD()
            
            AppAPI.instance.getAllAvailableListings(success: { [weak self] (listingArray) in
                
                guard let unwSelf = self else {
                    self?.hideProgressHUD()
                    return
                }
                
                unwSelf.listingArray = listingArray.sorted(by: { $0.timestamp > $1.timestamp }).filter({ $0.isBooked == false })
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
    
    // MARK: - Actions

    @IBAction func searchFieldEditingChanged(_ sender: UITextField) {
        
        guard let text = sender.text?.lowercased(), text.count > 0 else {
            resetTextField()
            return
        }
        
        filteredArray = listingArray.filter({$0.formattedAddress.lowercased().contains(text)})
        inSearchMode = true
        tableView.reloadData()
        handleNoListingUI()
    }
}

extension DiscoverViewController: UITextFieldDelegate {
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        presentGoogleAutocomplete()
        return false
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(true)
        return true
    }
    
    private func resetTextField() {
        searchTextField.text = nil
        inSearchMode = false
        tableView.reloadData()
        handleNoListingUI()
    }
}

extension DiscoverViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return inSearchMode == true ? filteredArray.count : listingArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard
            let cell = tableView.dequeueReusableCell(withIdentifier: "DiscoverTableViewCell", for: indexPath) as? DiscoverTableViewCell,
            let uid = Auth.auth().currentUser?.uid
            else { return UITableViewCell() }
        let listing = inSearchMode == true ? filteredArray[indexPath.row] : listingArray[indexPath.row]
        
        cell.collectionView.tag = indexPath.row
        cell.updateCell(listing: listing, uid: uid)
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let cell = cell as? DiscoverTableViewCell else { return }
        cell.collectionView.delegate = self
        cell.collectionView.dataSource = self
        cell.collectionView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        guard let detailsVC = storyboard?.instantiateViewController(withIdentifier: "ListingDetailsViewController") as? ListingDetailsViewController else { return }
        let listing = inSearchMode == true ? filteredArray[indexPath.row] : listingArray[indexPath.row]
        detailsVC.listing = listing
        navigationController?.pushViewController(detailsVC, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 300
    }
}

extension DiscoverViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return inSearchMode == true ? filteredArray[collectionView.tag].imageURLs.count : listingArray[collectionView.tag].imageURLs.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DiscoverCollectionViewCell", for: indexPath) as? DiscoverCollectionViewCell,
            let uid = Auth.auth().currentUser?.uid
            else { return UICollectionViewCell() }
        let listing = inSearchMode == true ? filteredArray[collectionView.tag] : listingArray[collectionView.tag]
        
        cell.index = indexPath.row
        cell.updateCell(listing: listing, uid: uid)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: collectionView.frame.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let detailsVC = storyboard?.instantiateViewController(withIdentifier: "ListingDetailsViewController") as? ListingDetailsViewController else { return }
        let listing = inSearchMode == true ? filteredArray[collectionView.tag] : listingArray[collectionView.tag]
        detailsVC.listing = listing
        navigationController?.pushViewController(detailsVC, animated: true)
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        
        let pageIndex = round(scrollView.contentOffset.x / view.frame.width)
        guard
            let collectionView = scrollView as? UICollectionView,
            let tableViewCell = tableView.cellForRow(at: IndexPath(item: collectionView.tag, section: 0)) as? DiscoverTableViewCell
            else { return }
        let listing = inSearchMode == true ? filteredArray[collectionView.tag] : listingArray[collectionView.tag]
        listing.selectedIndex = Int(pageIndex)
        tableViewCell.pageControl.currentPage = listing.selectedIndex
    }
}

extension DiscoverViewController: GMSAutocompleteViewControllerDelegate {
    
    // Handle the user's selection.
    func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
        
        let searchContent = place.name
        
        searchTextField.text = searchContent
        filteredArray = listingArray.filter({$0.formattedAddress.lowercased().contains(searchContent.lowercased())})
        inSearchMode = true
        tableView.reloadData()
        handleNoListingUI()
        
        // Close the autocomplete widget.
        dismiss(animated: true, completion: nil)
    }
    
    func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
        // TODO: handle the error.
        print("Error: ", error.localizedDescription)
    }
    
    func wasCancelled(_ viewController: GMSAutocompleteViewController) {
        dismiss(animated: true, completion: nil)
        resetTextField()
    }
    
    // Show the network activity indicator.
    func didRequestAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    // Hide the network activity indicator.
    func didUpdateAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
}
