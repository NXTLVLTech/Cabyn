//
//  CustomTabBarViewController.swift
//  Cabyn
//
//  Created by Lazar Vlaovic on 4/3/18.
//  Copyright © 2018 Lazar Vlaovic. All rights reserved.
//

import UIKit

class CustomTabBarViewController: UITabBarController {
    
    //MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let selectedColor   = UIColor.orange
        let unselectedColor = UIColor.lightGray
        UITabBarItem.appearance().setTitleTextAttributes([NSAttributedStringKey.foregroundColor: unselectedColor], for: .normal)
        UITabBarItem.appearance().setTitleTextAttributes([NSAttributedStringKey.foregroundColor: selectedColor], for: .selected)
        tabBar.tintColor = selectedColor
        tabBar.isTranslucent = false;
    }
    
}
