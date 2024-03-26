//
//  Queue.swift
//  tone-debug-visualizer
//
//  Created by Strut Company on 10/11/21.
//

import Foundation
struct Queue<T> {
  private var elements: [T] = []

  mutating func enqueue(_ value: T) {
    elements.append(value)
  }
    mutating func clear() {
        elements.removeAll()
    }

  mutating func dequeue() -> T? {
    guard !elements.isEmpty else {
      return nil
    }
    return elements.removeFirst()
  }
    var count: Int {
        return elements.count
    }

  var head: T? {
    return elements.first
  }

  var tail: T? {
    return elements.last
  }
}
