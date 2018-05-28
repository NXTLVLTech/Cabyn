//
//  TutorialViewController.swift
//  Beautify
//
//  Created by Lazar Vlaovic on 2/27/18.
//  Copyright © 2018 Lazar Vlaovic. All rights reserved.
//

import UIKit

class TutorialViewController: BaseViewController {
    
    // MARK: - Outlets
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var nextButton: UIButton!
    
    // MARK: - Properties
    
    let tutorialBg = ["tut1", "tut2", "tut3"]
    let tutorialText = ["text1", "text2", "text3"]
    var scrollIndex: Int = 0
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
    }
    
    // MARK: - Setup View
    
    private func setupView() {
        
        collectionView.dataSource = self
        collectionView.delegate = self
        
        nextButton.setTitle("Next", for: .normal)
    }
    
    // MARK: - Private Functions
    
    private func closeTutorial() {
        UserDefaultsMapper.save(true, forKey: .tutorialWatched)
        loginRootViewController()
    }
    
    @IBAction func nextButtonAction(_ sender: UIButton) {
        
        scrollIndex = scrollIndex + 1
        
        if scrollIndex == 2 {
            nextButton.setTitle("Sign Up", for: .normal)
        } else {
            nextButton.setTitle("Next", for: .normal)
        }
        
        if scrollIndex == 3 {
            closeTutorial()
        } else {
            collectionView.scrollToItem(at: IndexPath(item: scrollIndex, section: 0), at: .left, animated: true)
        }
    }
}

extension TutorialViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return tutorialBg.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "tutorialCell", for: indexPath) as? TutorialCollectionViewCell {
            
            
            cell.image.image = UIImage(named: tutorialBg[indexPath.row])
            cell.text.image = UIImage(named: tutorialText[indexPath.row])
            return cell
            
        } else {
            return UICollectionViewCell()
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        
        let pageIndex = round(scrollView.contentOffset.x / view.frame.width)
        scrollIndex = Int(pageIndex)
        
        if scrollIndex == 2 {
           nextButton.setTitle("Sign Up", for: .normal)
        } else {
            nextButton.setTitle("Next", for: .normal)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        return collectionView.bounds.size
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return .leastNonzeroMagnitude
    }
}
