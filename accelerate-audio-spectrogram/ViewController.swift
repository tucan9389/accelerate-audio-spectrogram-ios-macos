/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The view controller.
*/

import AVFoundation
import Accelerate
import UIKit

// Note that you must add a "Privacy - Microphone Usage Description" entry
// to `Info.plist`.

class ViewController: UIViewController {

    /// The audio spectrogram layer.
    let audioSpectrogram = AudioSpectrogram()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        audioSpectrogram.contentsGravity = .resize
        view.layer.addSublayer(audioSpectrogram)
  
        view.backgroundColor = .black
        
        audioSpectrogram.startRunning()
    }

    override func viewDidLayoutSubviews() {
        audioSpectrogram.frame = view.frame
    }
    
    override var prefersHomeIndicatorAutoHidden: Bool {
        true
    }
    
    override var prefersStatusBarHidden: Bool {
        true
    }
}
