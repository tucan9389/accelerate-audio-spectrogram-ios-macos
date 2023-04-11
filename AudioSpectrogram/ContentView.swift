/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The audio spectrogram content view.
*/

import SwiftUI

struct ContentView: View {
    
    @EnvironmentObject var audioSpectrogram: AudioSpectrogram
    
    var body: some View {
        
        VStack {
            
            Image(decorative: audioSpectrogram.outputImage,
                  scale: 1,
                  orientation: .left)
            .resizable()
            
            HStack {
                Text("Gain")
                Slider(value: $audioSpectrogram.gain,
                       in: 0.01 ... 0.04)
                
                Divider().frame(height: 40)
                
                Text("Zero Ref")
                Slider(value: $audioSpectrogram.zeroReference,
                       in: 10 ... 2500)
                
                Divider().frame(height: 40)
                
                Picker("Mode", selection: $audioSpectrogram.mode) {
                    ForEach(AudioSpectrogram.Mode.allCases) { mode in
                        Text(mode.rawValue.capitalized)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }
            .padding()
        }
    }
}
