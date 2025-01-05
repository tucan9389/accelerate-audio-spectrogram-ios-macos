//
//  AudioSpectrogram+Utility.swift
//  AudioSpectrogram
//
//  Created by Doyoung Gwak on 1/5/25.
//  Copyright © 2025 Apple. All rights reserved.
//

import Accelerate

extension AudioSpectrogram {
    /// Returns the RGB values from a blue -> red -> green color map for a specified value.
    ///
    /// Values near zero return dark blue, `0.5` returns red, and `1.0` returns full-brightness green.
    static var multidimensionalLookupTable: vImage.MultidimensionalLookupTable = {
        let entriesPerChannel = UInt8(32)
        let srcChannelCount = 1
        let destChannelCount = 3
        
        let lookupTableElementCount = Int(pow(Float(entriesPerChannel),
                                            Float(srcChannelCount))) *
        Int(destChannelCount)
        
        let tableData = [UInt16](unsafeUninitializedCapacity: lookupTableElementCount) {
            buffer, count in
            
            let multiplier = CGFloat(UInt16.max)
            var bufferIndex = 0
            
            for gray in (0 ..< entriesPerChannel) {
                let normalizedValue = CGFloat(gray) / CGFloat(entriesPerChannel - 1)
                let hue = 0.6666 - (0.6666 * normalizedValue)
                let brightness = sqrt(normalizedValue)
                
                let rgbValues = ColorUtility.rgbFrom(
                    hue: hue,
                    saturation: 1,
                    brightness: brightness
                )
                
                // Store values in consistent RGB order
                buffer[bufferIndex] = UInt16(rgbValues.green * multiplier)
                bufferIndex += 1
                buffer[bufferIndex] = UInt16(rgbValues.red * multiplier)
                bufferIndex += 1
                buffer[bufferIndex] = UInt16(rgbValues.blue * multiplier)
                bufferIndex += 1
            }
            
            count = lookupTableElementCount
        }
        
        let entryCountPerSourceChannel = [UInt8](repeating: entriesPerChannel,
                                               count: srcChannelCount)
        
        return vImage.MultidimensionalLookupTable(
            entryCountPerSourceChannel: entryCountPerSourceChannel,
            destinationChannelCount: destChannelCount,
            data: tableData
        )
    }()
}
