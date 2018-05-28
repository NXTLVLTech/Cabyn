//
//  User.swift
//  Cabyn
//
//  Created by Lazar Vlaovic on 4/30/18.
//  Copyright © 2018 Lazar Vlaovic. All rights reserved.
//

import Foundation

class User {
    
    var name: String
    var email: String?
    var phoneNumber: String?
    var imageURL: String?
    var dateOfBirth: String?
    
    init(fullname: String, imageURL: String? = nil) {
        self.name = fullname
        self.imageURL = imageURL
        self.email = nil
        self.phoneNumber = nil
        self.dateOfBirth = nil
    }
    
    init?(dict: [String: AnyObject]) {
        
        guard
            let name = dict["fullname"] as? String,
            let email = dict["email"] as? String else { return nil }
        
        self.name = name
        self.email = email
        self.phoneNumber = dict["phoneNumber"] as? String ?? nil
        self.dateOfBirth = dict["dateOfBirth"] as? String ?? nil
        self.imageURL = dict["profileLink"] as? String ?? ""
    }
}
