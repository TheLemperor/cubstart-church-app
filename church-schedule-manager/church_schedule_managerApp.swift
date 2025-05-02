import SwiftUI
import SwiftData

@main
struct ChurchScheduleManagerApp: App {
    // Create the model container
    let modelContainer: ModelContainer
    
    init() {
        do {
            // Define the schema
            let schema = Schema([
                ScheduleItem.self,
                Person.self
            ])
            
            // Configure SwiftData settings
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false // Set to true if you want in-memory only storage
            )
            
            // Create the container with the configuration
            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
            
            // Create a context to work with the container
            let context = ModelContext(modelContainer)
            
            // Check if we need to create an initial Person
            let descriptor = FetchDescriptor<Person>()
            if let count = try? context.fetchCount(descriptor), count == 0 {
                // Create default person with empty name
                let defaultPerson = Person()
                context.insert(defaultPerson)
                try? context.save()
            }
        } catch {
            // Fallback if container creation fails
            fatalError("Failed to create model container: \(error.localizedDescription)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(modelContainer)
        }
    }
}
