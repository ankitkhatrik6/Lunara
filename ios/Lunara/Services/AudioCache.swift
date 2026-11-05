import Foundation

/// Songs you've played, kept on disk automatically — like ExoPlayer's SimpleCache.
/// AVPlayer doesn't persist progressive streams itself, so we fetch the resolved
/// URL in the background while it plays and keep the file under an LRU size cap.
final class AudioCache: ObservableObject {
    static let shared = AudioCache()

    /// Whether songs are cached at all.
    var isEnabled: Bool {
        UserDefaults.standard.object(forKey: "enableSongCache") as? Bool ?? true
    }

    /// Cap in MB: -1 unlimited, 0 disabled, anything else is MB figure. Default 512.
    var limitMB: Int {
        guard UserDefaults.standard.object(forKey: "songCacheLimitMB") != nil else { return 512 }
        return UserDefaults.standard.integer(forKey: "songCacheLimitMB")
    }

    var limitBytes: Int64? {
        limitMB < 0 ? nil : Int64(limitMB) * 1024 * 1024
    }

    @Published private(set) var tracks: [String] = []  // videoIds cached
    @Published private(set) var sizeBytes: Int64 = 0

    private let dir: URL
    private let metaURL: URL
    private var lastUsed: [String: Date] = [:]
    private var inFlight: Set<String> = []

    private init() {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        dir = caches.appendingPathComponent("AudioCache", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        metaURL = dir.appendingPathComponent("cache.json")
        load()
        refreshSize()
    }

    // MARK: - Lookup

    private func fileURL(for id: String) -> URL { dir.appendingPathComponent("\(id).m4a") }
    private func artFileURL(for id: String) -> URL { dir.appendingPathComponent("\(id).jpg") }

    /// Artwork for a cached song.
    func cachedArtURL(for id: String) -> URL? {
        guard lastUsed[id] != nil else { return nil }
        return localArtURL(for: id)
    }

    func localArtURL(for id: String) -> URL? {
        let u = artFileURL(for: id)
        return FileManager.default.fileExists(atPath: u.path) ? u : nil
    }

    /// Is this track cached?
    func isCached(_ id: String) -> Bool {
        FileManager.default.fileExists(atPath: fileURL(for: id).path)
    }

    /// Add a track to cache (called after playback starts).
    func cache(trackId: String, url: URL) {
        guard isEnabled else { return }
        guard !inFlight.contains(trackId) else { return }
        inFlight.insert(trackId)

        Task.detached(priority: .background) { [weak self] in
            guard let self = self else { return }

            var req = URLRequest(url: url)
            req.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Safari/605.1.15",
                         forHTTPHeaderField: "User-Agent")

            var didStore = false
            if let (tmp, response) = try? await URLSession.shared.download(for: req),
               (response as? HTTPURLResponse)?.statusCode ?? 200 < 400 {
                let dest = self.fileURL(for: trackId)
                try? FileManager.default.removeItem(at: dest)
                didStore = (try? FileManager.default.moveItem(at: tmp, to: dest)) != nil
            }

            let stored = didStore
            await MainActor.run {
                self.inFlight.remove(trackId)
                guard stored else { return }
                self.lastUsed[trackId] = Date()
                if !self.tracks.contains(trackId) {
                    self.tracks.insert(trackId, at: 0)
                }
                self.save()
                self.evictIfNeeded()
                self.refreshSize()
            }
        }
    }

    // MARK: - Housekeeping

    private func measure() -> Int64 {
        (try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: [.fileSizeKey]))?
            .reduce(Int64(0)) { total, url in
                total + Int64((try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0)
            } ?? 0
    }

    func refreshSize() {
        Task.detached(priority: .utility) { [weak self] in
            guard let self else { return }
            let size = self.measure()
            await MainActor.run { self.sizeBytes = size }
        }
    }

    private func evictIfNeeded() {
        guard let cap = limitBytes, measure() > cap else { return }
        let order = tracks.sorted {
            (lastUsed[$0] ?? .distantPast) < (lastUsed[$1] ?? .distantPast)
        }
        for trackId in order {
            guard measure() > cap else { break }
            remove(trackId)
        }
    }

    func remove(_ id: String) {
        try? FileManager.default.removeItem(at: fileURL(for: id))
        try? FileManager.default.removeItem(at: artFileURL(for: id))
        tracks.removeAll { $0 == id }
        lastUsed[id] = nil
        save()
    }

    func clear() {
        for id in tracks {
            try? FileManager.default.removeItem(at: fileURL(for: id))
        }
        tracks = []
        lastUsed = [:]
        save()
        sizeBytes = 0
    }

    // MARK: - Persistence

    private struct Meta: Codable {
        let tracks: [String]
        let lastUsed: [String: Date]
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(Meta(tracks: tracks, lastUsed: lastUsed)) else { return }
        try? data.write(to: metaURL)
    }

    private func load() {
        guard let data = try? Data(contentsOf: metaURL),
              let meta = try? JSONDecoder().decode(Meta.self, from: data) else { return }
        lastUsed = meta.lastUsed
        tracks = meta.tracks.filter { isCached($0) }
    }
}
