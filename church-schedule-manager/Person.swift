//
//  Person.swift
//  church-schedule-manager
//
//  Created by Lemuel Sumardy on 5/1/25.
//

import SwiftUI
import SwiftData

@Model
class Person {
    var id: UUID
    var name: String
    var nameVariations: [String]
    
    init(name: String = "Placeholder", nameVariations: [String] = []) {
        self.id = UUID()
        self.name = name
        self.nameVariations = nameVariations
    }
}
