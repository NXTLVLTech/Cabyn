//
//  CreateListingViewController.swift
//  Cabyn
//
//  Created by Lazar Vlaovic on 4/28/18.
//  Copyright © 2018 Lazar Vlaovic. All rights reserved.
//

import UIKit
import GooglePlaces
import SwiftValidator
import Firebase
import KVNProgress
import MapKit

enum ListingViewType {
    case edit
    case create
}

class CreateListingViewController: BaseViewController {
    
    // MARK: - UI outlets
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var listingNameTextField: UITextField!
    @IBOutlet weak var addressTableView: UITableView!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var desctiptionTextField: UITextView!
    @IBOutlet weak var phoneNumberTextField: UITextField!
    @IBOutlet weak var dailyPriceTextField: UITextField!
    @IBOutlet weak var imagesCollectionView: UICollectionView!
    @IBOutlet weak var pageController: UIPageControl!
    @IBOutlet weak var addPhotoTableView: UITableView!
    @IBOutlet weak var saveListingButton: UIButton!
    @IBOutlet weak var mapView: MKMapView!
    
    // MARK: - Private proporties
    var capturedImageArray = [UIImage]() {
        didSet {
            imagesCollectionView.reloadData()
        }
    }
    var controllerType: ListingViewType!
    private let addressTableViewTag = 1
    private let photoTableViewTag = 2
    private var validator = Validator()
    private var allTextFields = [UITextField]()
    var listing: Listing?
    private var gmsPlace: GMSPlace? {
        didSet {
            if listing != nil {
                listing!.coordinates?.longitude = gmsPlace!.coordinate.longitude
                listing!.coordinates?.latitude = gmsPlace!.coordinate.latitude
                listing!.location = gmsPlace!.name
                listing!.formattedAddress = gmsPlace!.formattedAddress ?? gmsPlace!.name
            }
            centerMapAndAddAnnotation()
            addressLabel.text = gmsPlace!.name
            addressTableView.reloadData()
        }
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        generateTextFieldRules()
        setupUI()
        fillUI()
        centerMapAndAddAnnotation()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        addPhotoTableView.deselectRow(at: IndexPath(item: 0, section: 0), animated: true)
        addressTableView.deselectRow(at: IndexPath(item: 0, section: 0), animated: true)
    }
    
    // MARK: - Private functions
    
    private func setupUI() {
        
        switch controllerType ?? .create {
        case .create:
            titleLabel.text = "CREATE LISTING"
            saveListingButton.setTitle("Create Listing", for: .normal)
            addressLabel.text = gmsPlace?.name ?? "No Location Info"
            desctiptionTextField.text = "Enter your description"
            desctiptionTextField.textColor = .lightGray
        case .edit:
            titleLabel.text = "EDIT LISTING"
            saveListingButton.setTitle("Edit Listing", for: .normal)
        }
        
        imagesCollectionView.delegate = self
        imagesCollectionView.dataSource = self
        
        addressTableView.delegate = self
        addressTableView.dataSource = self
        addressTableView.tag = addressTableViewTag
        
        addPhotoTableView.delegate = self
        addPhotoTableView.dataSource = self
        addPhotoTableView.tag = photoTableViewTag
        
        desctiptionTextField.delegate = self
        
        pageController.numberOfPages = 1
        pageController.currentPage = 1
    }
    
    private func fillUI() {
        guard let listing = listing else { return }
        
        listingNameTextField.text = listing.name
        desctiptionTextField.text = listing.description
        phoneNumberTextField.text = listing.phoneNumber
        dailyPriceTextField.text = "\(listing.price)"
        addressLabel.text = listing.location
        pageController.numberOfPages = listing.imageURLs.count
        
        DispatchQueue.global().async {
            for imageURL in listing.imageURLs {
                
                let url = URL(string: imageURL)
                let data = try? Data(contentsOf: url!)
                DispatchQueue.main.async {
                    self.capturedImageArray.append(UIImage(data: data!)!)
                }
            }
        }
        
        addressTableView.reloadData()
    }
    
    private func generateTextFieldRules() {
        
        validator.registerField(listingNameTextField, rules: [RequiredRule(message: "Listing name is required.")])
        validator.registerField(phoneNumberTextField, rules: [RequiredRule(message: "Phone number is required.")])
        validator.registerField(dailyPriceTextField, rules: [RequiredRule(message: "Daily price is required.")])
        
        allTextFields = [listingNameTextField, phoneNumberTextField, dailyPriceTextField]
    }
    
    func centerMapAndAddAnnotation() {
        
        if let gmsPlace = gmsPlace {
            let regionRadius: CLLocationDistance = 1000
            let coordinateRegion = MKCoordinateRegionMakeWithDistance(gmsPlace.coordinate,
                                                                      regionRadius, regionRadius)
            mapView.setRegion(coordinateRegion, animated: true)
            
            let artwork = Artwork(title: listingNameTextField.text ?? "",
                                  locationName: gmsPlace.name,
                                  discipline: "",
                                  coordinate: gmsPlace.coordinate)
            mapView.addAnnotation(artwork)
        } else if let listing = listing {
            let regionRadius: CLLocationDistance = 1000
            let coordinateRegion = MKCoordinateRegionMakeWithDistance(listing.coordinates ?? CLLocationCoordinate2D(latitude: 0, longitude: 0),
                                                                      regionRadius, regionRadius)
            mapView.setRegion(coordinateRegion, animated: true)
            
            let artwork = Artwork(title: listing.name,
                                  locationName: listing.location,
                                  discipline: "",
                                  coordinate: listing.coordinates ?? CLLocationCoordinate2D(latitude: 0, longitude: 0))
            mapView.addAnnotation(artwork)
        }
    }
    
    private func presentGoogleAutocomplete() {
        
        let autocompleteController = GMSAutocompleteViewController()
        autocompleteController.delegate = self
        
        // Set a filter to return only addresses.
        let filter = GMSAutocompleteFilter()
        autocompleteController.autocompleteFilter = filter
        
        present(autocompleteController, animated: true, completion: nil)
    }
    
    private func presentCameraPicker() {
        presentCameraPhotoLibraryAlert(camera: { (_) in
            
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                
                let imagePicker = UIImagePickerController()
                imagePicker.delegate = self
                imagePicker.sourceType = .camera
                self.present(imagePicker, animated: true, completion: nil)
            } else {
                
                self.presentAlert(message: "Camera is not available.")
            }
        }, library: { (_) in
            
            if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
                
                let imagePicker = UIImagePickerController()
                imagePicker.delegate = self
                imagePicker.sourceType = .photoLibrary;
                self.present(imagePicker, animated: true, completion: nil)
            }
        })
    }
    
    // MARK: - Web services
    private func editListing() {
        
        guard
            let listing = listing,
            let uid = Auth.auth().currentUser?.uid,
            let coordinates = listing.coordinates,
            let selfUID = listing.selfUID
        else { return }
        
        guard let description = desctiptionTextField.text, description.count > 0 else {
            presentAlert(message: "Description is required")
            return
        }
        guard capturedImageArray.count > 0 else {
            presentAlert(message: "You must upload at least one photo.")
            return
        }
        
        var parameters = ["name": listingNameTextField.text ?? "",
                          "location": listing.location,
                          "formattedAddress": listing.formattedAddress,
                          "description": description,
                          "phoneNumber": phoneNumberTextField.text ?? listing.phoneNumber,
                          "uid": uid,
                          "isBooked": false,
                          "price": dailyPriceTextField.text ?? "\(listing.price)",
                          "coordinates": ["longitude": coordinates.longitude,
                                          "latitude": coordinates.latitude]]  as [String: AnyObject]
        
        var imageURLParameters: [String: String] = [:]
        
        showProgressHUD(animated: true)
        
        let myGroup = DispatchGroup()
        
        for image in capturedImageArray.reversed() {
            
            myGroup.enter()
            
            guard let imgData = UIImageJPEGRepresentation(image, 0.5) else {
                hideProgressHUD()
                continue
            }
            
            let metadata = StorageMetadata() ; metadata.contentType = "image/jpeg"
            let randomUID = NSUUID().uuidString
            
            AppAPI.instance.storageListingRef.child(randomUID).putData(imgData, metadata: metadata, completion: { [weak self] (metadata, error) in
                
                guard let unwSelf = self else {
                    self?.hideProgressHUD(animated: true)
                    return
                }
                
                if error != nil {
                    
                    unwSelf.hideProgressHUD(completionHandler: {
                        unwSelf.presentAlert(message: "Error with uploading an image to Firebase Storage.")
                    })
                } else {
                    
                    guard let downloadUrl = metadata?.downloadURL()?.absoluteString else { return }
                    
                    imageURLParameters[dataBase.childByAutoId().key] = downloadUrl
                    
                    myGroup.leave()
                }
            })
        }
        
        myGroup.notify(queue: .main) {
            print("Finished all requests.")
            parameters["images"] = imageURLParameters as AnyObject
            
            AppAPI.instance.editListing(forUID: uid, selfUID: selfUID, withParameters: parameters)
            
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    private func uploadListing() {
        
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        guard let description = desctiptionTextField.text, description.count > 0 else {
            presentAlert(message: "Description is required")
            return
        }
        
        guard let place = gmsPlace, let formattedAddress = place.formattedAddress else {
            presentAlert(message: "Location is required.")
            return
        }
        
        guard capturedImageArray.count > 0 else {
            presentAlert(message: "You must upload at least one photo.")
            return
        }
        
        var parameters = ["name": listingNameTextField.text ?? "",
                          "location": place.name,
                          "formattedAddress": formattedAddress,
                          "description": description,
                          "phoneNumber": phoneNumberTextField.text ?? "",
                          "timestamp": Date().timeIntervalSince1970,
                          "uid": uid,
                          "isBooked": false,
                          "price": dailyPriceTextField.text ?? "0",
                          "coordinates": ["longitude": place.coordinate.longitude,
                                         "latitude": place.coordinate.latitude]]  as [String: AnyObject]
        
        var imageURLParameters: [String: String] = [:]
        
        showProgressHUD(animated: true)
        
        let myGroup = DispatchGroup()
        
        for image in capturedImageArray.reversed() {
            
            myGroup.enter()
            
            guard let imgData = UIImageJPEGRepresentation(image, 0.5) else {
                hideProgressHUD()
                continue
            }
            
            let metadata = StorageMetadata() ; metadata.contentType = "image/jpeg"
            let randomUID = NSUUID().uuidString
            
            AppAPI.instance.storageListingRef.child(randomUID).putData(imgData, metadata: metadata, completion: { [weak self] (metadata, error) in
                
                guard let unwSelf = self else {
                    self?.hideProgressHUD(animated: true)
                    return
                }
                
                if error != nil {
                    
                    unwSelf.hideProgressHUD(completionHandler: {
                        unwSelf.presentAlert(message: "Error with uploading an image to Firebase Storage.")
                    })
                } else {
                    
                    guard let downloadUrl = metadata?.downloadURL()?.absoluteString else { return }
                    
                    imageURLParameters[dataBase.childByAutoId().key] = downloadUrl
                    
                    myGroup.leave()
                }
            })
        }
        
        myGroup.notify(queue: .main) {
            print("Finished all requests.")
            parameters["images"] = imageURLParameters as AnyObject
            
            AppAPI.instance.uploadListing(forUID: uid, withParameters: parameters as [String : AnyObject])
            
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    // MARK: - Button actions
    @IBAction func closeButtonAction(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func createListingButtonAction(_ sender: UIButton) {
        validator.validate(self)
    }
}

extension CreateListingViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, DeletionDelegate {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return capturedImageArray.count == 0 ? 1 : capturedImageArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AddPhotoCollectionViewCell", for: indexPath) as? AddPhotoCollectionViewCell else { return UICollectionViewCell() }
        cell.delegate = self
        cell.index = indexPath.row
        if capturedImageArray.count > 0 {
            cell.deleteButton.isHidden = false
            cell.imageView.image = capturedImageArray[indexPath.row]
        } else {
            cell.deleteButton.isHidden = true
            cell.imageView.image = UIImage(named: "map")
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: imagesCollectionView.frame.width, height: imagesCollectionView.frame.height)
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        
        let pageIndex = round(scrollView.contentOffset.x / view.frame.width)
        pageController.currentPage = Int(pageIndex)
    }
    
    func didDeleteImage(index: Int) {
        presentYesNoAlert(message: "Are you sure you want to delete this photo?", yesHandler: { [unowned self] (yesHandler) in
            self.capturedImageArray.remove(at: index)
            self.pageController.numberOfPages = self.capturedImageArray.count
            self.imagesCollectionView.reloadData()
        })
    }
}

extension CreateListingViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        switch tableView.tag {
        case addressTableViewTag:
            let cell = UITableViewCell(style: .default, reuseIdentifier: "ChangeAddressCell")
            if gmsPlace?.name != nil {
                cell.textLabel?.text = "Change Address"
            } else {
                cell.textLabel?.text = "Add Address"
            }
            
            cell.textLabel?.textColor = .orange
            cell.accessoryType = .disclosureIndicator
            return cell
        case photoTableViewTag:
            let cell = UITableViewCell(style: .default, reuseIdentifier: "AddPhotoCell")
            cell.textLabel?.text = "Add photo"
            cell.textLabel?.textColor = .orange
            cell.accessoryType = .disclosureIndicator
            return cell
        default:
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        switch tableView.tag {
        case addressTableViewTag:
            presentGoogleAutocomplete()
        case photoTableViewTag:
            presentCameraPicker()
        default:
            break
        }
    }
}

extension CreateListingViewController: GMSAutocompleteViewControllerDelegate {
    
    // Handle the user's selection.
    func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
        
        gmsPlace = place
        
        // Close the autocomplete widget.
        dismiss(animated: true, completion: nil)
    }
    
    func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
        // TODO: handle the error.
        print("Error: ", error.localizedDescription)
    }
    
    func wasCancelled(_ viewController: GMSAutocompleteViewController) {
        dismiss(animated: true, completion: nil)
    }
    
    // Show the network activity indicator.
    func didRequestAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    // Hide the network activity indicator.
    func didUpdateAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
}

extension CreateListingViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // MARK: - Image Delegates
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            
            capturedImageArray.append(image)
            pageController.numberOfPages = capturedImageArray.count
            imagesCollectionView.reloadData()
            dismiss(animated:true, completion: nil)
        } else {
            
            self.presentAlert(message: "Error with picking up image. Please choose another one.")
        }
    }
}

// MARK: - TextView delegates
extension CreateListingViewController: UITextViewDelegate {
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == UIColor.lightGray {
            textView.text = nil
            textView.textColor = UIColor.darkGray
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "Enter your description"
            textView.textColor = UIColor.lightGray
        }
    }
}

// MARK: - Swift Validator Delegate

extension CreateListingViewController: ValidationDelegate {
    
    func validationSuccessful() {
        if internetReachable {
            
            switch controllerType ?? .create {
            case .create:
                uploadListing()
            case .edit:
                editListing()
            }
        } else {
            noInternetAlert()
        }
    }
    
    func validationFailed(_ errors: [(Validatable, ValidationError)]) {
        for field in allTextFields {
            for error in errors where error.1.field === field {
                self.presentAlert(message: error.1.errorMessage)
                return
            }
        }
    }
}
