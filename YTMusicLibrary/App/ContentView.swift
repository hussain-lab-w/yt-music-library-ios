import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject private var library: AudioLibrary
    @State private var showingImporter = false
    @State private var showingShare = false
    @State private var showingDownload = false
    @State private var searchText = ""
    @State private var filter: Filter = .all

    enum Filter: String, CaseIterable { case all = "الكل", favorites = "المفضلة" }

    private var visibleTracks: [AudioTrack] {
        let filtered = filter == .favorites ? library.tracks.filter(\.isFavorite) : library.tracks
        guard !searchText.isEmpty else { return filtered }
        return filtered.filter { $0.title.localizedCaseInsensitiveContains(searchText) || $0.artist.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                LinearGradient(colors: [Color(red: 0.08, green: 0.06, blue: 0.18), .black], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        header
                        filterPicker
                        if visibleTracks.isEmpty { emptyState } else { trackList }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 18)
                    .padding(.bottom, library.selectedTrack == nil ? 24 : 105)
                }
                if let track = library.selectedTrack { NowPlayingBar(track: track).environmentObject(library) }
            }
            .toolbar(.hidden, for: .navigationBar)
            .fileImporter(isPresented: $showingImporter, allowedContentTypes: [.audio], allowsMultipleSelection: true) { result in
                if case .success(let urls) = result { library.importFiles(urls) }
            }
            .sheet(isPresented: $showingShare) { if let url = library.exportPlaylist() { ActivityView(activityItems: [url]) } }
            .sheet(isPresented: $showingDownload) { DownloadView().environmentObject(library) }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("مكتبتي الصوتية").font(.system(size: 32, weight: .bold, design: .rounded))
                    Text("صوتك، مرتب بطريقتك").foregroundStyle(.white.opacity(0.58))
                }
                Spacer()
                Button { showingDownload = true } label: {
                    Image(systemName: "arrow.down.circle.fill").font(.system(size: 28)).foregroundStyle(.purple, .white.opacity(0.9))
                }
                Menu {
                    Button { showingImporter = true } label: { Label("استيراد ملفات", systemImage: "square.and.arrow.down") }
                    Button { showingShare = true } label: { Label("تصدير قائمة M3U", systemImage: "arrow.up.doc") }
                } label: { Image(systemName: "ellipsis.circle.fill").font(.system(size: 28)).foregroundStyle(.purple, .white.opacity(0.9)) }
            }
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass").foregroundStyle(.white.opacity(0.5))
                TextField("ابحث في مكتبتك", text: $searchText).textInputAutocapitalization(.never)
            }
            .padding(13).background(.white.opacity(0.09), in: RoundedRectangle(cornerRadius: 15))
        }
    }

    private var filterPicker: some View {
        HStack(spacing: 8) {
            ForEach(Filter.allCases, id: \.self) { item in
                Button { withAnimation(.easeInOut(duration: 0.2)) { filter = item } } label: {
                    Text(item.rawValue).font(.subheadline.weight(.semibold)).foregroundStyle(filter == item ? .white : .white.opacity(0.55)).padding(.horizontal, 15).padding(.vertical, 9).background(filter == item ? Color.purple : .white.opacity(0.08), in: Capsule())
                }
            }
            Spacer()
            Text("\(library.tracks.count) ملف").font(.caption).foregroundStyle(.white.opacity(0.45))
        }
    }

    private var trackList: some View {
        LazyVStack(spacing: 12) {
            ForEach(visibleTracks) { track in TrackRow(track: track).environmentObject(library) }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "music.note.list").font(.system(size: 48)).foregroundStyle(.purple.opacity(0.9))
            Text(searchText.isEmpty ? "مكتبتك فارغة" : "لا توجد نتائج").font(.title3.bold())
            Text(searchText.isEmpty ? "استورد ملفاتك الصوتية من تطبيق الملفات وابدأ الاستماع." : "جرّب كلمة بحث أخرى.").multilineTextAlignment(.center).foregroundStyle(.white.opacity(0.55))
            if searchText.isEmpty { Button("استيراد ملفات") { showingImporter = true }.buttonStyle(.borderedProminent).tint(.purple) }
        }.frame(maxWidth: .infinity).padding(.top, 75)
    }
}

struct TrackRow: View {
    @EnvironmentObject private var library: AudioLibrary
    let track: AudioTrack
    var body: some View {
        HStack(spacing: 13) {
            Button { library.play(track) } label: {
                ZStack { RoundedRectangle(cornerRadius: 12).fill(LinearGradient(colors: [.purple.opacity(0.8), .blue.opacity(0.5)], startPoint: .topLeading, endPoint: .bottomTrailing)); Image(systemName: "waveform").font(.title3) }.frame(width: 52, height: 52)
            }.buttonStyle(.plain)
            VStack(alignment: .leading, spacing: 4) { Text(track.title).font(.headline).lineLimit(1); Text(track.displayArtist).font(.caption).foregroundStyle(.white.opacity(0.52)).lineLimit(1) }
            Spacer()
            Button { library.toggleFavorite(track) } label: { Image(systemName: track.isFavorite ? "heart.fill" : "heart").foregroundStyle(track.isFavorite ? .pink : .white.opacity(0.45)) }.buttonStyle(.plain)
            Menu { Button(role: .destructive) { library.delete(track) } label: { Label("حذف من المكتبة", systemImage: "trash") } } label: { Image(systemName: "ellipsis").foregroundStyle(.white.opacity(0.5)) }.buttonStyle(.plain)
        }.padding(12).background(.white.opacity(0.075), in: RoundedRectangle(cornerRadius: 17))
    }
}

struct NowPlayingBar: View {
    @EnvironmentObject private var library: AudioLibrary
    let track: AudioTrack
    var body: some View {
        HStack(spacing: 12) { Image(systemName: "waveform.circle.fill").font(.title2).foregroundStyle(.purple); VStack(alignment: .leading) { Text(track.title).font(.subheadline.bold()).lineLimit(1); Text(track.displayArtist).font(.caption).foregroundStyle(.white.opacity(0.55)) }; Spacer(); Button { library.togglePlayback() } label: { Image(systemName: library.isPlaying ? "pause.fill" : "play.fill").font(.title3).frame(width: 42, height: 42).background(.purple, in: Circle()) } }.padding(.horizontal, 18).padding(.vertical, 13).background(.ultraThinMaterial).clipShape(RoundedRectangle(cornerRadius: 22)).padding(.horizontal, 12).padding(.bottom, 8)
    }
}

struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController { UIActivityViewController(activityItems: activityItems, applicationActivities: nil) }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
