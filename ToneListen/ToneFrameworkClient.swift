//
//  ToneFrameworkClien.swift
//  ToneDemoApp
//
//  Created by Strut Company on 15/12/21.
//

import Foundation


public class ToneFramework {
    var toneFrameworkManager : ToneFrameworkManager
    let notifications = NotificationsHandler.shared
    public static let shared = ToneFramework()
    public init(){
        print("Tone Framework Initialized")
       toneFrameworkManager = ToneFrameworkManager(observer: ToneUIEventListener())
    }
    public func start(){
        toneFrameworkManager.startRecognizer()
        notifications.requestPermission()
    }
    public func stop(){
        toneFrameworkManager.stopRecognizer()
    }
    
    public func setClientId(clientID: String){
        notifications.clientID = clientID
        print(notifications.clientID)
    }
}

class ToneUIEventListener : Observer {
    
    func update(subject: Subject) {
        print("ToneUIEventListener: ", subject.state)
        RemoteService.checkTone(detectedTone: subject.state)
    }
}
