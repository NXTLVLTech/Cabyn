//
//  UserDefaultsMapper.swift
//  OneTraffic
//
//  Created by Robert Černjanski on 12/6/17.
//  Copyright © 2017 Zesium. All rights reserved.
//

import Foundation


class UserDefaultsMapper {

    /// Clear all values saved in UserDefaults.
    static func clearUserDefaults() {
        UserDefaultsMapper.removeObjects(keys: UserDefaultKeys.getAllKeys())
    }
    
    static func saveMultiple(_ multipleObjects: [(object: Any, key: UserDefaultKeys)]) {
        
        for multipleObject in multipleObjects {
            UserDefaults.standard.set(multipleObject.object, forKey: multipleObject.key.rawValue)
        }
        
        UserDefaults.standard.synchronize()
    }

    static func save(_ object: Any, forKey key: UserDefaultKeys) {
        UserDefaults.standard.set(object, forKey: key.rawValue)
        UserDefaults.standard.synchronize()
    }

    static func removeObjects(keys: [UserDefaultKeys]) {

        for key in keys {
            UserDefaults.standard.removeObject(forKey: key.rawValue)
        }

        UserDefaults.standard.synchronize()
    }

    static func getObject(key: UserDefaultKeys) -> Any? {
        return UserDefaults.standard.object(forKey: key.rawValue)
    }
}
