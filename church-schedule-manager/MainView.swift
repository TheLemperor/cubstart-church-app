import SwiftUI
import SwiftData

struct MainView: View {
    // Access the ModelContext from the environment
    @Environment(\.modelContext) private var modelContext
    @Query private var scheduleItems: [ScheduleItem]
    @Query private var persons: [Person]
    
    // Initialize the ViewModel with the environment's ModelContext
    @StateObject private var viewModel: ScheduleViewModel
    
    // Other view variables...
    @State private var selectedRole: String?
    @State private var showRoleFilter = false
    @State private var showingInfoAlert = false
    @State private var hasInitialized = false
    
    init() {
        // Create ViewModel with a temporary context
        // The real context will be assigned in onAppear
        // Correct version
        let container = try! ModelContainer(for: ScheduleItem.self, Person.self)
        _viewModel = StateObject(wrappedValue: ScheduleViewModel(modelContext: ModelContext(container)))
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                // User welcome and summary
                VStack(alignment: .leading, spacing: 6) {
                    Text("Selamat Datang, \(currentUserName)")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    if let nextServiceDate = viewModel.getUpcomingServices().first {
                        Text("Next Service: \(nextServiceDate, format: .dateTime.day().month().year())")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 8)
                
                // Main content
                List {
                    Section(header: Text("My Assignments")) {
                        if viewModel.isLoading {
                            ProgressView("Loading...")
                        } else if let myItems = myScheduleItems, !myItems.isEmpty {
                            ForEach(myItems) { item in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(item.date, format: .dateTime.day().month().year())
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text(item.role)
                                            .font(.headline)
                                    }
                                    
                                    Spacer()
                                    
                                    Text(item.assignedPerson)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 4)
                            }
                        } else {
                            HStack {
                                Text("No assignments found")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Button(action: {
                                    showingInfoAlert = true
                                }) {
                                    Image(systemName: "info.circle")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                    
                    Section(header: Text("Upcoming Sunday")) {
                        if viewModel.isLoading {
                            ProgressView("Loading...")
                        } else {
                            let upcomingItems = viewModel.getUpcomingSundayItems()
                            if upcomingItems.isEmpty {
                                Text("No upcoming assignments")
                                    .foregroundColor(.secondary)
                            } else {
                                ForEach(upcomingItems) { item in
                                    HStack {
                                        Text(item.role)
                                            .font(.headline)
                                        Spacer()
                                        Text(item.assignedPerson)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.vertical, 2)
                                }
                            }
                        }
                    }
                    
                    // Quick access to specific roles
                    Section(header: Text("Browse by Role")) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(popularRoles, id: \.self) { role in
                                    Button(action: {
                                        selectedRole = role
                                        showRoleFilter = true
                                    }) {
                                        Text(role)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(Color.blue.opacity(0.1))
                                            .cornerRadius(8)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.vertical, 8)
                        }
                        .padding(.horizontal, -16)
                    }
                }
                
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
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: refreshData) {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                    .disabled(viewModel.isLoading)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        NavigationLink(destination: SettingsView()) {
                            Label("Settings", systemImage: "gear")
                        }
                        
                        Button(action: {
                            showRoleFilter = true
                        }) {
                            Label("Filter by Role", systemImage: "line.3.horizontal.decrease.circle")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: FullScheduleView()) {
                        Text("Full Schedule")
                    }
                }
            }
            .sheet(isPresented: $showRoleFilter) {
                RoleFilterView(
                    availableRoles: viewModel.availableRoles,
                    selectedRole: $selectedRole
                )
                .onDisappear {
                    if let role = selectedRole {
                        navigateToRoleView(role: role)
                    }
                }
            }
            .alert("About Name Detection", isPresented: $showingInfoAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("To see your assignments, set your name and any variations in Settings. The app will detect assignments that match your name.")
            }
            .onAppear {
                if !hasInitialized {
                    // Use the environment's modelContext
                    viewModel.updateModelContext(modelContext)
                    hasInitialized = true
                    
                    // Load data if needed
                    if scheduleItems.isEmpty {
                        refreshData()
                    }
                }
            }
        }
    }
    
    private func navigateToRoleView(role: String) {
        // In a more complex app, this would navigate to a role-specific view
        // For now, we'll just clear the selection
        selectedRole = nil
    }
    
    private func refreshData() {
        viewModel.fetchFromGoogleSheets()
    }
    
    private var currentUserName: String {
        return persons.first?.name.isEmpty ?? true ? "User" : (persons.first?.name ?? "User")
    }
    
    private var myScheduleItems: [ScheduleItem]? {
        guard let person = persons.first, !person.name.isEmpty else { return [] }
        
        return viewModel.getMyScheduleItems(personName: person.name, nameVariations: person.nameVariations)
    }
    
    // Most commonly used roles for quick access
    private var popularRoles: [String] {
        return [
            "Pengkhotbah Umum",
            "PEMIMPIN IBADAH",
            "PIANIS",
            "SOUND SYSTEM",
            "TODDLER"
        ]
    }
}

// Role filter view
struct RoleFilterView: View {
    let availableRoles: [String]
    @Binding var selectedRole: String?
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    
    var body: some View {
        NavigationStack {
            VStack {
                List {
                    ForEach(filteredRoles, id: \.self) { role in
                        Button(action: {
                            selectedRole = role
                            dismiss()
                        }) {
                            HStack {
                                Text(role)
                                Spacer()
                                if role == selectedRole {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .foregroundColor(.primary)
                    }
                }
                .searchable(text: $searchText, prompt: "Search roles")
            }
            .navigationTitle("Select Role")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Clear") {
                        selectedRole = nil
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var filteredRoles: [String] {
        if searchText.isEmpty {
            return availableRoles
        } else {
            return availableRoles.filter {
                $0.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
}
