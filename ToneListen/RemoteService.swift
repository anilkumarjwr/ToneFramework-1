//
//  RemoteService.swift
//  ToneListen
//
//  Created by Strut Company on 15/12/21.
//

import Foundation
import SwiftLocation
import UIKit
public class RemoteService{
    
   private class RemoteServiceMethods{
       static func sendRequest(detectedTone: String){
            DispatchQueue.main.async {
                let modelName = UIDevice.modelName
                let now = Date()
                let formatter = DateFormatter()
                formatter.timeZone = TimeZone.current
                formatter.dateFormat = "yyyy-MM-dd HH:mm"
                let dateString = formatter.string(from: now)
                let location = SwiftLocation.lastKnownGPSLocation
                let systemVersion = UIDevice.current.systemVersion
                let notifications = NotificationsHandler.shared
                let Url = String(format: "https://demo.tonedashboard.com/tone/api/api/toneresponse")
                guard let serviceUrl = URL(string: Url) else { return }
    //                                print(detectedTone)
                let parameterDictionary = ["clientName": notifications.clientID,
                                           "deviceInfo": "\(modelName), iOS, \(systemVersion), \(UIDevice.current.identifierForVendor!.uuidString)",
                                           "locationInfo": "\(location!.coordinate.latitude),\(location!.coordinate.longitude)",
                                           "tonePacketDate":"\(dateString)",
                                           "toneSequence":"\(detectedTone)"]
                
//                print(parameterDictionary)
                var request = URLRequest(url: serviceUrl)
                request.httpMethod = "POST"
                request.setValue("application/json; charset=UTF-8", forHTTPHeaderField: "Content-Type")
                guard let httpBody = try? JSONSerialization.data(withJSONObject: parameterDictionary, options: []) else {
                    return
                }
                request.httpBody = httpBody
    //                                print(httpBody)

                let session = URLSession.shared
                session.dataTask(with: request) { (data, response, error) in
                    if let response = response {
                       // print(response)

                    }
                    if let data = data {
                        do {
                            let json: [String: Any] = try JSONSerialization.jsonObject(with: data, options: []) as! [String : Any]
//                            print(json)
                            let status:String = json["status"] as? String ?? "-";
                            var content: [String : Any] = json["content"] as! [String : Any]
                            let actionType: String = content["actionType"] as? String ?? ""
                            let actionUrl: String = content["actionURL"]  as? String ?? ""
                            content["clientId"] = notifications.clientID
                            if(status.contains("200")){
//                                print("RemoteService")
                                notifications.contentResponse = content
                                DispatchQueue.main.async{
                                   
                                    switch UIApplication.shared.applicationState {
                                        case .background, .inactive:
                                        let notifications = NotificationsHandler.shared
                                        NotificationCenter.default.post(name: NotificationsHandler.responseObjectNotificationName, object: content)
                                        print("Code OK, in .background & .inactive case")
                                        notifications.sendNotification(actionType: actionType, actionURL: actionUrl)
                                        break
                                        case .active:
                                        NotificationCenter.default.post(name: NotificationsHandler.responseObjectNotificationName, object: content)
                                            print("Code OK, in .active case")
                                        handleContent(actionType:actionType, actionUrl: actionUrl)
                                        default:
                                            break
                                    }
                                }
                                
    //                            self.presentResponse(content: json["content"] as! [String : Any])
                            }else{
                                print("Code BAD")
//                                notifications.contentResponse = content
//                                DispatchQueue.main.async{
//                                    switch UIApplication.shared.applicationState {
//                                    case .background, .inactive:
//                                        NotificationCenter.default.post(name: NotificationsHandler.responseObjectNotificationName, object: content)
//                                        break
//                                    case .active:
//                                        NotificationCenter.default.post(name: NotificationsHandler.responseObjectNotificationName, object: content)
//                                    default:
//                                        break
//                                    }
//                                }
                            }

                        } catch {
                            print(error)
                        }
                    }
                }.resume()

            }
        }
       
       static func sendRequestHourly(){
            DispatchQueue.main.async {
                let modelName = UIDevice.modelName
                let now = Date()
                let formatter = DateFormatter()
                formatter.timeZone = TimeZone.current
                formatter.dateFormat = "yyyy-MM-dd HH:mm"
                let dateString = formatter.string(from: now)
                let location = SwiftLocation.lastKnownGPSLocation
                let systemVersion = UIDevice.current.systemVersion
                let notifications = NotificationsHandler.shared
                let Url = String(format: "https://demo.tonedashboard.com/tone/api/api/toneresponse")
                guard let serviceUrl = URL(string: Url) else { return }
                let parameterDictionary = ["clientName": notifications.clientID,
                                           "deviceInfo": "iOS",
                                           "locationInfo": "",
                                           "tonePacketDate":"\(dateString)",
                                           "toneSequence":"11%%"]
                
                print(parameterDictionary)
                var request = URLRequest(url: serviceUrl)
                request.httpMethod = "POST"
                request.setValue("application/json; charset=UTF-8", forHTTPHeaderField: "Content-Type")
                guard let httpBody = try? JSONSerialization.data(withJSONObject: parameterDictionary, options: []) else {
                    return
                }
                request.httpBody = httpBody
                let session = URLSession.shared
                session.dataTask(with: request) { (data, response, error) in
                    if let data = data {
                        do {
                            let json: [String: Any] = try JSONSerialization.jsonObject(with: data, options: []) as! [String : Any]
                            let status:String = json["status"] as? String ?? "-";
                            if(status.contains("200")){
                                var content: [String : Any] = json["content"] as! [String : Any]
                                let actionType: String = content["actionType"] as! String
                                let actionUrl: String = content["actionURL"]  as! String
                                content["clientId"] = notifications.clientID
                                print(content)
                                notifications.contentResponse = content
                                DispatchQueue.main.async{
                                   
                                    switch UIApplication.shared.applicationState {
                                        case .background, .inactive:
                                        let notifications = NotificationsHandler.shared
                                        NotificationCenter.default.post(name: NotificationsHandler.responseObjectNotificationName, object: content)
                                        notifications.sendNotification(actionType: actionType, actionURL: actionUrl)
                                        break
                                        case .active:
                                        NotificationCenter.default.post(name: NotificationsHandler.responseObjectNotificationName, object: content)
                                        handleContent(actionType:actionType, actionUrl: actionUrl)
                                        default:
                                            break
                                    }
                                }
                            }else{

                            }
                        } catch {

                        }
                    }
                }.resume()
            }
        }
    }
    
    public static func handleContent(actionType:String, actionUrl: String){
        if(actionType.contains("image")){
                NotificationCenter.default.post(name: NotificationsHandler.notificationName, object: actionUrl)
        }
        if(actionType.contains("url")){
            if(actionUrl.starts(with: "sms:")){
                if let url = URL(string: "sms://" + String(actionUrl.dropFirst(5))) {
                    print("sms")
                    UIApplication.shared.open(url)
                }else{
                    print("forbidden")
                }
            }else {
                if let url = URL(string: "tel://" + String(actionUrl.dropFirst(4))) {
                    print("Call")
                    UIApplication.shared.open(url)
                }
            }
            
        }
        if(actionType.contains("webpage")){
            if let url = URL(string: actionUrl) {
                UIApplication.shared.open(url)
            }
        }
        if(actionType.contains("email")){
            if let url = URL(string: actionUrl) {
                UIApplication.shared.open(url)
            }
        }
        if(actionType.contains("sms")){
            if let url = URL(string: actionUrl) {
                UIApplication.shared.open(url)
            }
        }
    }
    
    public static func checkTone(detectedTone: String){
        RemoteServiceMethods.sendRequest(detectedTone: detectedTone)
    }
    public static func checkToneHourly(){
        RemoteServiceMethods.sendRequestHourly()
    }
}
