import SwiftUI
import SwiftData
import Foundation


@MainActor
class ScheduleViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var lastSyncDate: Date?
    
    let availableRoles: [String] = [
        "Pengkhotbah Umum",
        "PEMIMPIN IBADAH",
        "PIANIS",
        "ORGANIS",
        "Pengkotbah English Service",
        "E/S Pemimpin Pujian",
        "E/S Usher",
        "E/S Pianis",
        "E/S OHP",
        "E/S Sound",
        "ES Usher",
        "Penyambutan",
        "KONSUMSI",
        "LOWER ELEMENTARY",
        "TEEN",
        "TODDLER",
        "PRESCHOOL",
        "MUSIK S.M.",
        "PEM. PUJIAN S.M.",
        "UPPER ELEMENTARY -MIDDLE SCHOOL",
        "P BUNGA",
        "OHP Livestream Operator",
        "SOUND SYSTEM",
        "KEBERSIHAN",
        "PERJAMUAN KUDUS",
        "Pembicara PD SF",
        "Pemimpin PD SF",
        "Pembicara PD Dublin / Eastbay",
        "Pemimpin PD Dublin / Eastbay",
        "Persekutuan Eastbay (Host)",
        "Persekutuan Bethania",
        "Nursery",
        "Pembicara Persekutuan Pemuda",
        "Tema Persekutuan Pemuda",
        "Kebersihan Dapur"
    ]
    
    private var modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // update the model context
    func updateModelContext(_ newContext: ModelContext) {
        self.modelContext = newContext
    }
    
    // load sample data for testing
    func loadSampleData() {
        isLoading = true
        
        // Sample data
        let today = Date()
        let nextSunday = Calendar.current.nextDate(after: today, matching: DateComponents(weekday: 1), matchingPolicy: .nextTime)!
        
        let scheduleItems = [
            ScheduleItem(date: nextSunday, role: "Pengkhotbah Umum", assignedPerson: "Pdt. Samuel"),
            ScheduleItem(date: nextSunday, role: "PEMIMPIN IBADAH", assignedPerson: "Tn. Budi"),
            ScheduleItem(date: nextSunday, role: "PIANIS", assignedPerson: "Ny. Maria"),
            ScheduleItem(date: nextSunday, role: "SOUND SYSTEM", assignedPerson: "Your Name"),
            ScheduleItem(date: nextSunday, role: "TODDLER", assignedPerson: "Your Name"),
            ScheduleItem(date: Calendar.current.date(byAdding: .day, value: 7, to: nextSunday)!, role: "Pengkhotbah Umum", assignedPerson: "Pdt. John"),
            ScheduleItem(date: Calendar.current.date(byAdding: .day, value: 7, to: nextSunday)!, role: "PEMIMPIN IBADAH", assignedPerson: "Tn. David"),
            ScheduleItem(date: Calendar.current.date(byAdding: .day, value: 7, to: nextSunday)!, role: "PIANIS", assignedPerson: "Your Name"),
        ]
        
        for item in scheduleItems {
            modelContext.insert(item)
        }
        
        try? modelContext.save()
        isLoading = false
    }
    
    func fetchFromGoogleSheets() {

        isLoading = true
        errorMessage = nil
        
        deleteAllScheduleItems()
        
        GoogleSheetsService.shared.readSchedule { [weak self] scheduleItems, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                if let error = error {
                    self.errorMessage = "Failed to fetch schedule: \(error.localizedDescription)"
                    
                    self.loadSampleData()
                    return
                }
                
                guard let scheduleItems = scheduleItems, !scheduleItems.isEmpty else {
                    self.errorMessage = "No schedule items found"
                    
                    self.loadSampleData()
                    return
                }
                
                for item in scheduleItems {
                    self.modelContext.insert(item)
                }
                
                do {
                    try self.modelContext.save()
                    self.lastSyncDate = Date()
                } catch {
                    self.errorMessage = "Failed to save schedule: \(error.localizedDescription)"
                }
                
                self.isLoading = false
            }
        }
    }
    
    private func deleteAllScheduleItems() {
        let descriptor = FetchDescriptor<ScheduleItem>()
        
        do {
            let allItems = try modelContext.fetch(descriptor)
            for item in allItems {
                modelContext.delete(item)
            }
        } catch {
            print("Failed to fetch items for deletion: \(error.localizedDescription)")
        }
    }
    
    func getMyScheduleItems(personName: String, nameVariations: [String]) -> [ScheduleItem] {
        let descriptor = FetchDescriptor<ScheduleItem>(
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )
        
        do {
            let allItems = try modelContext.fetch(descriptor)
            let allNames = [personName] + nameVariations
            
            return allItems.filter { item in
                allNames.contains { name in
                    item.assignedPerson.localizedStandardContains(name)
                }
            }
        } catch {
            print("Fetch failed: \(error)")
            return []
        }
    }
    
    func getUpcomingSundayItems() -> [ScheduleItem] {
        let today = Date()
        let nextSunday = Calendar.current.nextDate(after: today, matching: DateComponents(weekday: 1), matchingPolicy: .nextTime)!
        let startOfDay = Calendar.current.startOfDay(for: nextSunday)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let descriptor = FetchDescriptor<ScheduleItem>(
            predicate: #Predicate<ScheduleItem> { item in
                item.date >= startOfDay && item.date < endOfDay
            },
            sortBy: [SortDescriptor(\.role)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Fetch failed: \(error)")
            return []
        }
    }
    
    func getUpcomingServices() -> [Date] {
        let today = Date()
        let threeMonthsLater = Calendar.current.date(byAdding: .month, value: 3, to: today)!
        
        let descriptor = FetchDescriptor<ScheduleItem>(
            predicate: #Predicate<ScheduleItem> { item in
                item.date >= today && item.date <= threeMonthsLater
            }
        )
        
        do {
            let items = try modelContext.fetch(descriptor)
            
            let uniqueDates = Set(items.map { Calendar.current.startOfDay(for: $0.date) })
            
            return Array(uniqueDates).sorted()
        } catch {
            print("Fetch failed: \(error)")
            return []
        }
    }
}
