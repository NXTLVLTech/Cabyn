//
//  BookedListingDetails.swift
//  Cabyn
//
//  Created by Lazar Vlaovic on 5/4/18.
//  Copyright © 2018 Lazar Vlaovic. All rights reserved.
//

import UIKit
import Cosmos
import Firebase
import MapKit

class BookedListingDetails: BaseViewController {
    
    // MARK: - UI outlets
    @IBOutlet weak var listingImageView: UIImageView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var ratingView: CosmosView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var tableViewHeightConstaint: NSLayoutConstraint!
    
    // MARK: - Proporties
    
    var listing: Listing?
    var isFavorited: Bool!
    var titleArray = ["", "LOCATION", "PHONE NUMBER"]
    
    // MARK: - Private variables
    private var tableViewContentSizeObserver: NSKeyValueObservation?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        fillUI()
    }
    
    deinit {
        tableViewContentSizeObserver = nil
    }
    
    // MARK: - Private methods
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
            self.tableViewHeightConstaint.constant = tableView.contentSize.height
        })
    }
    
    private func fillUI() {
        
        guard let listing = listing else { return }
        
        listingImageView.setImage(url: URL(string: listing.imageURLs[0]))
        
        nameLabel.text = listing.name
        ratingView.rating = listing.calculateUserRate()
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
}

extension BookedListingDetails: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard
            let cell = tableView.dequeueReusableCell(withIdentifier: "ListingDetailsTableViewCell", for: indexPath) as? ListingDetailsTableViewCell,
            let listing = listing
            else { return UITableViewCell() }
        cell.isExpanded = true
        cell.showDirectionsButton.addTarget(self, action: #selector(openMapOnLocation), for: .touchUpInside)
        cell.updateCell(listing: listing, index: indexPath.row, title: titleArray[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.row == 2 {
            guard
                let listing = listing,
                let url = URL(string: "tel://\(listing.phoneNumber)")
                else { return }
            
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
}

extension BookedListingDetails: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        guard scrollView != tableView else { return }
        
        if scrollView.contentOffset .y > 0 { return }
        
        var scale = 1.0 + fabs(scrollView.contentOffset.y) / scrollView.frame.size.height
        
        scale = max(0.0, scale)
        
        listingImageView.transform = CGAffineTransform(scaleX: scale, y: scale)
    }
}
