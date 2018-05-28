//
//  BookingCollectionViewCell.swift
//  Cabyn
//
//  Created by Lazar Vlaovic on 4/30/18.
//  Copyright © 2018 Lazar Vlaovic. All rights reserved.
//

import UIKit

class BookingCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var favoriteImageView: UIImageView!
    
    var index: Int!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        imageView.layer.cornerRadius = 4.0
    }
    
    func updateCell(listing: Listing, uid: String) {
        
        imageView.setImage(url: URL(string: listing.imageURLs[index]))
        
        if listing.favoritedUIDs.contains(uid) {
            favoriteImageView.image = UIImage(named: "favorite")
        } else {
            favoriteImageView.image = UIImage(named: "unfavorite")
        }
    }
}
