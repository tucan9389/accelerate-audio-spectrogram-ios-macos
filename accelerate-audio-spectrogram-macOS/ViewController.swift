/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The view controller.
*/

import Cocoa
import Accelerate

// Note that you must add a "Privacy - Microphone Usage Description" entry
// to `Info.plist`, and check "audio input" and "camera access" under the
// "Resource Access" category of "Hardened Runtime".

class ViewController: NSViewController {

    /// The audio spectrogram layer.
    let audioSpectrogram = AudioSpectrogram()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        audioSpectrogram.startRunning()
    }

    override func viewWillAppear() {
        super.viewWillAppear()

        view.wantsLayer = true
        
        view.window?.title = "Audio Spectrogram"
        
        view.window?.setContentSize(NSSize(width: 1024,
                                           height: 768))
        view.window?.showsResizeIndicator = false
        view.window?.contentResizeIncrements = NSSize(width: Double.greatestFiniteMagnitude,
                                                      height: Double.greatestFiniteMagnitude)
        view.window?.center()

        view.layer!.addSublayer(audioSpectrogram)
        audioSpectrogram.frame = CGRect(origin: .zero,
                                        size: CGSize(width: 1024,
                                                     height: 768))
    }
}

