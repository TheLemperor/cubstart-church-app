import SwiftUI
import SwiftData

@main
struct ChurchScheduleManagerApp: App {
    // Create the model configuration
    let modelContainer: ModelContainer
    
    init() {
        do {
            // Create the model container
            modelContainer = try ModelContainer(for: ScheduleItem.self, Person.self)
            
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
