import Foundation

struct DownloadJob: Codable, Identifiable {
    let id: String
    var title: String
    var status: String
    var progress: Double
    var fileURL: String?
    var error: String?
}

@MainActor
final class DownloadService: ObservableObject {
    @Published var urlText = ""
    @Published var job: DownloadJob?
    @Published var isWorking = false
    @Published var message = ""
    @Published var downloadedData: Data?

    // Set this to the deployed backend URL before release.
    var baseURL = URL(string: "http://127.0.0.1:8000")!

    func startDownload() async {
        guard let url = URL(string: urlText.trimmingCharacters(in: .whitespacesAndNewlines)), url.scheme != nil else {
            message = "أدخل رابطاً صحيحاً"; return
        }
        isWorking = true; message = "جاري تجهيز الرابط..."
        defer { isWorking = false }
        do {
            var request = URLRequest(url: baseURL.appendingPathComponent("api/download"))
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(["url": url.absoluteString])
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else { throw URLError(.badServerResponse) }
            job = try JSONDecoder().decode(DownloadJob.self, from: data)
            message = "بدأ التنزيل"
            await poll()
        } catch { message = "تعذر بدء التنزيل: \(error.localizedDescription)" }
    }

    private func poll() async {
        guard let id = job?.id else { return }
        while isWorking || job?.status == "queued" || job?.status == "downloading" || job?.status == "converting" {
            do {
                let (data, _) = try await URLSession.shared.data(from: baseURL.appendingPathComponent("api/download/\(id)"))
                let latest = try JSONDecoder().decode(DownloadJob.self, from: data)
                job = latest
                if latest.status == "completed" {
                    if let path = latest.fileURL, let fileURL = URL(string: path, relativeTo: baseURL) {
                        downloadedData = try? Data(contentsOf: fileURL)
                    }
                    message = "اكتمل التنزيل"; return
                }
                if latest.status == "error" { message = latest.error ?? "فشل التنزيل"; return }
            } catch { message = "انقطع الاتصال بالخادم"; return }
            try? await Task.sleep(for: .seconds(1))
        }
    }
}
