//
//  ListingDetailsViewController.swift
//  Cabyn
//
//  Created by Lazar Vlaovic on 5/3/18.
//  Copyright © 2018 Lazar Vlaovic. All rights reserved.
//

import UIKit
import Firebase
import Cosmos
import MapKit

protocol FavoriteProtocol: class {
    func didChangeFavoriteStatus(_ status: Bool)
}

class ListingDetailsViewController: BaseViewController {
    
    // MARK: - UI outlets
    @IBOutlet weak var favoriteButton: UIButton!
    @IBOutlet weak var listingImageView: UIImageView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var ratingView: CosmosView!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var tableViewHeightConstraint: NSLayoutConstraint!
    
    // MARK: - Private variables
    private var tableViewContentSizeObserver: NSKeyValueObservation?
    private var isFavorited: Bool!
    private var titleArray = ["", "LOCATION", "PHONE NUMBER"]
    
    // MARK: - Variables
    var listing: Listing?
    var delegate: FavoriteProtocol?

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        fillUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.navigationBar.tintColor = .white
    }
    
    deinit {
        tableViewContentSizeObserver = nil
    }
    
    // MARK: - Private functions
    private func setupUI() {
        
        clearNavBar()
        backBarButton()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorColor = .lightGray
        tableView.tableFooterView = UIView()
        tableView.estimatedRowHeight = 70
        tableView.rowHeight = UITableViewAutomaticDimension
        scrollView.delegate = self
        
        listingImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openImageGallery)))
        listingImageView.isUserInteractionEnabled = true
        
        // Subscribe to tableView height
        tableViewContentSizeObserver = tableView.observe(\.contentSize, changeHandler: { [unowned self] (tableView, _) in
            self.tableViewHeightConstraint.constant = tableView.contentSize.height
        })
    }
    
    private func fillUI() {
        
        guard
            let listing = listing,
            let uid = Auth.auth().currentUser?.uid
        else { return }
        
        listingImageView.setImage(url: URL(string: listing.imageURLs[0]))
        
        if listing.favoritedUIDs.contains(uid) {
            isFavorited = true
            favoriteButton.setImage(UIImage(named: "favorite"), for: .normal)
        } else {
            isFavorited = false
            favoriteButton.setImage(UIImage(named: "unfavorite"), for: .normal)
        }
        
        nameLabel.text = listing.name
        ratingView.rating = listing.calculateUserRate()
        priceLabel.text = "$ \(listing.price)"
    }
    
    @objc private func openImageGallery() {
        guard let vc = storyboard?.instantiateViewController(withIdentifier: "ImagesView") as? ImageViewViewController,
              let listing = listing
        else { return }
        vc.imagesArray = listing.imageURLs
        vc.modalTransitionStyle = .crossDissolve
        
        present(vc, animated: true, completion: nil)
    }
    
    //MARK: - Open Map With Coordinates
    @objc private func openMapOnLocation() {
        
        guard
            let listing = listing,
            let listingCoordinate = listing.coordinates else {
                presentAlert(message: "No location coordinates!")
                return
        }
        
        let coordinates = CLLocationCoordinate2DMake(listingCoordinate.latitude, listingCoordinate.longitude)
        let regionSpan = MKCoordinateRegionMakeWithDistance(coordinates, 50000, 50000)
        let options = [
            MKLaunchOptionsMapCenterKey: NSValue(mkCoordinate: regionSpan.center),
            MKLaunchOptionsMapSpanKey: NSValue(mkCoordinateSpan: regionSpan.span)
        ]
        let placemark = MKPlacemark(coordinate: coordinates, addressDictionary: nil)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = listing.name
        mapItem.openInMaps(launchOptions: options)
    }
    
    @IBAction func favoriteButtonAction(_ sender: UIButton) {
        
        guard
            let listing = listing,
            let uid = Auth.auth().currentUser?.uid,
            let selfUID = listing.selfUID
            else { return }
        
        if isFavorited {
            favoriteButton.setImage(UIImage(named: "unfavorite"), for: .normal)
            AppAPI.instance.favoriteListing(uid: uid, ownerUID: listing.uid, listingUID: selfUID, shouldFavorite: false)
        } else {
            favoriteButton.setImage(UIImage(named: "favorite"), for: .normal)
            AppAPI.instance.favoriteListing(uid: uid, ownerUID: listing.uid, listingUID: selfUID, shouldFavorite: true)
            presentAlert(message: "Successfully favorited listing!")
        }
        
        isFavorited = !isFavorited
        delegate?.didChangeFavoriteStatus(isFavorited)
    }
    
    @IBAction func bookButtonAction() {
        guard
            let listing = listing,
            let chooseDateViewController = storyboard?.instantiateViewController(withIdentifier: "ChooseDateViewController") as? ChooseDateViewController else { return }
        
        chooseDateViewController.listing = listing
        navigationController?.pushViewController(chooseDateViewController, animated: true)
    }
}

extension ListingDetailsViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard
            let cell = tableView.dequeueReusableCell(withIdentifier: "ListingDetailsTableViewCell", for: indexPath) as? ListingDetailsTableViewCell,
            let listing = listing
        else { return UITableViewCell() }
        cell.showDirectionsButton.addTarget(self, action: #selector(openMapOnLocation), for: .touchUpInside)
        cell.isExpanded = true
        cell.updateCell(listing: listing, index: indexPath.row, title: titleArray[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.row == 2 {
            guard
                let listing = listing,
                let url = URL(string: "tel://\(listing.phoneNumber)")
                else { return }
            
            if UIApplication.shared.canOpenURL(url) { UIApplication.shared.openURL(url) }
        }
    }
}

extension ListingDetailsViewController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        guard scrollView != tableView else { return }
        
        if scrollView.contentOffset .y > 0 { return }
        
        var scale = 1.0 + fabs(scrollView.contentOffset.y) / scrollView.frame.size.height
        
        scale = max(0.0, scale)
        
        listingImageView.transform = CGAffineTransform(scaleX: scale, y: scale)
    }
}
