//
//  ToneTable.swift
//  tone-debug-visualizer
//
//  Created by Strut Company on 1/11/21.
//

import Foundation

struct TableCodes : Codable{
    let data: [Item]
}

struct Item : Codable{
    let lowkey: Int
    let pairs: [Pair]
}

struct Pair : Codable{
    let highkey: Int
    let tonetag: String
}
