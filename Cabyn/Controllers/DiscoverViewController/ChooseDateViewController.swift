//
//  ChooseDateViewController.swift
//  Cabyn
//
//  Created by Lazar Vlaovic on 5/7/18.
//  Copyright © 2018 Lazar Vlaovic. All rights reserved.
//

import UIKit
import JTAppleCalendar

class ChooseDateViewController: BaseViewController {
    
    // MARK: - UI outlets
    @IBOutlet weak var calendarView: JTAppleCalendarView!
    @IBOutlet weak var currentMonthLabel: UILabel!
    
    // MARK: - Proporties
    var listing: Listing!
    let outsideMonthColor = UIColor.clear//UIColor.init(rgb:0x584a66)
    let monthColor = UIColor.black
    let selectedMonthColor = UIColor.init(rgb:0x3a294b)
    let currentDateSelectedViewColor = UIColor.init(rgb:0x4e3f5d)
    let selectedViewColor = UIColor.init(rgb:0xF5A623)
    let rangeColor = UIColor.init(rgb:0xfee9cf)
    var firstDate: Date?
    var lastDate: Date?
    var rangeSelectedDates: [Date] = []
    
    // MARK: - Private variables
    private let formatter = DateFormatter()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
    }
    
    // MARK: - Private methods
    private func setupUI() {
        
        darkBarButton()
        navigationController?.navigationBar.tintColor = .darkGray
        
        calendarView.calendarDataSource = self
        calendarView.calendarDelegate = self
        calendarView.allowsMultipleSelection = true
        calendarView.isRangeSelectionUsed = true
        
        calendarView.visibleDates { [weak self] (visibleDates) in
            guard let date = visibleDates.monthDates.first?.date else { return }
            self?.formatter.dateFormat = "yyyy MMMM"
            self?.currentMonthLabel.text = self?.formatter.string(from: date)
        }
    }
    
    // MARK: - Button actions
    @IBAction func nextButtonAction(_ sender: UIButton) {
        guard calendarView.selectedDates.count > 0 else {
            presentAlert(message: "Please choose booking date!")
            return
        }
        
        guard let bookingDetailsViewController = storyboard?.instantiateViewController(withIdentifier: "BookingDetailsViewController") as? BookingDetailsViewController else { return }
        
        bookingDetailsViewController.listing = listing
        bookingDetailsViewController.selectedDates = calendarView.selectedDates
        navigationController?.pushViewController(bookingDetailsViewController, animated: true)
    }
}

// MARK: - JTAppleCalendarView Delegates
extension ChooseDateViewController: JTAppleCalendarViewDataSource, JTAppleCalendarViewDelegate {
    
    func calendar(_ calendar: JTAppleCalendarView, willDisplay cell: JTAppleCell, forItemAt date: Date, cellState: CellState, indexPath: IndexPath) {
        
        handleCellSelected(view: cell, cellState: cellState)
        handleCellTextColor(view: cell, cellState: cellState)
        handleDateRangeSelection(view: cell, cellState: cellState)
        cell.layoutIfNeeded()

    }
    
    func configureCalendar(_ calendar: JTAppleCalendarView) -> ConfigurationParameters {
        formatter.dateFormat = "yyyy MM dd"
        formatter.timeZone = Calendar.current.timeZone
        formatter.locale = Calendar.current.locale
        
        let startDate = Date()
        let endDate = formatter.date(from: "2050 01 01") ?? Date()
        
        let parameters = ConfigurationParameters(startDate: startDate, endDate: endDate)
        return parameters
    }
    
    func calendar(_ calendar: JTAppleCalendarView, cellForItemAt date: Date, cellState: CellState, indexPath: IndexPath) -> JTAppleCell {
        
        guard let cell = calendar.dequeueReusableJTAppleCell(withReuseIdentifier: "CalendarCollectionViewCell", for: indexPath) as? CalendarCollectionViewCell else { return JTAppleCell() }
        cell.dateLabel.text = cellState.text
        handleCellSelected(view: cell, cellState: cellState)
        handleCellTextColor(view: cell, cellState: cellState)
        handleDateRangeSelection(view: cell, cellState: cellState)
        cell.layoutIfNeeded()
        return cell
    }
    
    func calendar(_ calendar: JTAppleCalendarView, didScrollToDateSegmentWith visibleDates: DateSegmentInfo) {
        
        guard let date = visibleDates.monthDates.first?.date else { return }
        formatter.dateFormat = "yyyy MMMM"
        currentMonthLabel.text = formatter.string(from: date)
    }
    
    func calendar(_ calendar: JTAppleCalendarView, didSelectDate date: Date, cell: JTAppleCell?, cellState: CellState) {
        handleCellSelected(view: cell, cellState: cellState)
        handleCellTextColor(view: cell, cellState: cellState)
        handleDateRangeSelection(view: cell, cellState: cellState)
        
        if firstDate != nil {
            if date < self.firstDate! {
                self.firstDate = date
            } else {
                self.lastDate = date
            }
            calendarView.selectDates(from: firstDate!, to: self.lastDate!,  triggerSelectionDelegate: false, keepSelectionIfMultiSelectionAllowed: true)
        } else {
            firstDate = date
            self.lastDate = date
        }
        
        //self.rangingStarted(cellState: cellState)
        cell?.bounce()
    }
    
    func calendar(_ calendar: JTAppleCalendarView, didDeselectDate date: Date, cell: JTAppleCell?, cellState: CellState) {
        
        handleCellSelected(view: cell, cellState: cellState)
        handleCellTextColor(view: cell, cellState: cellState)
        handleDateRangeSelection(view: cell, cellState: cellState)
        self.calendarView.deselectDates(from: self.firstDate!, to: self.lastDate!, triggerSelectionDelegate: false)
        if date != self.firstDate && date != self.lastDate {
            if date < self.firstDate! {
                self.firstDate = date
            } else {
                self.lastDate = date
            }
            calendarView.selectDates(from: firstDate!, to: self.lastDate!,  triggerSelectionDelegate: false, keepSelectionIfMultiSelectionAllowed: true)
            cell?.bounce()
        } else {
            self.firstDate = nil
            self.lastDate = nil
        }
        
    }
    
    func calendar(_ calendar: JTAppleCalendarView, shouldSelectDate date: Date, cell: JTAppleCell?, cellState: CellState) -> Bool {
        formatter.dateFormat = "yyyy MM dd"
        let todayDateString = formatter.string(from: Date())
        let monthsDateString = formatter.string(from: cellState.date)
        
        if cellState.dateBelongsTo != .thisMonth || (cellState.date < Date() && todayDateString != monthsDateString){
            return false
        } else {
            return true
        }
    }
    func calendar(_ calendar: JTAppleCalendarView, shouldDeselectDate date: Date, cell: JTAppleCell?, cellState: CellState) -> Bool {
        if cellState.dateBelongsTo == .thisMonth {
            return true
        } else {
            return false
        }
    }
    
    func handleCellTextColor(view: JTAppleCell?, cellState: CellState) {
        guard let validCell = view as? CalendarCollectionViewCell else { return }
        let todaysDate = Date()
        formatter.dateFormat = "yyyy MM dd"
        let todayDateString = formatter.string(from: todaysDate)
        let monthsDateString = formatter.string(from: cellState.date)
        if todayDateString == monthsDateString && cellState.dateBelongsTo == .thisMonth {
            validCell.dateLabel.textColor = UIColor.red
        } else if cellState.date < todaysDate && cellState.dateBelongsTo == .thisMonth{
            validCell.dateLabel.textColor = UIColor.lightGray
        }else {
            if cellState.isSelected {
                if cellState.dateBelongsTo == .thisMonth {
                    validCell.dateLabel.textColor = self.selectedMonthColor
                }
            } else {
                if cellState.dateBelongsTo == .thisMonth {
                    validCell.dateLabel.textColor = self.monthColor
                } else {
                    validCell.dateLabel.textColor = self.outsideMonthColor
                }
            }
        }
        
    }
    
    func handleCellSelected(view: JTAppleCell?, cellState: CellState) {
        guard let validCell = view as? CalendarCollectionViewCell else { return }
        
        if cellState.isSelected && cellState.dateBelongsTo == .thisMonth {
            validCell.selectedView.isHidden = false
        } else {
            validCell.selectedView.isHidden = true
            validCell.leftView.isHidden = true
            validCell.rightView.isHidden = true
            validCell.backgroundColor = UIColor.clear
            validCell.dateLabel.isHidden = false
            
        }
    }
    
    func handleDateRangeSelection(view: JTAppleCell?, cellState: CellState) {
        guard let cell = view as? CalendarCollectionViewCell else { return }
        if calendarView.allowsMultipleSelection {
            if cellState.isSelected {
                if cellState.dateBelongsTo == .thisMonth {
                    cell.selectedView.isHidden = false
                } else {
                    cell.selectedView.isHidden = true
                }
                switch cellState.selectedPosition() {
                    
                case .full:
                    cell.dateLabel.isHidden = false
                    cell.backgroundColor = UIColor.clear
                    cell.selectedView.backgroundColor = self.selectedViewColor
                    cell.leftView.isHidden = true
                    cell.rightView.isHidden = true
                case .right:
                    //cell.selectedView.isHidden = false
                    if cellState.dateBelongsTo != .thisMonth {
                        cell.leftView.isHidden = true
                    } else {
                        cell.leftView.isHidden = false
                    }
                    cell.backgroundColor = UIColor.white
                    cell.selectedView.backgroundColor = self.selectedViewColor
                case .left:
                    //cell.selectedView.isHidden = false
                    if cellState.dateBelongsTo != .thisMonth {
                        cell.rightView.isHidden = true
                    } else {
                        cell.rightView.isHidden = false
                    }
                    cell.backgroundColor = UIColor.white
                    cell.selectedView.backgroundColor = self.selectedViewColor
                case .middle:
                    if cellState.dateBelongsTo != .thisMonth {
                        cell.dateLabel.isHidden = true
                    } else {
                        cell.dateLabel.isHidden = false
                    }
                    cell.backgroundColor = self.rangeColor
                    cell.leftView.isHidden = true
                    cell.rightView.isHidden = true
                    cell.selectedView.backgroundColor = self.rangeColor // Or what ever you want for your dates that land in the middle
                default:
                    cell.backgroundColor = UIColor.white
                    cell.dateLabel.isHidden = false
                    cell.leftView.isHidden = true
                    cell.rightView.isHidden = true
                    cell.selectedView.isHidden = true
                    cell.selectedView.backgroundColor = nil // Have no selection when a cell is not selected
                }
            }
            
        }
    }
}

extension UIColor {
    convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }
    
    convenience init(rgb: Int) {
        self.init(
            red: (rgb >> 16) & 0xFF,
            green: (rgb >> 8) & 0xFF,
            blue: rgb & 0xFF
        )
    }
}

extension UIView {
    func bounce() {
        self.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        UIView.animate(withDuration: 0.5,
                       delay: 0,
                       usingSpringWithDamping: 0.3,
                       initialSpringVelocity: 0.1,
                       options: UIViewAnimationOptions.beginFromCurrentState,
                       animations: {
                        self.transform = CGAffineTransform(scaleX: 1, y: 1)
        }, completion: nil)
    }
}

