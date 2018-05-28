//
//  PreLoginViewController.swift
//  Cabyn
//
//  Created by Lazar Vlaovic on 5/10/18.
//  Copyright © 2018 Lazar Vlaovic. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation

class PreLoginViewController: BaseViewController {
    
    // MARK: - Private variables
    var player: AVPlayer?

    override func viewDidLoad() {
        super.viewDidLoad()

        playBackgroundView()
        checkIfLoggedIn()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Private methods
    private func checkIfLoggedIn() {
        if UserDefaultsMapper.getObject(key: .tutorialWatched) != nil {
            if UserDefaultsMapper.getObject(key: .isLoggedIn) != nil {
                mainTabViewController()
            }
        } else {
            showTutorialScreen()
        }
    }
    
    //MARK: - Play Video as Background
    
    private func playBackgroundView() {
        
        // Load the video from the app bundle.
        let videoURL: URL = Bundle.main.url(forResource: "video", withExtension: "mp4")!
        
        player = AVPlayer(url: videoURL)
        player?.actionAtItemEnd = .none
        player?.isMuted = true
        
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        playerLayer.zPosition = -1
        
        playerLayer.frame = view.frame
        
        view.layer.addSublayer(playerLayer)
        
        player?.play()
        
        //loop video
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(loopVideo),
                                               name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                                               object: nil)
    }
    
    @objc func loopVideo() {
        player?.seek(to: kCMTimeZero)
        player?.play()
    }
    
    // MARK: - Button Actions
    
    @IBAction func signInButtonAction(_ sender: UIButton) {
        loginRootViewController()
    }

}
