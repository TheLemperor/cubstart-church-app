import Foundation
import SwiftData

@Model
class ScheduleItem {
    var id: UUID
    var date: Date
    var role: String
    var assignedPerson: String
    
    init(date: Date, role: String, assignedPerson: String) {
        self.id = UUID()
        self.date = date
        self.role = role
        self.assignedPerson = assignedPerson
    }
}
