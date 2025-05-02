import SwiftUI
import SwiftData

@MainActor
class ScheduleViewModel: ObservableObject {
    @Published var isLoading = false
    private var modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func loadSampleData() {
        isLoading = true
        
        // Sample data
        let today = Date()
        let nextSunday = Calendar.current.nextDate(after: today, matching: DateComponents(weekday: 1), matchingPolicy: .nextTime)!
        
        let scheduleItems = [
            ScheduleItem(date: nextSunday, role: "Worship Leader", assignedPerson: "John Smith"),
            ScheduleItem(date: nextSunday, role: "Prayer", assignedPerson: "Jane Doe"),
            ScheduleItem(date: nextSunday, role: "Scripture Reading", assignedPerson: "Your Name"),
            ScheduleItem(date: Calendar.current.date(byAdding: .day, value: 7, to: nextSunday)!, role: "Worship Leader", assignedPerson: "Mike Johnson"),
            ScheduleItem(date: Calendar.current.date(byAdding: .day, value: 7, to: nextSunday)!, role: "Prayer", assignedPerson: "Your Name"),
        ]
        
        for item in scheduleItems {
            modelContext.insert(item)
        }
        
        try? modelContext.save()
        isLoading = false
    }
    
    // This would be implemented to connect to Google Sheets
    func fetchFromGoogleSheets() {
        // Future implementation to connect with Google Sheets API
    }
    
    func getMyScheduleItems(personName: String, nameVariations: [String]) -> [ScheduleItem] {
        let allNames = [personName] + nameVariations
        let descriptor = FetchDescriptor<ScheduleItem>(
            predicate: #Predicate<ScheduleItem> { item in
                allNames.contains { name in
                    item.assignedPerson.localizedStandardContains(name)
                }
            },
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Fetch failed: \(error)")
            return []
        }
    }
}//
//  ScheduleViewModel.swift
//  church-schedule-manager
//
//  Created by Lemuel Sumardy on 5/1/25.
//

