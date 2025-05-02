import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        SplashView()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [ScheduleItem.self, Person.self])
}
