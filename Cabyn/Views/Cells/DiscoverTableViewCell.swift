//
//  DiscoverTableViewCell.swift
//  Cabyn
//
//  Created by Lazar Vlaovic on 4/26/18.
//  Copyright © 2018 Lazar Vlaovic. All rights reserved.
//

import UIKit
import Cosmos

class DiscoverTableViewCell: UITableViewCell {
    
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
        priceLabel.text = "$ \(listing.price) / per day"
        ratingView.rating = listing.calculateUserRate()
        pageControl.currentPage = listing.selectedIndex
        pageControl.numberOfPages = listing.imageURLs.count
        numberOfReviewsLabel.text = "\(listing.rating.count) reviews"
    }
}

extension Listing {
    // MARK: - Rating Calculation From The Server
    
    func calculateUserRate() -> Double {
        
        if self.rating.count == 0 {
            return 0.0
        }
        
        var result: Double
        
        result = self.rating.map({$0.rating}).reduce(0, +)
        return result / Double(self.rating.count) // Addition all ratings and devide by number of ratings
    }
}
