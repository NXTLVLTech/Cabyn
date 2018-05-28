//
//  ListingDetailsTableViewCell.swift
//  Cabyn
//
//  Created by Lazar Vlaovic on 5/3/18.
//  Copyright © 2018 Lazar Vlaovic. All rights reserved.
//

import UIKit
import MapKit

class ListingDetailsTableViewCell: UITableViewCell {
    
    // MARK: - UI outlets
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var callLabel: UILabel!
    @IBOutlet weak var detailsImageView: UIImageView!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var showDirectionsButton: UIButton!
    
    // MARK: - Variables
    var isExpanded: Bool? = false
    
    func updateCell(listing: Listing, index: Int, title: String) {
        
        if index == 0 {
            titleLabel.isHidden = true
            titleLabel.text = title
            descriptionLabel.text = listing.description
            callLabel.text = " "
            detailsImageView.image = UIImage()
            mapView.isHidden = true
            showDirectionsButton.isHidden = true
        } else if index == 1 {
            titleLabel.isHidden = false
            titleLabel.text = title
            descriptionLabel.text = listing.location
            callLabel.text = " "
            detailsImageView.image = isExpanded! ? UIImage(named: "up") : UIImage(named: "down")
            mapView.isHidden = isExpanded! ? false : true
            showDirectionsButton.isHidden = isExpanded! ? false : true
            centerMapAndAddAnnotation(listing)
        } else if index == 2 {
            titleLabel.isHidden = false
            titleLabel.text = title
            descriptionLabel.text = listing.phoneNumber
            callLabel.text = "CALL"
            detailsImageView.image = UIImage(named: "Phone")
            mapView.isHidden = true
            showDirectionsButton.isHidden = true
        }
    }
    
    private func centerMapAndAddAnnotation(_ listing: Listing) {
        
        let regionRadius: CLLocationDistance = 1000
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(listing.coordinates ?? CLLocationCoordinate2D(latitude: 0, longitude: 0),
                                                                  regionRadius, regionRadius)
        mapView.setRegion(coordinateRegion, animated: true)
        
        let artwork = Artwork(title: listing.name,
                              locationName: listing.location,
                              discipline: listing.description,
                              coordinate: listing.coordinates!)
        mapView.addAnnotation(artwork)
    }

}
