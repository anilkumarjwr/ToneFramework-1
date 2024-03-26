@_implementationOnly import AudioKit
@_implementationOnly import AudioKitEX
@_implementationOnly import AudioKitUI
@_implementationOnly import AudioToolbox
@_implementationOnly import SoundpipeAudioKit
import SwiftUI
import Foundation
import CoreLocation
@_implementationOnly import SwiftLocation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif


struct TunerData {
    var pitch: Float = 0.0
    var amplitude: String = ""
    var noteNameWithSharps = "-"
    var noteNameWithFlats = "-"
    var toneSequence = ""
}

class TunerConductor: ObservableObject {
    let engine = AudioEngine()
    var mic: AudioEngine.InputNode
    var tappableNode1: Fader
    var tappableNodeA: Fader
    var tappableNode2: Fader
    var tappableNodeB: Fader
    var tappableNode3: Fader
    var tappableNodeC: Fader
    var tracker: GoertzelTap!
    var silence: Fader
    
    var firstPair: Bool = false
    var secondPair: Bool = false
    
    var firstRepeats: Int = 0
    var secondRepeats: Int = 0
    var queue = Queue<String>()
    var largeQueue = Queue<String>()
    
    var timer: Timer?
    var shouldClearQueue: Bool = true

    let noteFrequencies = [14987, 15978, 16968, 17959, 18992, 19983, 20973]
    let noteNamesWithSharps = ["C", "C♯", "D", "D♯", "E", "F", "F♯", "G", "G♯", "A", "A♯", "B"]
    let noteNamesWithFlats = ["C", "D♭", "D", "E♭", "E", "F", "G♭", "G", "A♭", "A", "B♭", "B"]


    @Published var data = TunerData()
    
    var detectedIndex: Int = 0
    var secondPairTries: Int = 0
    var lastFrequency: Int = 0
    var lastHighFrequency: Int = 0

    private func readLocalFile(forName name: String) -> TableCodes? {
        do {
            if let bundlePath = Bundle.main.path(forResource: name,
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
    
    func presentResponse(content:[String : Any]){
        let actionType: String = content["actionType"] as! String
        let actionUrl: String = content["actionURL"]  as! String
        print(actionType)
        print(actionUrl)
        DispatchQueue.main.async{
            if(actionType.contains("image")){
                if let url = URL(string: actionUrl) {
                    UIApplication.shared.open(url)
                }
            }
            if(actionType.contains("url")){
                if let url = URL(string: "tel://" + String(actionUrl.dropFirst(4))) {
                    UIApplication.shared.open(url)
                }
            }
            if(actionType.contains("webpage")){
                if let url = URL(string: actionUrl) {
                    UIApplication.shared.open(url)
                }
            }
        }
    }
    
    func update(_ pitch: AUValue, _ amp: AUValue) {
       
        if(pitch > 4000){
            data.pitch = pitch
           // data.amplitude = amp
            
        }

        var frequency = pitch
        while frequency > Float(noteFrequencies[noteFrequencies.count - 1]) {
            frequency /= 2.0
        }
        while frequency < Float(noteFrequencies[0]) {
            frequency *= 2.0
        }

        var minDistance: Float = 10_000.0
        var index = 0

        for possibleIndex in 0 ..< noteFrequencies.count {
            let distance = fabsf(Float(noteFrequencies[possibleIndex]) - frequency)
            if distance < minDistance {
                index = possibleIndex
                minDistance = distance
            }
        }
        let octave = Int(log2f(pitch / frequency))
        data.noteNameWithSharps = "\(noteNamesWithSharps[index])\(octave)"
        data.noteNameWithFlats = "\(noteNamesWithFlats[index])\(octave)"
    }

    init() {
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
        silence = Fader(tappableNodeC, gain: 0)
        engine.output = silence
        let frequenciesToDetect: TableCodes? = readLocalFile(forName: "frequency_tables")
        var lastKey: String = ""
        var firstDetect: Bool = true
        var hits: Int = 0
        var lastPairs: [String] = []
        var pairs: [String] = []
        var lastBridge: Int = 0
        var toneSequence: [String] = [String](repeating: "", count: 4)
        var firstKey: Bool = true
        var secondKey: Bool = false
        var thirdKey: Bool = false
        var fourthKey: Bool = false
        var keyIndex: Int = -1
        var lastDualTone: String = ""
        var keyCount: Int = 0
        var lastToneSequence = ""
        
        
        timer =  Timer.scheduledTimer(withTimeInterval: 0.50, repeats: true) { (timer) in
            if(self.shouldClearQueue && keyIndex >= 0){
                print("Clear Queue - Tuner")
                self.queue.clear()
                lastBridge = 0
                toneSequence = [String](repeating: "", count: 4)
                firstKey = true
                secondKey = false
                thirdKey = false
                fourthKey = false
                keyIndex = -1
                lastDualTone = ""
            }else{
                self.shouldClearQueue = true
            }
        }
        tracker = GoertzelTap(mic){ outPutFrequencies, powers in
            DispatchQueue.main.async {
//                print("--------------------------Buffer Analysis---------------------------------")
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
                                    maxAmplitude = maxAmplitude2
                                    maxFrequency2 = maxFrequency
                                    maxAmplitude = powers[index]
                                    maxFrequency = frequency

                                }else if(maxAmplitude2 < powers[index]){
                                    maxAmplitude2 = powers[index]
                                    maxFrequency2 = frequency
                                }
                            }
                        }
                    }
                    if(index > 1 && index < outPutFrequencies.count - 1 && powers[index] > (frequency > 18000 ? 0.0001 : 0.1)){
                        if(powers[index] > powers[index - 1]){
                            if(powers[index] > powers[index + 1]){
                                if(maxBridgeAmplitude < powers[index]){
                                    if(self.noteFrequencies.contains(frequency)){
                                        maxBridgeAmplitude = powers[index]
                                        maxBridge = frequency
                                    }
                                }
                            }
                        }
                    }
                }
                let interval: Int = 1
                if(maxFrequency != 0 && maxAmplitude != -500){
                    var isDetecting: Bool = false
                    if(maxAmplitude > -100 && maxAmplitude2 > -100){
                        for lowFrequencies in frequenciesToDetect?.data ?? [] {
                            let min: Int = maxFrequency - interval
                            let max: Int = maxFrequency + interval
                            if(Int(lowFrequencies.lowkey) > min && Int(lowFrequencies.lowkey) < max){
                                for highfrequency in lowFrequencies.pairs{
                                    let min2: Int = maxFrequency2 - interval
                                    let max2: Int = maxFrequency2 + interval
                                    if(Int(highfrequency.highkey) > min2 && Int(highfrequency.highkey) < max2){
                                        isDetecting = true
                                        let amplitudeRatio = (maxAmplitude2/maxAmplitude)
                                        let amplitudePercentage = amplitudeRatio * 100
                                        
                                        if(isDetecting && amplitudePercentage > 12){
                                            print("\(highfrequency.tonetag): \(lowFrequencies.lowkey) - \(highfrequency.highkey) \(maxAmplitude) - \(maxAmplitude2) - \(amplitudePercentage)%")
                                            isDualTone = true
                                            isDetecting = false
                                            currentDualTone = highfrequency.tonetag
                                            self.shouldClearQueue = false
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                var detectedTone: String = ""
                if(maxBridge != 0 && maxBridgeAmplitude > -100 && !isDualTone){
//                    self.largeQueue.enqueue("\(maxBridge)")

                    isBridge = true
                }
                
                if(firstKey && isDualTone){
                    keyIndex = 0
                    toneSequence[keyIndex] = currentDualTone
                    isDualTone = false
                    keyIndex = 1
//                    print("first Key")
                }
                if(firstKey && isBridge && keyIndex == 1){
                    firstKey = false
                    secondKey = true
                    isBridge = false
                    print("FirstKey Bridge -----------------------------------")
                    print("Bridge: \(maxBridge) -  \(maxBridgeAmplitude)")
                    print("second Key")
                }
                if(secondKey && isDualTone){
                    toneSequence[keyIndex] = currentDualTone
                    isDualTone = false
                    keyIndex = 2
                   
                }
                if(secondKey && isBridge && keyIndex == 2){
                    secondKey = false
                    thirdKey = true
                    isBridge = false
                    print("SecondKey Bridge ---------------------------------")
                    print("Bridge: \(maxBridge) -  \(maxBridgeAmplitude)")
                    print("Third Key")
                }
                if(thirdKey && isDualTone){
                    toneSequence[keyIndex] = currentDualTone
                    isDualTone = false
                    keyIndex = 3
                }
                if(thirdKey && isBridge && keyIndex == 3){
                    thirdKey = false
                    fourthKey = true
                    isBridge = false
                    print("Third Bridge ---------------------------------------")
                    print("Bridge: \(maxBridge) -  \(maxBridgeAmplitude)")
                    print("Last Key")
                }
                if(fourthKey && isDualTone && keyIndex != 4){
                    toneSequence[keyIndex] = currentDualTone
//                    firstKey = true
                    keyIndex = 4
                    isDualTone = false
                    
                   
                }
                if(keyIndex == 4){
                    for tone in toneSequence{
                        detectedTone.append(tone+" ")
                    }
                    if(lastToneSequence.contains(detectedTone)){
                        
                    }else{
                        print("---------------------Outoput-------------------------------")
                        print(detectedTone)
                        print("---------------------Outoput-------------------------------")
                        self.data.toneSequence.append("\n")
                        self.data.toneSequence.append(detectedTone+" ")
                    }
                    lastToneSequence = detectedTone
                    
                    self.shouldClearQueue = true
                    
                }
                
            }
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
}

struct TunerView: View {
    @StateObject var conductor = TunerConductor()
    @State private var showDevices: Bool = false

    var body: some View {
        VStack {
            HStack{
                Text("Tone Detection Demo iOS")
            }.padding()
//            HStack {
//                Text("Frequency")
//                Spacer()
//                Text("\(conductor.data.pitch, specifier: "%0.1f")")
//            }.padding()
//            HStack {
//                Text("Previous Tone")
//                Spacer()
//                Text("\(conductor.data.amplitude)")
//            }.padding()
//            HStack {
//                Text("Note Name")
//                Spacer()
//                Text("\(conductor.data.noteNameWithSharps) / \(conductor.data.noteNameWithFlats)")
//            }.padding()
            HStack {
                Text("\(conductor.data.toneSequence)").lineLimit(nil)
            }.padding()
//            HStack {
//                Text("Backend Response: ")
//                Spacer()
//                Text("\(conductor.data.noteNameWithSharps)")
//            }.padding()
            Button("\(conductor.engine.inputDevice?.deviceID ?? "Choose Mic")") {
                self.showDevices = true
            }
            Button("\("Clear Screen")") {
                self.conductor.data.toneSequence = ""
            }
//
//            NodeRollingView(conductor.tappableNodeB).clipped()
//            NodeOutputView(conductor.tappableNodeA).clipped()
//            NodeFFTView(conductor.tappableNodeC).clipped()

        }.navigationBarTitle(Text("Tuner"))
            .onAppear {
                self.conductor.start()
            }
            .onDisappear {
                self.conductor.stop()
            }.sheet(isPresented: $showDevices,
                    onDismiss: { print("finished!") },
                    content: { MySheet(conductor: self.conductor) })
    }
}

struct MySheet: View {
    @Environment(\.presentationMode) var presentationMode
    var conductor: TunerConductor

    func getDevices() -> [Device] {
        return AudioEngine.inputDevices.compactMap { $0 }
    }
    
//    override func viewDidLoad(){
//        super.viewDidLoad()
//        //_ = FrameworkLogger.init()
//    }

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            ForEach(getDevices(), id: \.self) { device in
                Text(device == self.conductor.engine.inputDevice ? "* \(device.deviceID)" : "\(device.deviceID)").onTapGesture {
                    do {
                        try AudioEngine.setInputDevice(device)
                    } catch let err {
                        print(err)
                    }
                }
            }
            Text("Dismiss")
                .onTapGesture {
                    self.presentationMode.wrappedValue.dismiss()
                }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .edgesIgnoringSafeArea(.all)
    }
}

struct TunerView_Previews: PreviewProvider {
    static var previews: some View {
        TunerView()
    }
}
