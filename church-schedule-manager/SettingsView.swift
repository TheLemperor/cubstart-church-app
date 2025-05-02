import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var persons: [Person]
    
    @State private var userName = ""
    @State private var nameVariation = ""
    @State private var nameVariations: [String] = []
    @State private var showSavedAlert = false
    
    var body: some View {
        Form {
            Section(header: Text("Your Name")) {
                TextField("Enter your name", text: $userName)
                    .textContentType(.name)
            }
            
            Section(header: Text("Name Variations")) {
                HStack {
                    TextField("Add name variation", text: $nameVariation)
                    Button(action: addNameVariation) {
                        Image(systemName: "plus.circle")
                    }
                }
                
                List {
                    ForEach(nameVariations, id: \.self) { variation in
                        Text(variation)
                    }
                    .onDelete(perform: deleteNameVariation)
                }
            }
            
            Section {
                Button("Save Settings") {
                    saveSettings()
                    showSavedAlert = true
                }
                .frame(maxWidth: .infinity)
                .buttonStyle(.borderedProminent)
                .padding()
            }
        }
        .navigationTitle("Settings")
        .onAppear {
            loadSettings()
        }
        .alert("Settings Saved", isPresented: $showSavedAlert) {
            Button("OK") { showSavedAlert = false }
        }
    }
    
    private func addNameVariation() {
        if !nameVariation.isEmpty {
            nameVariations.append(nameVariation)
            nameVariation = ""
        }
    }
    
    private func deleteNameVariation(at offsets: IndexSet) {
        nameVariations.remove(atOffsets: offsets)
    }
    
    private func loadSettings() {
        if let person = persons.first {
            userName = person.name
            nameVariations = person.nameVariations
        }
    }
    
    private func saveSettings() {
        if let person = persons.first {
            // Update existing person
            person.name = userName
            person.nameVariations = nameVariations
            
            // Save changes
            try? modelContext.save()
        }
    }
}
