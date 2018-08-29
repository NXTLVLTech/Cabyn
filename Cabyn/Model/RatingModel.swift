//
//  RatingModel.swift
//  Swopy
//
//  Created by Lazar Vlaovic on 4/22/18.
//  Copyright © 2018 lv. All rights reserved.
//

import Foundation

class RatingModel {
    
    var rating: Double
    var name: String
    var text: String
    
    init?(dict: [String: AnyObject]) {
        
        guard
            let rating = dict["rates"] as? Double,
            let name = dict["ratedBy"] as? String,
            let text = dict["text"] as? String
            else { return nil }
        
        self.rating = rating
        self.name = name
        self.text = text
    }
}
