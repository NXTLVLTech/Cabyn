//
//  ImageView+Extension.swift
//  Cabyn
//
//  Created by Lazar Vlaovic on 4/28/18.
//  Copyright © 2018 Lazar Vlaovic. All rights reserved.
//

import Foundation
import Kingfisher

extension UIImageView {
    
    func setImage(url: URL?, defaultImage: UIImage? = nil) {
        
        self.kf.indicatorType = .activity
        
        if let unwURL = url {
            self.kf.setImage(
                with: unwURL,
                options: [.transition(ImageTransition.fade(0.5))],
                completionHandler: { [weak self] (image, _, _, _) in
                    if let unwImage = image {
                        self?.image = unwImage
                    } else {
                        self?.image = defaultImage
                    }
            })
        } else {
            self.image = defaultImage
        }
    }
}
