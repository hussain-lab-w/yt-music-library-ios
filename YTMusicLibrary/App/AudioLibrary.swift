import Foundation
import AVFoundation
import UniformTypeIdentifiers

struct AudioTrack: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var artist: String
    var album: String
    var fileName: String
    var isFavorite: Bool = false
    var addedAt: Date = .now

    var displayArtist: String { artist.isEmpty ? "Unknown artist" : artist }
}

@MainActor
final class AudioLibrary: ObservableObject {
    @Published private(set) var tracks: [AudioTrack] = []
    @Published var selectedTrack: AudioTrack?
    @Published var isPlaying = false

    private let player = AVAudioPlayerController()
    private let fileManager = FileManager.default
    private var libraryURL: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("library.json")
    }
    private var audioFolder: URL {
        let folder = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Audio", isDirectory: true)
        try? fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder
    }

    init() {
        load()
        player.onFinish = { [weak self] in
            Task { @MainActor in self?.isPlaying = false }
        }
    }

    func importFiles(_ urls: [URL]) {
        for url in urls {
            guard url.startAccessingSecurityScopedResource() else { continue }
            defer { url.stopAccessingSecurityScopedResource() }
            let destination = audioFolder.appendingPathComponent("\(UUID().uuidString)-\(url.lastPathComponent)")
            do {
                try fileManager.copyItem(at: url, to: destination)
                let title = url.deletingPathExtension().lastPathComponent
                tracks.insert(AudioTrack(id: UUID(), title: title, artist: "", album: "", fileName: destination.lastPathComponent), at: 0)
            } catch { continue }
        }
        save()
    }

    func importDownloadedAudio(data: Data, fileName: String, title: String) {
        let safeName = "\(UUID().uuidString)-\(fileName)"
        do {
            try data.write(to: audioFolder.appendingPathComponent(safeName), options: .atomic)
            tracks.insert(AudioTrack(id: UUID(), title: title, artist: "", album: "", fileName: safeName), at: 0)
            save()
        } catch { }
    }

    func toggleFavorite(_ track: AudioTrack) {
        guard let index = tracks.firstIndex(where: { $0.id == track.id }) else { return }
        tracks[index].isFavorite.toggle()
        save()
    }

    func play(_ track: AudioTrack) {
        let url = audioFolder.appendingPathComponent(track.fileName)
        selectedTrack = track
        isPlaying = player.play(url: url)
    }

    func togglePlayback() {
        if player.isPlaying { player.pause(); isPlaying = false }
        else if selectedTrack != nil { player.resume(); isPlaying = player.isPlaying }
    }

    func delete(_ track: AudioTrack) {
        if selectedTrack?.id == track.id { player.stop(); selectedTrack = nil; isPlaying = false }
        let url = audioFolder.appendingPathComponent(track.fileName)
        try? fileManager.removeItem(at: url)
        tracks.removeAll { $0.id == track.id }
        save()
    }

    func exportPlaylist() -> URL? {
        let contents = ["#EXTM3U"] + tracks.map(\.fileName)
        let url = fileManager.temporaryDirectory.appendingPathComponent("My-Library.m3u8")
        do { try contents.joined(separator: "\n").write(to: url, atomically: true, encoding: .utf8); return url }
        catch { return nil }
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(tracks) else { return }
        try? data.write(to: libraryURL, options: .atomic)
    }

    private func load() {
        guard let data = try? Data(contentsOf: libraryURL),
              let saved = try? JSONDecoder().decode([AudioTrack].self, from: data) else { return }
        tracks = saved
    }
}

final class AVAudioPlayerController: NSObject, AVAudioPlayerDelegate {
    private var player: AVAudioPlayer?
    var onFinish: (() -> Void)?
    var isPlaying: Bool { player?.isPlaying == true }

    func play(url: URL) -> Bool {
        do { player = try AVAudioPlayer(contentsOf: url); player?.delegate = self; player?.prepareToPlay(); return player?.play() == true }
        catch { return false }
    }
    func pause() { player?.pause() }
    func resume() { player?.play() }
    func stop() { player?.stop() }
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) { onFinish?() }
}
