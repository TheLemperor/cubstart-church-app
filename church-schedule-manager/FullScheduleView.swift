//
//  FullScheduleView.swift
//  church-schedule-manager
//
//  Created by Lemuel Sumardy on 5/1/25.
//

import SwiftUI
import SwiftData

struct FullScheduleView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var scheduleItems: [ScheduleItem]
    @State private var searchText = ""
    
    var body: some View {
        NavigationStack {
            VStack {
                List {
                    ForEach(groupedByDate(), id: \.0) { date, items in
                        Section(header: Text(date, style: .date)) {
                            ForEach(items) { item in
                                HStack {
                                    Text(item.role)
                                    Spacer()
                                    Text(item.assignedPerson)
                                }
                            }
                        }
                    }
                }
                .searchable(text: $searchText, prompt: "Search by name or role")
            }
            .navigationTitle("Full Schedule")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Swap") {
                        // Action to swap assignments (to be implemented)
                    }
                }
            }
        }
    }
    
    private func groupedByDate() -> [(Date, [ScheduleItem])] {
        let filtered = searchText.isEmpty ? scheduleItems : scheduleItems.filter {
            $0.role.localizedCaseInsensitiveContains(searchText) ||
            $0.assignedPerson.localizedCaseInsensitiveContains(searchText)
        }
        
        let grouped = Dictionary(grouping: filtered) { item in
            // Group by date, ignoring time component
            Calendar.current.startOfDay(for: item.date)
        }
        
        return grouped.sorted { $0.key < $1.key }
    }
}

// Make ScheduleItem identifiable
extension ScheduleItem: Identifiable {
    // ID already exists from the @Model
}
