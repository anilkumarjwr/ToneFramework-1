//
//  ToneAPI.swift
//  ToneListen
//
//  Created by Strut Company on 15/12/21.
//

import Foundation
import Combine

public struct ToneFrameworkData {
    public var lastDetectedTone = ""
}

public class ToneAPI: ObservableObject & Observer{
    @Published public var data = ToneFrameworkData()
    public init(){
        
    }
    public func update(subject: Subject) {
        print("New state", subject.state)
        data.lastDetectedTone = subject.state
    }
}
