import SwiftUI
import SwiftData

struct FullScheduleView: View {
    // Access the ModelContext from the environment
    @Environment(\.modelContext) private var modelContext
    @Query private var scheduleItems: [ScheduleItem]
    
    // Initialize the ViewModel with the environment's ModelContext
    @StateObject private var viewModel: ScheduleViewModel
    
    // Other view variables
    @State private var searchText = ""
    @State private var selectedRole: String?
    @State private var showRoleFilter = false
    @State private var sortOption = SortOption.byDate
    @State private var hasInitialized = false
    
    enum SortOption: String, CaseIterable, Identifiable {
        case byDate = "Date"
        case byRole = "Role"
        var id: String { self.rawValue }
    }
    
    init() {
        let container = try! ModelContainer(for: ScheduleItem.self, Person.self)
        _viewModel = StateObject(wrappedValue: ScheduleViewModel(modelContext: ModelContext(container)))
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                if viewModel.isLoading {
                    ProgressView("Loading schedule...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        if let selectedRole = selectedRole {
                            roleSection(for: selectedRole)
                        } else {
                            switch sortOption {
                            case .byDate:
                                dateGroupedContent
                            case .byRole:
                                roleGroupedContent
                            }
                        }
                    }
                    .searchable(text: $searchText, prompt: "Search by name or role")
                    
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding()
                    }
                    
                    if let lastSync = viewModel.lastSyncDate {
                        Text("Last synced: \(lastSync, format: .dateTime)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.bottom, 5)
                    }
                }
            }
            .navigationTitle(navigationTitle)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        viewModel.fetchFromGoogleSheets()
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(viewModel.isLoading)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            showRoleFilter = true
                        }) {
                            Label("Filter by Role", systemImage: "line.3.horizontal.decrease.circle")
                        }
                        
                        if selectedRole != nil {
                            Button(action: {
                                selectedRole = nil
                            }) {
                                Label("Clear Filter", systemImage: "xmark.circle")
                            }
                        }
                        
                        Divider()
                        
                        Picker("Sort by", selection: $sortOption) {
                            ForEach(SortOption.allCases) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                    }
                }
            }

            .onAppear {
                if !hasInitialized {
                    viewModel.updateModelContext(modelContext)
                    hasInitialized = true
                }
            }
        }
    }
    
    private var navigationTitle: String {
        if let role = selectedRole {
            return "Schedule: \(role)"
        } else {
            return "Full Schedule"
        }
    }
    
    private var filteredItems: [ScheduleItem] {
        if searchText.isEmpty {
            return scheduleItems
        } else {
            return scheduleItems.filter {
                $0.role.localizedCaseInsensitiveContains(searchText) ||
                $0.assignedPerson.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    // Group by date
    private var dateGroupedContent: some View {
        ForEach(groupedByDate(), id: \.0) { date, items in
            Section(header: Text(date, style: .date)) {
                ForEach(items) { item in
                    scheduleItemRow(item)
                }
            }
        }
    }
    
    // Group by role
    private var roleGroupedContent: some View {
        ForEach(groupedByRole(), id: \.0) { role, items in
            Section(header: Text(role)) {
                ForEach(items) { item in
                    HStack {
                        Text(item.date, format: .dateTime.day().month().year())
                        Spacer()
                        Text(item.assignedPerson)
                    }
                }
            }
        }
    }
    
    
    // Display items for a specific role
    private func roleSection(for role: String) -> some View {
        let items = filteredItems.filter { $0.role == role }
            .sorted { $0.date < $1.date }
        
        return ForEach(items) { item in
            HStack {
                Text(item.date, format: .dateTime.day().month().year())
                Spacer()
                Text(item.assignedPerson)
            }
        }
    }
    
    // Row for a schedule item
    private func scheduleItemRow(_ item: ScheduleItem) -> some View {
        HStack {
            Text(item.role)
            Spacer()
            Text(item.assignedPerson)
        }
    }
    
    private func groupedByDate() -> [(Date, [ScheduleItem])] {
        let grouped = Dictionary(grouping: filteredItems) { item in
            // Group by date, ignoring time 
            Calendar.current.startOfDay(for: item.date)
        }
        
        return grouped.sorted { $0.key < $1.key }
    }
    
    private func groupedByRole() -> [(String, [ScheduleItem])] {
        let grouped = Dictionary(grouping: filteredItems) { item in
            item.role
        }
        
        return grouped.sorted { $0.key < $1.key }
    }
    
    private func groupedByPerson() -> [(String, [ScheduleItem])] {
        let grouped = Dictionary(grouping: filteredItems) { item in
            item.assignedPerson
        }
        
        return grouped.sorted { $0.key < $1.key }
    }
}
