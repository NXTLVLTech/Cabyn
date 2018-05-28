
//
//  Listing.swift
//  Cabyn
//
//  Created by Lazar Vlaovic on 4/28/18.
//  Copyright © 2018 Lazar Vlaovic. All rights reserved.
//

import Foundation
import MapKit

class Listing {
    
    var name: String
    var uid: String
    var description: String
    var isBooked: Bool
    var location: String
    var phoneNumber: String
    var selfUID: String?
    var timestamp: Double
    var imageURLs: [String]
    var rating: [RatingModel]
    var price: Int
    var selectedIndex: Int
    var favoritedUIDs: [String]
    var coordinates: CLLocationCoordinate2D?
    var formattedAddress: String
    var bookedDates: [Date]?
    
    init?(dict: [String: AnyObject]) {
        
        guard
            let name = dict["name"] as? String,
            let timestamp = dict["timestamp"] as? Double,
            let imageURLs = dict["images"] as? [String: String],
            let location = dict["location"] as? String,
            let uid = dict["uid"] as? String,
            let description = dict["description"] as? String,
            let isBooked = dict["isBooked"] as? Bool,
            let phoneNumber = dict["phoneNumber"] as? String,
            let price = dict["price"] as? String
            else { return nil }
        
        self.name = name
        self.uid = uid
        self.description = description
        self.isBooked = isBooked
        self.location = location
        self.phoneNumber = phoneNumber
        self.selfUID = dict["selfUID"] as? String ?? nil
        self.formattedAddress = dict["formattedAddress"] as? String ?? "No address"
        self.timestamp = timestamp
        self.price = Int(price) ?? 0
        selectedIndex = 0
        
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = Calendar.current.timeZone
        dateFormatter.dateFormat = "EEE, dd MMM, yyyy"
        let dates = dict["bookedDates"] as? String
        let d = dates?.components(separatedBy: ";") ?? nil
        
        if let d = d {
            self.bookedDates = d.map({dateFormatter.date(from: $0) ?? Date()})
        }
        
        self.imageURLs = imageURLs.map({$0.value})
        
        var ratingArray = [RatingModel]()
        
        if let ratingDict = dict["reviews"] as? [String: AnyObject] {
            
            for review in ratingDict {
                
                if let dict = review.value as? [String: AnyObject] {
                    
                    if let rateNumber = RatingModel(dict: dict) {
                        ratingArray.append(rateNumber)
                    }
                }
            }
        }
        
        self.rating = ratingArray
        
        var uids = [String]()
        
        if let uidsDict = dict["favoritedBy"] as? [String: AnyObject] {
            
            for review in uidsDict {
                
                uids.append(review.key)
            }
        }
        
        self.favoritedUIDs = uids
        
        if let coordinate = dict["coordinates"] as? [String: Any] {
            if let longitude = coordinate["longitude"] as? Double, let latitude = coordinate["latitude"] as? Double {
                self.coordinates = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            }
        }
    }
}
