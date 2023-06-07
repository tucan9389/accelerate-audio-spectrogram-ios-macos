/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The audio spectrogram app file.
*/
import SwiftUI

@main
struct AudioSpectrogramApp: App {
    
    @Environment(\.scenePhase) private var scenePhase
    
    let audioSpectrogram = AudioSpectrogram()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(audioSpectrogram)
                .onChange(of: scenePhase) { phase in
                    if phase == .active {
                        Task(priority: .userInitiated) {
                            audioSpectrogram.startRunning()
                        }
                    }
                }
        }
    }
}
