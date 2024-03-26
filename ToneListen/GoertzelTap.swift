//
//  GoertzelTap.swift
//  tone-debug-visualizer
//
//  Created by Strut Company on 2/11/21.
//

// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKit/

import AVFoundation
import AudioKit
@_implementationOnly import CSoundpipeAudioKit
import CoreAudio

/// Tap to do pitch tracking on any node.
/// start() will add the tap, and stop() will remove it.
public class GoertzelTap: BaseTap {
    private var pitch: [Float] = [0, 0]
    private var amp: [Float] = [0, 0]
    private var detectedFrequencies : [Double] = [Double](repeating: 0, count: 1000)
    private var frequenciesToDetectLow : [Int] = []
    private var frequenciesToDetectHigh: [Int] = []
    private var frequenciesToDetect: [Int] = []
    private var detectedPowers: [Double] = [Double](repeating: 0, count: 1000)
    private var precalculatedK: [Double] = [Double](repeating: 0, count: 1000)
    private var precalculatedW: [Double] = [Double](repeating: 0, count: 1000)
    private var precalculatedCosines: [Double] = [Double](repeating: 0, count: 1000)
    private var precalculatedSines: [Double] = [Double](repeating: 0, count: 1000)
    private var precalculatedCoeff: [Double] = [Double](repeating: 0, count: 1000)
    private var lastTime: AVAudioTime? = nil
    //let systemVersion = ProcessInfo.processInfo.operatingSystemVersion


    private func readLocalFile(forName name: String) -> TableCodes? {

        
        do {
            let bundleTone = Bundle.allFrameworks.filter({$0.bundleIdentifier == "tone.example.br.ToneListen"}).first
            if let bundlePath = bundleTone?.path(forResource: name,
                                                 ofType: "json"),
                let jsonData = try String(contentsOfFile: bundlePath).data(using: .utf8) {
                let decodedData = try JSONDecoder().decode(TableCodes.self,
                                                           from: jsonData)
                return decodedData
                }
        } catch {
            print(error)
        }
        
        return nil
    }
 
    /// Detected amplitude (average of left and right channels)
    public var amplitude: Float {
        return amp.reduce(0, +) / 2
    }

    /// Detected frequency of left channel
    public var leftPitch: Float {
        return pitch[0]
    }

    /// Detected frequency of right channel
    public var rightPitch: Float {
        return pitch[1]
    }

    /// Callback type
    public typealias Handler = ([Int], [Double]) -> Void

    private var handler: Handler = { _, _ in }

    /// Initialize the pitch tap
    ///
    /// - Parameters:
    ///   - input: Node to analyze
    ///   - bufferSize: Size of buffer to analyze
    ///   - handler: Callback to call on each analysis pass
    public init(_ input: Node, bufferSize: UInt32 = 3584, handler: @escaping Handler) {
        //let version = (UIDevice.current.systemVersion as NSString).floatValue
        self.handler = handler
        super.init(input, bufferSize: bufferSize, callbackQueue: .global(qos: .default))
        var sampleRate: Double = 44100.00;
//        switch UIDevice.modelName {
//        case "iPhone 11", "iPhone 11 Pro" , "iPhone 11 Pro Max", "iPhone SE (2nd generation)", "iPhone 12 mini",
//            "iPhone 12", "iPhone 12 Pro","iPhone 12 Pro Max","iPhone 13 mini","iPhone 13","iPhone 13 Pro", "iPhone 13 Pro Max":
//            sampleRate = 48000.00
//        default:
//            print(UIDevice.modelName)
//        }
        
        
        print(sampleRate, "FRAMES")
        let minIndex = 4100.00 * 1024.00 / sampleRate
        let maxIndex = 8000.00 * 1024.00 / sampleRate
        let frequenciesCount = maxIndex - minIndex
        let frequenciesTable: TableCodes? = readLocalFile(forName: "frequency_tables")
        for low in frequenciesTable?.data ?? []{
            frequenciesToDetectLow.append(low.lowkey)
            for high in low.pairs{
                frequenciesToDetectHigh.append(high.highkey)
            }
        }
        for i in 0 ..< Int(frequenciesCount) {
            frequenciesToDetect.append(Int((sampleRate/1024.00) * (Double(i) + minIndex)))
        }
        let bridgeFrequencies = [14987, 15978, 16968, 17959, 18992, 19983, 20973]
        frequenciesToDetect.append(contentsOf: frequenciesToDetectLow)
        frequenciesToDetect.append(contentsOf: frequenciesToDetectHigh)
        frequenciesToDetect.append(contentsOf: bridgeFrequencies)
        frequenciesToDetect = frequenciesToDetect.uniqued().sorted()
        // Feed the frequencies from the JSON
        
        for(index, frequency) in frequenciesToDetect.enumerated() {
            let k = Int(0.5+(Double(bufferSize) * Double(frequency))/(sampleRate))
            let w = ((2.0 * (Double.pi / Double(bufferSize))) * Double(k))
            let cosine = cos(w)
            let sine = sin(w)
            let coeff = 2 * cosine
            
            precalculatedCosines[index] = cosine
            precalculatedSines[index] = sine
            precalculatedCoeff[index] = coeff
        }
        
        
    }

    deinit {
        
    }

    /// Stop detecting pitch
    override open func stop() {
        super.stop()
    }

    /// Overide this method to handle Tap in derived class
    /// - Parameters:
    ///   - buffer: Buffer to analyze
    ///   - time: Unused in this case
    override public func doHandleTapBlock(buffer: AVAudioPCMBuffer, at time: AVAudioTime) {
        let channels = UnsafeBufferPointer(start: buffer.floatChannelData, count: Int(buffer.format.channelCount))
        let floats = UnsafeBufferPointer(start: channels[1], count: Int(buffer.frameLength))
//        guard let floatData = buffer.floatChannelData else { return }
        for (index, frequency) in frequenciesToDetect.enumerated(){
//            let k = Int(0.5+(Double(buffer.frameLength) * Double(frequency))/(44100.00))
//            let w = ((2.0 * (Double.pi / Double(buffer.frameLength))) * Double(k))
//            let cosine = cos(w)
//            let sine = sin(w)
//            let coeff = 2 * cosine
            let cosine = precalculatedCosines[index]
            let sine = precalculatedSines[index]
            let coeff = precalculatedCoeff[index]
            
            var q0: Float
            var q1: Float = 0.0
            var q2: Float = 0.0
            
            var offload: UInt32 = 1
            if(frequency > 16000 && frequency < 18000){
                offload = 1
            }
            
            
            // change N samples to the lowest possible
            for N in 0 ..< buffer.frameLength {
                q0 = Float(coeff) * q1 - q2 + floats[Int(N)]
                q2 = q1
                q1 = q0
            }
            
            let real = (q1 - q2 * Float(cosine))
            let imag = (q2 * Float(sine))
            let magnitude2 = (pow(real, 2) + pow(imag, 2))
//            optimized goertzel
//            let magnitude2 = (q1 * q1) + (q2 * q2) - (q1*q2*coeff)
            detectedPowers[index] = Double(magnitude2) //* Double(magnitude2)
            
        }
        if(lastTime != nil){
//            print("Buffer Time Lenght:")
//            print("-------------------------Analysis--------------------------")
//            print(time.timeIntervalSince(otherTime: lastTime!)!)
        }
        lastTime = time
        self.handler(self.frequenciesToDetect, self.detectedPowers)
        
    }
       
}
extension Sequence where Element: Hashable {
    func uniqued() -> [Element] {
        var set = Set<Element>()
        return filter { set.insert($0).inserted }
    }
}
