import SwiftUI

struct DownloadView: View {
    @EnvironmentObject private var library: AudioLibrary
    @StateObject private var settings = AppSettings()
    @Environment(\.dismiss) private var dismiss
    @State private var showingSettings = false
    @State private var showSuccess = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.055, green: 0.05, blue: 0.09).ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        hero
                        urlCard
                        statusCard
                        privacyNote
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Download").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } }
                ToolbarItem(placement: .primaryAction) { Button { showingSettings = true } label: { Image(systemName: "gearshape.fill") } }
            }
            .sheet(isPresented: $showingSettings) { BackendSettingsView(settings: settings) }
            .alert("Added to Library", isPresented: $showSuccess) { Button("Done") { dismiss() } } message: { Text("Your downloaded audio is now available offline.") }
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: "arrow.down.circle.fill").font(.system(size: 44)).foregroundStyle(.purple, .blue)
            Text("Download audio").font(.system(size: 34, weight: .bold, design: .rounded))
            Text("Paste a video or playlist link. Audio is converted to high-quality MP3 on your Backend.").foregroundStyle(.white.opacity(0.58))
        }
    }

    private var urlCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Source URL", systemImage: "link")
                .font(.subheadline.weight(.semibold)).foregroundStyle(.white.opacity(0.7))
            TextField("https://…", text: $service.urlText, axis: .vertical)
                .font(.body).textInputAutocapitalization(.never).autocorrectionDisabled().keyboardType(.URL)
                .padding(14).background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 15))
            Button { Task { await service.startDownload() } } label: {
                HStack { Image(systemName: service.isWorking ? "hourglass" : "arrow.down.circle.fill"); Text(service.isWorking ? "Working…" : "Start Download").fontWeight(.semibold); Spacer() }
                .padding(15).background(service.isWorking ? .gray.opacity(0.35) : .purple, in: RoundedRectangle(cornerRadius: 15))
            }.disabled(service.isWorking)
        }
        .padding(18).background(.white.opacity(0.065), in: RoundedRectangle(cornerRadius: 22))
    }

    @ViewBuilder private var statusCard: some View {
        if let job = service.job {
            VStack(alignment: .leading, spacing: 12) {
                HStack { Text(job.title).font(.headline).lineLimit(2); Spacer(); Text("\(Int(job.progress * 100))%").font(.caption.monospacedDigit()).foregroundStyle(.purple) }
                ProgressView(value: job.progress).tint(.purple)
                Text(service.message).font(.subheadline).foregroundStyle(.white.opacity(0.6))
                if job.status == "completed", !service.downloadedFiles.isEmpty {
                    Button { for file in service.downloadedFiles { library.importDownloadedAudio(data: file.data, fileName: "\(file.title).mp3", title: file.title) }; showSuccess = true } label: {
                        Label("Add \(service.downloadedFiles.count) file(s) to Library", systemImage: "checkmark.circle.fill").frame(maxWidth: .infinity)
                    }.buttonStyle(.borderedProminent).tint(.purple)
                }
            }.padding(18).background(.white.opacity(0.065), in: RoundedRectangle(cornerRadius: 22))
        } else if !service.message.isEmpty {
            Text(service.message).font(.subheadline).foregroundStyle(.orange).padding(18).frame(maxWidth: .infinity, alignment: .leading).background(.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 18))
        }
    }

    private var privacyNote: some View {
        Label("Download only content you own or are authorized to save.", systemImage: "checkmark.shield").font(.footnote).foregroundStyle(.white.opacity(0.45))
    }

    @StateObject private var service: DownloadService
    init() {
        let sharedSettings = AppSettings()
        _settings = StateObject(wrappedValue: sharedSettings)
        _service = StateObject(wrappedValue: DownloadService(settings: sharedSettings))
    }
}

struct BackendSettingsView: View {
    @ObservedObject var settings: AppSettings
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            Form {
                Section("Backend URL") {
                    TextField("https://your-server.example.com", text: $settings.backendURL).textInputAutocapitalization(.never).autocorrectionDisabled().keyboardType(.URL)
                    Text("The iPhone cannot reach 127.0.0.1 on your computer. Use a public HTTPS URL or a reachable local network address.").font(.footnote).foregroundStyle(.secondary)
                }
                Section { Text("The server must expose /health, /api/download and /api/download/{id}. Install yt-dlp and ffmpeg on the server.").font(.footnote).foregroundStyle(.secondary) }
            }
            .navigationTitle("Backend Settings")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }
}
