//
//  FacebookDataService.swift
//  Cabyn
//
//  Created by Lazar Vlaovic on 5/2/18.
//  Copyright © 2018 Lazar Vlaovic. All rights reserved.
//

import UIKit
import FBSDKLoginKit

class FacebookDataService {
    
    static func firebaseCredentialRequest(success: @escaping(User) -> Void, failure: @escaping(String) -> Void) {
        
        FBSDKGraphRequest(graphPath: "me",
                          parameters: ["fields": "email, first_name, last_name, picture.type(large)"])
            .start { (_, result, error) in
                
                // Check if error has occured
                if error != nil {
                    failure("There was a problem with getting your facebook information.")
                    return
                }
                
                guard let resultJSON = result else { return }
                
                let face = CabynFacebookResponseModel(object: resultJSON)
                
                let firstName = face.firstName ?? ""
                let lastName = face.lastName ?? ""
                let fullname = firstName + " " + lastName
                guard let _ = face.email else {
                    failure("Your facebook account doesn't have email.")
                    return
                }
                
                // Check if users facebook picture is just silhouette
                
                var imageURL: String?
                
                if face.picture?.data?.isSilhouette == false, let photoUrl = face.picture?.data?.url {
                    
                    imageURL = photoUrl
                }
                
                let user = User(fullname: fullname, imageURL: imageURL)
                
                success(user)
        }
    }
}
