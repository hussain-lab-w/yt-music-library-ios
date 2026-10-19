import Foundation

struct DownloadedFile: Codable, Identifiable {
    let id: String
    let title: String
    let url: String
}

struct DownloadJob: Codable, Identifiable {
    let id: String
    var title: String
    var status: String
    var progress: Double
    var files: [DownloadedFile]
    var error: String?
}

@MainActor
final class DownloadService: ObservableObject {
    @Published var urlText = ""
    @Published var job: DownloadJob?
    @Published var message = ""
    @Published var isWorking = false
    @Published var downloadedFiles: [(title: String, data: Data)] = []

    private let settings: AppSettings

    init(settings: AppSettings) { self.settings = settings }

    func startDownload() async {
        downloadedFiles = []
        guard let backend = settings.normalizedURL else {
            message = "Set a valid HTTPS Backend URL in Settings first."; return
        }
        let source = urlText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let sourceURL = URL(string: source), ["http", "https"].contains(sourceURL.scheme?.lowercased() ?? "") else {
            message = "Paste a valid video or playlist URL."; return
        }
        isWorking = true
        defer { isWorking = false }
        do {
            try await checkConnection(backend: backend)
            message = "Starting download..."
            var request = URLRequest(url: backend.appendingPathComponent("api/download"))
            request.httpMethod = "POST"
            request.timeoutInterval = 30
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: ["url": source])
            let (data, response) = try await URLSession.shared.data(for: request)
            try validate(response)
            job = try JSONDecoder().decode(DownloadJob.self, from: data)
            await poll(backend: backend)
        } catch {
            message = friendlyError(error)
        }
    }

    private func checkConnection(backend: URL) async throws {
        var request = URLRequest(url: backend.appendingPathComponent("health"))
        request.timeoutInterval = 10
        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response)
        guard String(data: data, encoding: .utf8) != nil else { throw URLError(.cannotParseResponse) }
    }

    private func poll(backend: URL) async {
        guard let id = job?.id else { return }
        for _ in 0..<1800 {
            do {
                let (data, response) = try await URLSession.shared.data(from: backend.appendingPathComponent("api/download/\(id)"))
                try validate(response)
                let latest = try JSONDecoder().decode(DownloadJob.self, from: data)
                job = latest
                if latest.status == "completed" {
                    message = "Download complete. Preparing files..."
                    for file in latest.files {
                        let fileURL = backend.appendingPathComponent(file.url.trimmingCharacters(in: CharacterSet(charactersIn: "/")))
                        let (audio, fileResponse) = try await URLSession.shared.data(from: fileURL)
                        try validate(fileResponse)
                        downloadedFiles.append((file.title, audio))
                    }
                    message = "Ready to add \(downloadedFiles.count) file(s) to your library."
                    return
                }
                if latest.status == "error" { message = latest.error ?? "The server could not complete the download."; return }
            } catch { message = friendlyError(error); return }
            try? await Task.sleep(for: .seconds(1))
        }
        message = "The download timed out. Check the server logs and try again."
    }

    private func validate(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else { throw URLError(.badServerResponse) }
    }

    private func friendlyError(_ error: Error) -> String {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .cannotFindHost, .cannotConnectToHost, .timedOut: return "Could not connect to the Backend. Check the URL and make sure the server is online."
            case .appTransportSecurityRequiresSecureConnection: return "The Backend must use HTTPS."
            default: break
            }
        }
        return error.localizedDescription
    }
}
