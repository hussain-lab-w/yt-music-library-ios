import Foundation
import SwiftUI

final class AppSettings: ObservableObject {
    @Published var backendURL: String {
        didSet { UserDefaults.standard.set(backendURL, forKey: "backendURL") }
    }

    init() {
        backendURL = UserDefaults.standard.string(forKey: "backendURL") ?? ""
    }

    var normalizedURL: URL? {
        var value = backendURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return nil }
        if !value.contains("://") { value = "https://" + value }
        guard let url = URL(string: value), let scheme = url.scheme, ["http", "https"].contains(scheme), url.host != nil else { return nil }
        return url
    }
}
