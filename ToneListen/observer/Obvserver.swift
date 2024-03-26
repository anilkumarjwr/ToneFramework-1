//
//  Obvserver.swift
//  ToneListen
//
//  Created by Strut Company on 15/12/21.
//

import Foundation
public class Subject {

    /// For the sake of simplicity, the Subject's state, essential to all
    /// subscribers, is stored in this variable.
    public var state: String = ""

    /// @var array List of subscribers. In real life, the list of subscribers
    /// can be stored more comprehensively (categorized by event type, etc.).
    private lazy var observers = [Observer]()

    /// The subscription management methods.
    func attach(_ observer: Observer) {
        print("Observer: Attached an observer.\n")
        observers.append(observer)
    }

    func detach(_ observer: Observer) {
        if let idx = observers.firstIndex(where: { $0 === observer }) {
            observers.remove(at: idx)
            print("Subject: Detached an observer.\n")
        }
    }

    /// Trigger an update in each subscriber.
    func notify() {
        print("Obvserver: Notifying observers...\n")
        observers.forEach({ $0.update(subject: self)})
    }

    /// Usually, the subscription logic is only a fraction of what a Subject can
    /// really do. Subjects commonly hold some important business logic, that
    /// triggers a notification method whenever something important is about to
    /// happen (or after it)
    func toneDetected(tone: String){
        state = tone
        notify()
    }
}

/// The Observer protocol declares the update method, used by subjects.
public protocol Observer: AnyObject {

    func update(subject: Subject)
}

/// Concrete Observers react to the updates issued by the Subject they had been
/// attached to.
class ConcreteObserverA: Observer {

    func update(subject: Subject) {
        print("ConcreteObserverA: Reacted to the event.\n", subject.state)
    }
}

class ConcreteObserverB: Observer {

    func update(subject: Subject) {
        print("ConcreteObserverA: Reacted to the event.\n", subject.state)
    }
}
