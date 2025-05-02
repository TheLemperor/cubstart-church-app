import SwiftUI
import SwiftData

struct MainView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var scheduleItems: [ScheduleItem]
    @Query private var persons: [Person]
    
    var body: some View {
        NavigationStack {
            VStack {
                List {
                    Section(header: Text("My Assignments")) {
                        if let myItems = myScheduleItems, !myItems.isEmpty {
                            ForEach(myItems) { item in
                                Text("\(item.date, format: .dateTime.day().month()): \(item.role)")
                            }
                        } else {
                            Text("No assignments found")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Section(header: Text("Upcoming Sunday")) {
                        Text("No upcoming assignments")
                    }
                }
            }
            .navigationTitle("Welcome, \(currentUserName)")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gear")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: FullScheduleView()) {
                        Text("Full Schedule")
                    }
                }
            }
        }
    }
    
    private var currentUserName: String {
        return persons.first?.name.isEmpty ?? true ? "User" : (persons.first?.name ?? "User")
    }
    
    private var myScheduleItems: [ScheduleItem]? {
        guard let person = persons.first, !person.name.isEmpty else { return [] }
        
        let allNames = [person.name] + person.nameVariations
        return scheduleItems.filter { item in
            allNames.contains { name in
                item.assignedPerson.localizedStandardContains(name)
            }
        }
    }
}
