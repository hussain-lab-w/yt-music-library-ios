import SwiftUI

@main
struct YTMusicLibraryApp: App {
    @StateObject private var library = AudioLibrary()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(library)
                .preferredColorScheme(.dark)
        }
    }
}
