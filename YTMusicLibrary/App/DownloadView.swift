import SwiftUI

struct DownloadView: View {
    @StateObject private var service = DownloadService()
    @EnvironmentObject private var library: AudioLibrary
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section { TextField("ألصق رابط الفيديو أو القائمة", text: $service.urlText, axis: .vertical).textInputAutocapitalization(.never).autocorrectionDisabled() }
                Section {
                    Button { Task { await service.startDownload() } } label: {
                        HStack { Spacer(); Label(service.isWorking ? "جاري العمل..." : "بدء التنزيل", systemImage: service.isWorking ? "arrow.down.circle" : "play.fill"); Spacer() }
                    }.disabled(service.isWorking)
                    if let job = service.job {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(job.title).font(.headline)
                            ProgressView(value: job.progress).tint(.purple)
                            Text(job.status == "completed" ? "تمت الإضافة إلى المكتبة" : service.message).font(.caption).foregroundStyle(.secondary)
                            if job.status == "completed", let data = service.downloadedData {
                                Button("إضافة إلى مكتبتي") {
                                    library.importDownloadedAudio(data: data, fileName: "\(job.title).mp3", title: job.title)
                                    dismiss()
                                }.buttonStyle(.borderedProminent).tint(.purple)
                            }
                        }
                    } else if !service.message.isEmpty { Text(service.message).foregroundStyle(.secondary) }
                } header: { Text("تنزيل للمحتوى المسموح لك به فقط") }
                Section { Text("يعمل التنزيل عبر خادم yt-dlp منفصل، ثم يحول الصوت إلى MP3 ويعيده للتطبيق.").font(.footnote).foregroundStyle(.secondary) }
            }
            .navigationTitle("تنزيل صوت")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("إغلاق") { dismiss() } } }
        }
    }
}
