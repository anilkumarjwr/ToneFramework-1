@_implementationOnly import AudioKit
@_implementationOnly import AudioKitEX
@_implementationOnly import SwiftLocation
import UIKit

struct ToneDetection {
    var lastDetectedTone: String
    var lastDetectionTime: Date
}

class SwiftRecognizer: ObservableObject {
    var tracker: GoertzelTap!
    let engine = AudioEngine()
    var mic: AudioEngine.InputNode
    var tappableNode1: Fader
    var tappableNodeA: Fader
    var tappableNode2: Fader
    var tappableNodeB: Fader
    var tappableNode3: Fader
    var tappableNodeC: Fader
    var bandPassFilter: BandPassFilter?
    let noteFrequencies = [14987, 15978, 16968, 17959, 18992, 19983, 20973, 21964]
    var detectedTones: [ToneDetection] = []
    var timer: Timer?
    var shouldClearQueue: Bool = true
    var toneSequence: [String] = [String](repeating: "", count: 4)
    var firstKey: Bool = true
    var secondKey: Bool = false
    var thirdKey: Bool = false
    var fourthKey: Bool = false
    var keyIndex: Int = -1
    private var silenceTimer: Timer?
    private var lastToneTime: Date?
    init(subject: Subject) {
        guard let input = engine.input else {
            fatalError()
        }
        SwiftLocation.gpsLocation().then {
            print("Location is \(String(describing: $0.location))")
        }

        mic = input
        tappableNode1 = Fader(mic)
        tappableNode2 = Fader(tappableNode1)
        tappableNode3 = Fader(tappableNode2)
        tappableNodeA = Fader(tappableNode3)
        tappableNodeB = Fader(tappableNodeA)
        tappableNodeC = Fader(tappableNodeB)
        // Initialize and set up the bandpass filter
        let lowerFrequency: AUValue = 10000
        let upperFrequency: AUValue = 22000
        let centerFrequency = (lowerFrequency + upperFrequency) / 2
        let bandwidth = upperFrequency - lowerFrequency
        bandPassFilter = BandPassFilter(mic, centerFrequency: centerFrequency, bandwidth: bandwidth)
        // Attach the band pass filter to the audio chain
        let finalOutput = Fader(bandPassFilter!, gain: 0)
        engine.output = finalOutput
        let frequenciesToDetect: TableCodes? = readLocalFile(forName: "frequency_tables")
        startApiCallTimer()
        
        // Adjust your existing timer logic to respect the silence timer
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] (timer) in
            guard let self = self else { return }
            
            if self.silenceTimer == nil && (self.shouldClearQueue && keyIndex >= 0) {
                self.clearToneSequence()
            } else {
                self.shouldClearQueue = true
            }
        }
        
        tracker = GoertzelTap(mic){ outPutFrequencies, powers in
            
            DispatchQueue.main.async {
                var maxAmplitude2: Double = -500
                var maxFrequency2: Int = 0
                var maxAmplitude: Double = -500
                var maxFrequency: Int = 0
                var maxBridge: Int = 0
                var maxBridgeAmplitude: Double = 0
                var isDualTone: Bool = false
                var currentDualTone: String = ""
                var isBridge: Bool = false
                for (index,frequency) in outPutFrequencies.enumerated(){
                    if(index > 1 && index < outPutFrequencies.count - 1 && powers[index] > 0.0001){
                        if(powers[index] > powers[index - 1]){
                            if(powers[index] > powers[index + 1]){
                                if(maxAmplitude < powers[index]){
                                    maxAmplitude2 = maxAmplitude
                                    maxFrequency2 = maxFrequency
                                    maxAmplitude = powers[index]
                                    maxFrequency = Int(frequency)
                                }else if(maxAmplitude2 < powers[index]){
                                    maxAmplitude2 = powers[index]
                                    maxFrequency2 = Int(frequency)
                                }
                            }
                        }
                    }
                    if(index > 1 && index < outPutFrequencies.count - 1 && powers[index] > (frequency > 18000 ? 0.0001 : 0.1)){
                        if(powers[index] > powers[index - 1]){
                            if(powers[index] > powers[index + 1]){
                                if(maxBridgeAmplitude < powers[index]){
                                    if(self.noteFrequencies.contains(Int(frequency))){
                                        maxBridgeAmplitude = powers[index]
                                        maxBridge = Int(frequency)
                                    }
                                }
                            }
                        }
                    }
                }
                if maxAmplitude2 > Double(-500) {
                    let maxFre = Double(maxFrequency).rounded()
                    let maxFre2 = Double(maxFrequency2).rounded()
                    for lowFrequencies in frequenciesToDetect?.data ?? [] {
                        if(Int(lowFrequencies.lowkey) == Int(maxFre)){
                            for highfrequency in lowFrequencies.pairs{
                                if(Int(highfrequency.highkey) == Int(maxFre2)){
                                    isDualTone = true
                                    currentDualTone = highfrequency.tonetag
                                    print("currentDualTone::::::::::\(currentDualTone)")
                                    self.resetSilenceTimer()
                                    self.lastToneTime = Date()
                                    self.shouldClearQueue = false
                                }
                            }
                        }
                    }
                }
                
                var detectedTone: String = ""
                if(maxBridge != 0 && maxBridgeAmplitude > -100 && !isDualTone){
                    isBridge = true
                }
                if(self.firstKey && isDualTone){
                    self.keyIndex = 0
                    self.toneSequence[self.keyIndex] = currentDualTone
                    isDualTone = false
                    self.keyIndex = 1
                }
                if(self.firstKey && isBridge && self.keyIndex == 1){
                    self.firstKey = false
                    self.secondKey = true
                    isBridge = false
                }
                if(self.secondKey && isDualTone){
                    self.toneSequence[self.keyIndex] = currentDualTone
                    isDualTone = false
                    self.keyIndex = 2
                }
                if(self.secondKey && isBridge && self.keyIndex == 2){
                    self.secondKey = false
                    self.thirdKey = true
                    isBridge = false
                }
                if(self.thirdKey && isDualTone){
                    self.toneSequence[self.keyIndex] = currentDualTone
                    isDualTone = false
                    self.keyIndex = 3
                }
                if(self.thirdKey && isBridge && self.keyIndex == 3){
                    self.thirdKey = false
                    self.fourthKey = true
                    isBridge = false
                }
                if(self.fourthKey && isDualTone && self.keyIndex != 4){
                    self.toneSequence[self.keyIndex] = currentDualTone
                    self.keyIndex = 4
                    isDualTone = false
                }
                
                if(self.keyIndex == 4){
                    let detectedToneSequence = self.toneSequence.joined()
                    // Call processTone with the joined sequence
                    self.processTone(detectedToneSequence, subject: subject)
                    
                    self.clearToneSequence()
                    self.shouldClearQueue = true
                }
            }
        }
    }
    // Method to process and validate tones
    private func processTone(_ toneSequence: String, subject: Subject) {
        let currentTime = Date()
        let newTone = ToneDetection(lastDetectedTone: toneSequence, lastDetectionTime: currentTime)
        
        // Remove tones that are older than 2 minutes
        detectedTones = detectedTones.filter { currentTime.timeIntervalSince($0.lastDetectionTime) <= 120 }
        
        // Check if the new tone has been detected in the last 2 minutes
        if let existingToneIndex = detectedTones.firstIndex(where: { $0.lastDetectedTone == toneSequence }) {
            print("Tone already detected within the last 2 minutes: \(detectedTones[existingToneIndex].lastDetectedTone) at \(detectedTones[existingToneIndex].lastDetectionTime)")
        } else {
            detectedTones.append(newTone)
            subject.toneDetected(tone: toneSequence)
        }
    }

    func start() {

        do {
            try engine.start()
            tracker.start()
        } catch let err {
            Log(err)
        }
    }

    func stop() {
        engine.stop()
    }
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
            //print(error)
        }
        
        return nil
    }
    private func startApiCallTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) {  _ in
            RemoteService.checkToneHourly()
        }
    }
    private func resetSilenceTimer() {
        silenceTimer?.invalidate()
        silenceTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(handleSilence), userInfo: nil, repeats: false)
    }
    @objc private func handleSilence() {
        clearToneSequence()
    }
    
    private func clearToneSequence() {
        toneSequence = [String](repeating: "", count: 4)
        firstKey = true
        secondKey = false
        thirdKey = false
        fourthKey = false
        keyIndex = -1
    }
}
