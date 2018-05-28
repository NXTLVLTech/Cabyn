//
//  BookingDetailsViewController.swift
//  Cabyn
//
//  Created by Lazar Vlaovic on 5/4/18.
//  Copyright © 2018 Lazar Vlaovic. All rights reserved.
//

import UIKit
import Firebase
import Stripe
import Alamofire


class BookingDetailsViewController: BaseViewController {
    
    // MARK: - UI outlets
    @IBOutlet weak var listingNameLabel: UILabel!
    @IBOutlet weak var checkInLabel: UILabel!
    @IBOutlet weak var checkOutLabel: UILabel!
    @IBOutlet weak var costLabel: UILabel!
    @IBOutlet weak var firstNameLabel: UILabel!
    @IBOutlet weak var lastNameLabel: UILabel!
    @IBOutlet weak var phoneNumberLabel: UILabel!
    @IBOutlet weak var priceBookingLabel: UILabel!
    @IBOutlet weak var numberOfBookingDaysLabel: UILabel!
    
    // MARK: - Private variables
    private var user: User?
    private lazy var dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = Calendar.current.timeZone
        dateFormatter.dateFormat = "EEE, dd MMM, yyyy"
        return dateFormatter
    }()
    
    // MARK: - Variables
    var listing: Listing?
    var selectedDates = [Date]()
    var rentierUser: User? {
        didSet {
            fillUserUI()
        }
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        fillUI()
        getRenterUserData()
    }
    
    
    // MARK: - Private methods
    private func setupUI() {
        
        darkBarButton()
        navigationController?.navigationBar.tintColor = .darkGray
    }
    
    private func fillUI() {
        
        guard let listing = listing else { return }
        
        listingNameLabel.text = listing.name
        costLabel.text = "$ \(listing.price * selectedDates.count)"
        priceBookingLabel.text = "$ \(listing.price * selectedDates.count)"
        numberOfBookingDaysLabel.text = "/ \(selectedDates.count) days"
        checkInLabel.text = dateFormatter.string(from: selectedDates.first ?? Date())
        checkOutLabel.text = dateFormatter.string(from: selectedDates.last ?? Date())
        phoneNumberLabel.text = listing.phoneNumber
    }
    
    private func fillUserUI() {
        guard let user = rentierUser else { return }
        
        var names = user.name.components(separatedBy: " ")
        let firstName = names.removeFirst()
        let lastName = names.joined(separator: " ")
        
        firstNameLabel.text = firstName
        lastNameLabel.text = lastName
    }
    
    // MARK: - Web services
    private func getRenterUserData() {
        
        guard let listing = listing else { return }
        
        showProgressHUD()
        
        AppAPI
            .instance.getUserProfileData(uid: listing.uid, success: { [weak self] (user) in
            
            self?.rentierUser = user
            self?.getUserData()
        }) { [weak self] (error) in
            self?.hideProgressHUD(animated: true, completionHandler: {
                self?.presentAlert(message: error)
            })
        }
    }
    
    private func getUserData() {
        
        guard let uid = Auth.auth().currentUser?.uid else {
            self.hideProgressHUD()
            return
        }
        
        AppAPI
            .instance.getUserProfileData(uid: uid, success: { [weak self] (user) in
            
            self?.user = user
            self?.hideProgressHUD()
        }) { [weak self] (error) in
            self?.hideProgressHUD(animated: true, completionHandler: {
                self?.presentAlert(message: error)
            })
        }
    }
    
    // MARK: - Button actions
    @IBAction func bookButtonAction() {
        
        if internetReachable {
            // Setup add card view controller
            let addCardViewController = STPAddCardViewController()
            addCardViewController.delegate = self
            
            // Present add card view controller
            let navigationController = UINavigationController(rootViewController: addCardViewController)
            present(navigationController, animated: true)
        } else {
            noInternetAlert()
        }
    }
}

// MARK: - Stripe delegates
extension BookingDetailsViewController: STPAddCardViewControllerDelegate {
    
    func addCardViewControllerDidCancel(_ addCardViewController: STPAddCardViewController) {
        // Dismiss add card view controller
        dismiss(animated: true)
        self.view.endEditing(true)
    }
    
    func addCardViewController(_ addCardViewController: STPAddCardViewController, didCreateToken token: STPToken, completion: @escaping STPErrorBlock) {
        
        submitTokenToBackend(token) { [weak self] (error) in
            
            if let error = error {
                // Show error in add card view controller
                completion(error)
            }
            else {
                // Notify add card view controller that token creation was handled successfully
                completion(nil)
                // Dismiss add card view controller
                self?.dismiss(animated: true, completion: {
                    
                    self?.saveBookingData()
                })
            }
        }
    }
    
    func submitTokenToBackend(_ token: STPToken, completion: @escaping (Error?) -> ()) {
        
        guard let listing = listing else { return }
        
        let parameters: Parameters = ["source": token.tokenId,
                                      "amount": (listing.price * selectedDates.count) * 100,
                                      "currency": "usd",
                                      "description": listing.description]
        
        let header = ["Authorization": stripeTestKey]
        
        Alamofire.request("https://api.stripe.com/v1/charges", method: .post, parameters: parameters, headers: header).responseString(completionHandler: { (response) in
            
            switch response.result {
                
            case .success:
                
                completion(nil)
            case .failure(let error):
                completion(error)
            }
        })
    }
    
    private func saveBookingData() {
        
        guard
            let listing = listing,
            let uid = Auth.auth().currentUser?.uid else { return }
        
        var images = [String: String]()
        
        for image in listing.imageURLs.reversed() {
            images.updateValue(image, forKey: dataBase.childByAutoId().key)
        }
        
        let dates = selectedDates.map({ dateFormatter.string(from: $0)}).joined(separator: ";")
        
        let dict = ["name": listing.name,
                    "location": listing.location,
                    "description": listing.description,
                    "phoneNumber": listing.phoneNumber,
                    "timestamp": Date().timeIntervalSince1970,
                    "bookedBy": uid,
                    "uid": listing.uid,
                    "isBooked": true,
                    "bookedDates": dates,
                    "favoritedBy": listing.favoritedUIDs.contains(uid) ? [uid: true] : [],
                    "images": images,
                    "price": "\(listing.price * selectedDates.count)",
                    "coordinates": ["longitude": listing.coordinates?.longitude ?? 0,
                                    "latitude": listing.coordinates?.latitude ?? 0]] as [String : Any]
        
        AppAPI.instance.saveBookedListing(forUID: uid, dict: dict)
        sendEmailToCustomer()
        sendEmailToRentier()
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "BookingNotification"), object: nil)
        navigationController?.popToRootViewController(animated: true)
    }
}

extension BookingDetailsViewController {
    
    func sendEmailToRentier() {
        
        guard let listing = listing,
              let rentierUser = rentierUser,
              let rentierEmail = rentierUser.email,
              let user = user
              else { return }
        
        let selectedDays = selectedDates.map({ dateFormatter.string(from: $0)}).joined(separator: " ;")
        
        
        let smtpSession = MCOSMTPSession()
        smtpSession.hostname = "smtp.gmail.com"
        smtpSession.username = "Cabynbookings@gmail.com"
        smtpSession.password = "Cabynbookings1$"
        smtpSession.port = 465
        smtpSession.authType = MCOAuthType.saslPlain
        smtpSession.connectionType = MCOConnectionType.TLS
        smtpSession.connectionLogger = {(connectionID, type, data) in
            if data != nil {
                if let string = NSString(data: data!, encoding: String.Encoding.utf8.rawValue){
                    print("Connectionlogger: \(string)")
                }
            }
        }
        
        let builder = MCOMessageBuilder()
        builder.header.to = [MCOAddress(displayName: rentierUser.name, mailbox: rentierEmail)]
        builder.header.from = MCOAddress(displayName: "Cabyn", mailbox: "Cabynbookings@gmail.com")
        builder.header.subject = "Cabyn Booking"
        builder.htmlBody = self.emailBody(listing: listing, user: user, bookingDates: selectedDays, numberOfDays: selectedDates.count)
        
        let rfc822Data = builder.data()
        let sendOperation = smtpSession.sendOperation(with: rfc822Data!)
        sendOperation?.start { (error) -> Void in
            if (error != nil) {
                print("Error sending email: \(error!)")
            } else {
                print("Successfully sent email!")
            }
        }
    }
    
    func sendEmailToCustomer() {
        
        guard let listing = listing,
              let user = user,
              let userEmail = user.email
              else { return }
        
        let selectedDays = selectedDates.map({ dateFormatter.string(from: $0)}).joined(separator: " ;")
        
        let smtpSession = MCOSMTPSession()
        smtpSession.hostname = "smtp.gmail.com"
        smtpSession.username = "Cabynbookings@gmail.com"
        smtpSession.password = "Cabynbookings1$"
        smtpSession.port = 465
        smtpSession.authType = MCOAuthType.saslPlain
        smtpSession.connectionType = MCOConnectionType.TLS
        smtpSession.connectionLogger = {(connectionID, type, data) in
            if data != nil {
                if let string = NSString(data: data!, encoding: String.Encoding.utf8.rawValue){
                    print("Connectionlogger: \(string)")
                }
            }
        }
        
        let builder = MCOMessageBuilder()
        builder.header.to = [MCOAddress(displayName: user.name, mailbox: userEmail)]
        builder.header.from = MCOAddress(displayName: "Cabyn", mailbox: "Cabynbookings@gmail.com")
        builder.header.subject = "Cabyn Booking"
        
        builder.htmlBody = self.emailBody(listing: listing, bookingDates: selectedDays, numberOfDays: selectedDates.count)
        
        let rfc822Data = builder.data()
        let sendOperation = smtpSession.sendOperation(with: rfc822Data!)
        sendOperation?.start { (error) -> Void in
            if (error != nil) {
                print("Error sending email: \(error!)")
            } else {
                print("Successfully sent email!")
            }
        }
    }
}

