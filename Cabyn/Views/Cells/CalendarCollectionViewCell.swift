//
//  CalendarCollectionViewCell.swift
//  Cabyn
//
//  Created by Lazar Vlaovic on 5/8/18.
//  Copyright © 2018 Lazar Vlaovic. All rights reserved.
//

import UIKit
import JTAppleCalendar

class CalendarCollectionViewCell: JTAppleCell {
    
    // MARK: - UI outlets
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var selectedView: UIView!
    @IBOutlet weak var rightView: UIView!
    @IBOutlet weak var leftView: UIView!
    
}
