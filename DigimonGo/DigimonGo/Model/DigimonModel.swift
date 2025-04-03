//
//  DigimonModel.swift
//  DigimonGo
//
//  Created by Rashad Milton on 3/10/25.
//

import Foundation
struct Digimon: Decodable, Identifiable, Equatable {
    let name: String
    let img: String
    let level: String
}
extension Digimon {
    var id: String {
        img
    }
}
