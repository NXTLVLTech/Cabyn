//
//  ImageViewCollectionViewCell.swift
//  Beautify
//
//  Created by Lazar Vlaovic on 3/19/18.
//  Copyright © 2018 Lazar Vlaovic. All rights reserved.
//

import UIKit

class ImageViewCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var backImage: UIImageView!
    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var blurView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()

        let blurEffect = UIBlurEffect(style: .light)
        let blurredEffectView = UIVisualEffectView(effect: blurEffect)
        blurredEffectView.frame = blurView.bounds
        blurView.backgroundColor = .clear
        blurView.addSubview(blurredEffectView)
    }
    
    func updateCell(imageURL: String) {
        
        backImage.setImage(url: URL(string: imageURL))
        image.setImage(url: URL(string: imageURL))
    }
}
