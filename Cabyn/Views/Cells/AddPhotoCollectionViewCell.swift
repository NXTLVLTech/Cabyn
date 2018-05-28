//
//  AddPhotoCollectionViewCell.swift
//  Cabyn
//
//  Created by Lazar Vlaovic on 4/28/18.
//  Copyright © 2018 Lazar Vlaovic. All rights reserved.
//

import UIKit

protocol DeletionDelegate: class {
    func didDeleteImage(index: Int)
}

class AddPhotoCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var deleteButton: UIButton!
    
    var index: Int?
    var delegate: DeletionDelegate?
    
    @IBAction func deletePhotoAction(_ sender: UIButton) {
        delegate?.didDeleteImage(index: index ?? 0)
    }
}
