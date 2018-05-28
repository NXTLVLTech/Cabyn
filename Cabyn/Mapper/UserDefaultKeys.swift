//
//  UserDefaultKeys.swift
//  OneTraffic
//
//  Created by Robert Černjanski on 1/23/18.
//  Copyright © 2018 Zesium. All rights reserved.
//

import Foundation

/*
 Everything added to the user defaults MUST be done via this enum.
 Make the string the exact same as the enum value. Also add documentation of the type that is stored to that key in the
 UserDefaults and explain in one sentence what this key is used for.
 */
enum UserDefaultKeys: String {
    
    case isLoggedIn
    case facebookAccount
    case tutorialWatched
    
    static func getAllKeys() -> [UserDefaultKeys] {
        return [.isLoggedIn, .facebookAccount, .tutorialWatched]
    }
}
