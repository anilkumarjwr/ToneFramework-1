//
//  ToneFrameworkManager.swift
//  ToneListen
//
//  Created by Strut Company on 14/12/21.
//

import Foundation

public class ToneFrameworkManager{
    let recognizer: SwiftRecognizer
//    let audioReg: AudioRecognizer

    public init(observer: Observer){
        let subject = Subject()
        subject.attach(observer)
        recognizer = SwiftRecognizer(subject: subject)
//        audioReg = AudioRecognizer()
    }
    
    public func LogTone(message: String){
        print("ToneFrameworkTest: ", message)
    }
    
    public func startRecognizer(){
        LogTone(message: "Recognizer Started")
        recognizer.start()
//        DispatchQueue.global().async {
//            self.audioReg.run()
//        }
    }
    public func stopRecognizer(){
        LogTone(message: "Recognizer Finished")
        recognizer.stop()
    }
}
