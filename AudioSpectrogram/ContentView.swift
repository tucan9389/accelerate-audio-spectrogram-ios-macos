/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The audio spectrogram content view.
*/

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var audioSpectrogram: AudioSpectrogram
    
    var body: some View {
        #if os(iOS)
        iOSLayout
        #else
        macOSLayout
        #endif
    }
    
    // MARK: - Layouts
    private var macOSLayout: some View {
        VStack {
            SpectrogramImage(image: audioSpectrogram.outputImage)
            
            HStack {
                ControlGroup {
                    GainControl(gain: $audioSpectrogram.gain)
                    ZeroReferenceControl(reference: $audioSpectrogram.zeroReference)
                    ModeControl(mode: $audioSpectrogram.mode)
                }
            }
            .padding()
        }
    }
    
    private var iOSLayout: some View {
        VStack {
            SpectrogramImage(image: audioSpectrogram.outputImage)
            
            VStack(spacing: 20) {
                ControlGroup {
                    GainControl(gain: $audioSpectrogram.gain)
                }
                
                ControlGroup {
                    ZeroReferenceControl(reference: $audioSpectrogram.zeroReference)
                }
                
                ControlGroup {
                    ModeControl(mode: $audioSpectrogram.mode)
                }
            }
            .padding()
        }
    }
}

// MARK: - Subviews
private struct SpectrogramImage: View {
    let image: CGImage
    
    var body: some View {
        Image(decorative: image, scale: 1, orientation: .left)
            .resizable()
            .aspectRatio(contentMode: .fit)
    }
}

private struct ControlGroup<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        #if os(iOS)
        content
            .background(Color(.systemBackground))
            .cornerRadius(10)
            .shadow(radius: 1)
        #else
        content
        #endif
    }
}

private struct GainControl: View {
    @Binding var gain: Double
    
    var body: some View {
        HStack {
            Text("Gain")
                .frame(width: 60, alignment: .leading)
            
            Slider(value: $gain, in: 0.01...0.04)
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal)
        #if os(iOS)
        .padding(.vertical, 8)
        #endif
    }
}

private struct ZeroReferenceControl: View {
    @Binding var reference: Double
    
    var body: some View {
        HStack {
            Text("Zero Ref")
                .frame(width: 60, alignment: .leading)
            
            Slider(value: $reference, in: 10...2500)
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal)
        #if os(iOS)
        .padding(.vertical, 8)
        #endif
    }
}

private struct ModeControl: View {
    @Binding var mode: AudioSpectrogram.Mode
    
    var body: some View {
        VStack(alignment: .leading) {
            #if os(iOS)
            Text("Mode")
                .frame(width: 60, alignment: .leading)
                .padding(.horizontal)
            #endif
            
            Picker("Mode", selection: $mode) {
                ForEach(AudioSpectrogram.Mode.allCases) { mode in
                    Text(mode.rawValue.capitalized)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding(.horizontal)
        }
        #if os(iOS)
        .padding(.vertical, 8)
        #endif
    }
}

#Preview {
    ContentView()
        .environmentObject(AudioSpectrogram())
}
