//
//  ViewController.swift
//  MineSweeper
//
//  Created by Mac21 on 07/03/24.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    @IBOutlet weak var btnMusic: UIButton!
    var audioPlayer: AVAudioPlayer?

    override func viewDidLoad() {
        super.viewDidLoad()

        if let path = Bundle.main.path(forResource: "OST", ofType: "mp3") {
            let url = URL(fileURLWithPath: path)
            do {
                print("Reproduciendo...")
                audioPlayer = try AVAudioPlayer(contentsOf: url)
                audioPlayer?.numberOfLoops = -1 // -1 For infinite loop
                audioPlayer?.prepareToPlay() // Prepare the audio player
                audioPlayer?.play()
            } catch {
                print("Couldn't load the file: \(error)") // Print detailed error
            }
        } else {
            print("Sound file does not exist in main bundle")
        }
    }
    

    @IBAction func btnMusicTapped(_ sender: UIButton) {
        if let player = audioPlayer {
            if player.isPlaying {
                player.pause()
                btnMusic.setTitle("Encender Música", for: .normal)
            } else {
                player.play()
                btnMusic.setTitle("Apagar Música", for: .normal)
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let player = audioPlayer, player.isPlaying {
            player.stop()
        }
    }
}




