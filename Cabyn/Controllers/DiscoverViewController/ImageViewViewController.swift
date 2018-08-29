//
//  ImageViewViewController.swift
//  Beautify
//
//  Created by Lazar Vlaovic on 3/19/18.
//  Copyright © 2018 Lazar Vlaovic. All rights reserved.
//

import UIKit

class ImageViewViewController: UIViewController {
    
    //MARK: - Outlets
    
    @IBOutlet weak var collectionVIew: UICollectionView!
    
    //MARK: - Properties
    
    var imagesArray = [String]()
    var selectedIndexPath: IndexPath?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupView()
    }
    
    // MARK: - Private functions
    
    private func setupView() {
        
        // Adding swipe down gesture
        
        let slideDown = UISwipeGestureRecognizer(target: self, action: #selector(dismissView(gesture:)))
        slideDown.direction = .down
        view.addGestureRecognizer(slideDown)
        
        // Collection View Setup
        
        collectionVIew.delegate = self
        collectionVIew.dataSource = self
        
        collectionVIew.frame.size.height = view.bounds.height
        collectionVIew.frame.size.width = view.bounds.width
    }
    
    @objc func dismissView(gesture: UISwipeGestureRecognizer) {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Button Action
    
    @IBAction func closeButtonAction(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
}

// MARK: - Collection View DataSouce and Delegates

extension ImageViewViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imagesArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "imageCell", for: indexPath) as? ImageViewCollectionViewCell else { return UICollectionViewCell() }
        
        cell.updateCell(imageURL: imagesArray[indexPath.row])
        
        let blurEffect = UIBlurEffect(style: .dark)
        let blurredEffectView = UIVisualEffectView(effect: blurEffect)
        blurredEffectView.frame = collectionView.frame
        cell.blurView.backgroundColor = .clear
        cell.blurView.addSubview(blurredEffectView)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        return CGSize(width: collectionView.bounds.width, height: collectionView.bounds.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
}
