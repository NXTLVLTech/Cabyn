//
//  BookingTableViewCell.swift
//  Cabyn
//
//  Created by Lazar Vlaovic on 4/30/18.
//  Copyright © 2018 Lazar Vlaovic. All rights reserved.
//

import UIKit
import Cosmos

class BookingTableViewCell: UITableViewCell {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var ratingView: CosmosView!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var numberOfReviewsLabel: UILabel!
    

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func updateCell(listing: Listing, uid: String) {
        nameLabel.text = listing.name
        if let bookedDates = listing.bookedDates {
            priceLabel.text = "$ \(listing.price / bookedDates.count) / per day"
        } else {
            priceLabel.text = "$ \(listing.price) per day"
        }
        ratingView.rating = listing.calculateUserRate()
        pageControl.currentPage = listing.selectedIndex
        pageControl.numberOfPages = listing.imageURLs.count
        numberOfReviewsLabel.text = "\(listing.rating.count) reviews"
    }
}
