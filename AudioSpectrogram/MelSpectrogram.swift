/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The mel spectrogram support.
*/

import Accelerate

class MelSpectrogram {
    
    let sampleCount: Int
    
    /// The number of mel filter banks  — the height of the spectrogram.
    static let filterBankCount = 40

    /// A matrix of `filterBankCount` rows and `sampleCount` that contain the triangular overlapping
    /// windows for each mel frequency.
    let filterBank: UnsafeMutableBufferPointer<Float>
    
    /// A buffer that contains the matrix multiply result of the current frame of frequency-domain values in
    /// `frequencyDomainBuffer` multiplied by the `filterBank` matrix.
    let sgemmResult: UnsafeMutableBufferPointer<Float>
    
    init(sampleCount: Int) {
        self.sampleCount = sampleCount
        
        filterBank = MelSpectrogram.makeFilterBank(
            withFrequencyRange: 20 ... 20_000,
            sampleCount: sampleCount,
            filterBankCount: MelSpectrogram.filterBankCount)
        
        sgemmResult = UnsafeMutableBufferPointer<Float>.allocate(capacity: MelSpectrogram.filterBankCount)
    }
    
    deinit {
        filterBank.deallocate()
        sgemmResult.deallocate()
    }
    
    /// Overwrites the provided frequency-domain values with their mel scale equivalents.
    ///
    /// This function multiplies the frequency-domain data in the `values` parameter by the `filterBank`
    /// matrix to generate  the `sgemmResult` product. The function overwrites the `values` with a
    /// linearly interpolated version of the product that contains `values.count` elements.
    ///
    /// The matrix multiply effectively creates a  vector of `filterBankCount` elements that summarizes
    /// the `sampleCount` frequency-domain values.  For example, given a vector of four frequency-domain
    /// values:
    /// ```
    ///  [ 1, 2, 3, 4 ]
    /// ```
    /// And a filter bank of three filters with the following values:
    /// ```
    ///  [ 0.5, 0.5, 0.0, 0.0,
    ///    0.0, 0.5, 0.5, 0.0,
    ///    0.0, 0.0, 0.5, 0.5 ]
    /// ```
    /// The result contains three values of:
    /// ```
    ///  [ ( 1 * 0.5 + 2 * 0.5) = 1.5,
    ///     (2 * 0.5 + 3 * 0.5) = 2.5,
    ///     (3 * 0.5 + 4 * 0.5) = 3.5 ]
    /// ```
    public func computeMelSpectrogram(values: inout [Float]) {
        values.withUnsafeBufferPointer { frequencyDomainValuesPtr in
            cblas_sgemm(CblasRowMajor,
                        CblasTrans, CblasTrans,
                        1,
                        Int32(MelSpectrogram.filterBankCount),
                        Int32(sampleCount),
                        1,
                        frequencyDomainValuesPtr.baseAddress,
                        1,
                        filterBank.baseAddress, Int32(sampleCount),
                        0,
                        sgemmResult.baseAddress, Int32(MelSpectrogram.filterBankCount))
        }
        
        /// Use linear interpolation to "stretch" the mulitplication result in `sgemmResult` to the number
        /// of elements in `values`.
        let indices = vDSP.ramp(in: 0 ... Float(sampleCount),
                                count: sgemmResult.count)
        vDSP.linearInterpolate(values: sgemmResult,
                               atIndices: indices,
                               result: &values)
    }
    
    /// Populates the specified `filterBank` with a matrix of overlapping triangular windows.
    ///
    /// For each frequency in `melFilterBankFrequencies`, the function creates a row in `filterBank`
    /// that contains a triangular window starting at the previous frequency, having a response of `1` at the
    /// frequency, and ending at the next frequency.
    private static func makeFilterBank(withFrequencyRange frequencyRange: ClosedRange<Float>,
                                       sampleCount: Int,
                                       filterBankCount: Int) -> UnsafeMutableBufferPointer<Float> {
        
        /// The `melFilterBankFrequencies` array contains `filterBankCount` elements
        /// that are indices of the `frequencyDomainBuffer`. The indices represent evenly spaced
        /// monotonically incrementing mel frequencies; that is, they're roughly logarithmically spaced as
        /// frequency in hertz.
        let melFilterBankFrequencies: [Int] = MelSpectrogram.populateMelFilterBankFrequencies(
            withFrequencyRange: frequencyRange,
            sampleCount: sampleCount,
            filterBankCount: filterBankCount)
        
        let capacity = sampleCount * filterBankCount
        let filterBank = UnsafeMutableBufferPointer<Float>.allocate(capacity: capacity)
        filterBank.initialize(repeating: 0)
        
        var baseValue: Float = 1
        var endValue: Float = 0
        
        for i in 0 ..< melFilterBankFrequencies.count {
            
            let row = i * sampleCount
            
            let startFrequency = melFilterBankFrequencies[ max(0, i - 1) ]
            let centerFrequency = melFilterBankFrequencies[ i ]
            let endFrequency = (i + 1) < melFilterBankFrequencies.count ?
            melFilterBankFrequencies[ i + 1 ] : sampleCount - 1
            
            let attackWidth = centerFrequency - startFrequency + 1
            let decayWidth = endFrequency - centerFrequency + 1
            
            // Create the attack phase of the triangle.
            if attackWidth > 0 {
                vDSP_vgen(&endValue,
                          &baseValue,
                          filterBank.baseAddress!.advanced(by: row + startFrequency),
                          1,
                          vDSP_Length(attackWidth))
            }
            
            // Create the decay phase of the triangle.
            if decayWidth > 0 {
                vDSP_vgen(&baseValue,
                          &endValue,
                          filterBank.baseAddress!.advanced(by: row + centerFrequency),
                          1,
                          vDSP_Length(decayWidth))
            }
        }
        
        return filterBank
    }
    
    /// Populates the specified `melFilterBankFrequencies` with a monotonically increasing series
    /// of indices into `frequencyDomainBuffer` that represent evenly spaced mels.
    private static func populateMelFilterBankFrequencies(withFrequencyRange frequencyRange: ClosedRange<Float>,
                                                         sampleCount: Int,
                                                         filterBankCount: Int) -> [Int] {
        func frequencyToMel(_ frequency: Float) -> Float {
            return 2595 * log10(1 + (frequency / 700))
        }
        
        func melToFrequency(_ mel: Float) -> Float {
            return 700 * (pow(10, mel / 2595) - 1)
        }
        
        let minMel = frequencyToMel(frequencyRange.lowerBound)
        let maxMel = frequencyToMel(frequencyRange.upperBound)
        let bankWidth = (maxMel - minMel) / Float(filterBankCount - 1)
        
        let melFilterBankFrequencies: [Int] = stride(from: minMel, to: maxMel, by: bankWidth).map {
            let mel = Float($0)
            let frequency = melToFrequency(mel)
            
            return Int((frequency / frequencyRange.upperBound) * Float(sampleCount))
        }
        return melFilterBankFrequencies
    }
}

