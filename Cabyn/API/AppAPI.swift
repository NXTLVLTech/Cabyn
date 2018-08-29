//
//  AppAPI.swift
//  Cabyn
//
//  Created by Lazar Vlaovic on 4/25/18.
//  Copyright © 2018 Lazar Vlaovic. All rights reserved.
//

import Foundation
import Firebase
import FirebaseStorage

let dataBase = Database.database().reference()
let storageBase = Storage.storage().reference()

class AppAPI {
    
    static let instance = AppAPI()
    
    //Database Refrences
    let userRefrence = dataBase.child("users")
    let listingReftence = dataBase.child("listings")
    let bookingReference = dataBase.child("bookings")
    
    //Storage Refrences
    let storageProfileRef = storageBase.child("profile-pics")
    let storageListingRef = storageBase.child("listings")
    
    func registerUser(uid: String, dict: [String: Any]) {
        userRefrence.child(uid).updateChildValues(dict)
    }
    
    func saveUserData(uid: String, dict: [String: AnyObject]) {
        userRefrence.child(uid).updateChildValues(dict)
    }
    
    func uploadListing(forUID uid: String, withParameters parameters: [String: AnyObject]) {
        var params = parameters
        let autoID = dataBase.childByAutoId().key
        params["selfUID"] = autoID as AnyObject
        listingReftence.child(uid).child(autoID).updateChildValues(params)
    }
    
    func editListing(forUID uid: String, selfUID: String, withParameters parameters: [String: AnyObject]) {
        listingReftence.child(uid).child(selfUID).updateChildValues(parameters)
    }
    
    func getAllListings(forUID uid: String, success: @escaping([Listing]) -> Void, failure: @escaping(String) -> Void) {
        
        listingReftence.child(uid).observe(.value) { (snapshot) in
            
            guard let listingSnapshot = snapshot.children.allObjects as? [DataSnapshot] else {
                failure(self.generateError())
                return
            }
            
            var listingArray = [Listing]()
            
            for listing in listingSnapshot {
                
                guard let dict = listing.value as? [String: AnyObject],
                    let listing = Listing(dict: dict)
                    else { continue }
                    
                    listingArray.append(listing)
                
            }
            
            success(listingArray)
        }
    }
    
    func getAllBookedListings(forUID uid: String, success: @escaping([Listing]) -> Void, failure: @escaping(String) -> Void) {
        
        bookingReference.child(uid).observe(.value) { (snapshot) in
            
            guard let listingSnapshot = snapshot.children.allObjects as? [DataSnapshot] else {
                failure(self.generateError())
                return
            }
            
            var listingArray = [Listing]()
            
            for listing in listingSnapshot {
                
                guard let dict = listing.value as? [String: AnyObject],
                    let listing = Listing(dict: dict)
                    else { continue }
                
                listingArray.append(listing)
                
            }
            
            success(listingArray)
        }
    }
    
    func getAllAvailableListings(success: @escaping([Listing]) -> Void, failure: @escaping(String) -> Void) {
        
        listingReftence.observe(.value) { (snapshot) in
            
            guard let listingSnapshot = snapshot.children.allObjects as? [DataSnapshot] else {
                failure(self.generateError())
                return
            }
            
            var listingArray = [Listing]()
            
            for listing in listingSnapshot {
                
                guard let listingDictArray = listing.value as? [String: AnyObject] else { continue }
                
                for dict in listingDictArray {
                    
                    guard
                        let listingDict = dict.value as? [String: AnyObject],
                        let listing = Listing(dict: listingDict)
                        else { continue }
                    
                    listingArray.append(listing)
                }
            }
            
            success(listingArray)
        }
    }
    
    func getUserProfileData(uid: String, success: @escaping(User) -> Void, failure: @escaping(String) -> Void) {
        
        userRefrence.child(uid).observe(.value) { (snapshot) in
            guard let dict = snapshot.value as? [String: AnyObject] else {
                failure(self.generateError())
                return
            }
            
            guard let userModel = User(dict: dict) else {
                failure(self.generateError())
                return
            }
            
            success(userModel)
        }
    }
    
    func favoriteListing(uid: String, ownerUID: String, listingUID: String, shouldFavorite: Bool) {
        
        if shouldFavorite {
            listingReftence.child(ownerUID).child(listingUID).child("favoritedBy").updateChildValues([uid: true])
        } else {
            listingReftence.child(ownerUID).child(listingUID).child("favoritedBy").child(uid).removeValue()
        }
    }
    
    func saveBookedListing(forUID uid: String, dict: [String: Any]) {
        bookingReference.child(uid).childByAutoId().updateChildValues(dict)
    }
}

extension AppAPI {
    private func generateError() -> String {
        return "There was a problem with the server!"
    }
}
