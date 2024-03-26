//
//  NotificationsHandler.swift
//  ToneListen
//
//  Created by Strut Company on 27/12/21.
//

import Foundation
import UserNotifications
import UIKit

public class NotificationsHandler: NSObject, UNUserNotificationCenterDelegate{
    public override init() {}
    public static var shared = NotificationsHandler()
    var clientID = ""
    public var contentResponse = [String : Any]()
    public static let clientNotificationName = Notification.Name("clientNotificationName")
    public static let notificationName = Notification.Name("View2Msg")
    public static let responseObjectNotificationName = Notification.Name("responseObjectNotificationName")
    public func requestPermission(){
        
        UNUserNotificationCenter.current().delegate = self
        let openAction = UNNotificationAction(
          identifier: "open",
          title: "open",
          options: [])
        
        
        let category = UNNotificationCategory(
          identifier: "OrganizerPlusCategory",
          actions: [openAction],
          intentIdentifiers: [],
          options: [])
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
            if success {
                print("All set!")
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
                UNUserNotificationCenter.current().setNotificationCategories([category])
            } else if let error = error {
                print(error.localizedDescription)
            }
        }
        
    }
    
    func sendNotification(actionType:String, actionURL:String) {
        let center = UNUserNotificationCenter.current()
        
        let content = UNMutableNotificationContent()
        content.title = "Tone Detected"
        content.body = "Tap to see the contents"
        content.sound = .default
        content.userInfo = ["data": actionURL,"type":actionType]
        content.categoryIdentifier = actionType
                
        let fireDate = Calendar.current.dateComponents([.day, .month, .year, .hour, .minute, .second], from: Date().addingTimeInterval(1))
        let trigger = UNCalendarNotificationTrigger(dateMatching: fireDate, repeats: false)
        
        let request = UNNotificationRequest(identifier: actionType, content: content, trigger: trigger)
        center.add(request) { (error) in
            if error != nil {
                print("Error = \(error?.localizedDescription ?? "error local notification")")
            }
        }
    }
    
    // This function will be called when the app receive notification
    public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
      // show the notification alert (banner), and with sound
      completionHandler([.alert, .sound])
    }
      
    public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        
            let userInfo = response.notification.request.content.userInfo
               if let customData = userInfo["data"] as? String {
                   if userInfo["type"] as? String == "image" {                       
                       NotificationCenter.default.post(name: NotificationsHandler.notificationName, object: customData)
                   } else {
                       RemoteService.handleContent(actionType: userInfo["type"] as? String ?? "url", actionUrl: customData)
                   }
                   
                   
                   
               }
        
        completionHandler()
      }
    

    
}
