import SwiftUI
import Observation
import AVFoundation

@Observable
@MainActor
public final class PlayerViewModel {
    public var currentTrack: Track?
    public var isPlaying: Bool = false
    public var currentTime: Double = 0
    public var duration: Double = 0
    public var isMiniPlayerVisible: Bool = false
    public var isFullScreenPresented: Bool = false
    public var isLyricsPresented: Bool = false
    public var isQueuePresented: Bool = false
    public var isSleepTimerPresented: Bool = false
    public var lyrics: [LyricLine] = []
    public var currentLyricIndex: Int?
    public var queue: [Track] = []
    public var queueIndex: Int = 0
    public var sleepTimerRemaining: Int? = nil
    public var sleepTimerActive: Bool = false
    public var repeatMode: RepeatMode = .off
    public var shuffleEnabled: Bool = false

    public enum RepeatMode: String, CaseIterable {
        case off = "off"
        case all = "all"
        case one = "one"
    }

    private let audioService = AudioPlayerService.shared
    private let storageService = StorageService.shared
    private var sleepTimerTask: Task<Void, Never>?

    public init() {
        bindAudioService()
    }

    private func bindAudioService() {
        audioService.onTrackChange = { [weak self] track in
            Task { @MainActor in
                self?.currentTrack = track
                self?.isMiniPlayerVisible = track != nil
                self?.updateQueueFromTrack(track)
                if let track = track {
                    self?.loadLyrics(for: track)
                }
            }
        }

        audioService.onPlaybackStateChange = { [weak self] playing in
            Task { @MainActor in
                self?.isPlaying = playing
            }
        }

        audioService.onProgressUpdate = { [weak self] time, total in
            Task { @MainActor in
                self?.currentTime = time
                self?.duration = total
                self?.updateCurrentLyric(time: time)
                self?.checkSleepTimer()
            }
        }
    }

    // MARK: - Playback

    public func play(track: Track, inQueue newQueue: [Track] = []) {
        var trackToPlay = track
        trackToPlay.isLiked = storageService.isTrackLiked(id: track.id)

        if !newQueue.isEmpty {
            self.queue = newQueue
            if let idx = self.queue.firstIndex(where: { $0.id == track.id }) {
                self.queueIndex = idx
            } else {
                self.queue.append(trackToPlay)
                self.queueIndex = self.queue.count - 1
            }
        }

        audioService.play(track: trackToPlay, inQueue: newQueue)
    }

    public func playQueueItem(at index: Int) {
        guard index >= 0, index < queue.count else { return }
        queueIndex = index
        let track = queue[index]
        var trackToPlay = track
        trackToPlay.isLiked = storageService.isTrackLiked(id: track.id)
        audioService.play(track: trackToPlay, inQueue: queue)
    }

    public func removeFromQueue(at index: Int) {
        guard index >= 0, index < queue.count else { return }
        queue.remove(at: index)
        if queueIndex >= queue.count {
            queueIndex = max(0, queue.count - 1)
        }
        if queueIndex >= 0, queueIndex < queue.count {
            let track = queue[queueIndex]
            var trackToPlay = track
            trackToPlay.isLiked = storageService.isTrackLiked(id: track.id)
            audioService.play(track: trackToPlay, inQueue: queue)
        } else {
            currentTrack = nil
            isPlaying = false
        }
    }

    public func clearQueue() {
        queue.removeAll()
        queueIndex = 0
        currentTrack = nil
        isPlaying = false
        audioService.pause()
    }

    public func togglePlayPause() {
        audioService.togglePlayPause()
    }

    public func skipNext() {
        audioService.skipNext()
    }

    public func skipPrevious() {
        audioService.skipPrevious()
    }

    public func seek(to progress: Double) {
        audioService.seek(to: progress)
    }

    public func seekToTime(_ time: Double) {
        audioService.seek(to: time)
    }

    public func toggleLike() {
        guard let track = currentTrack else { return }
        let isLiked = storageService.toggleLike(track: track)
        currentTrack?.isLiked = isLiked
        if let idx = queue.firstIndex(where: { $0.id == track.id }) {
            queue[idx].isLiked = isLiked
        }
    }

    public func toggleRepeat() {
        switch repeatMode {
        case .off: repeatMode = .all
        case .all: repeatMode = .one
        case .one: repeatMode = .off
        }
    }

    public func toggleShuffle() {
        shuffleEnabled.toggle()
        if shuffleEnabled && queue.count > 1 {
            queue.shuffle()
            if let current = currentTrack, let idx = queue.firstIndex(where: { $0.id == current.id }) {
                queueIndex = idx
            }
        }
    }

    public func startSleepTimer(minutes: Int) {
        sleepTimerRemaining = minutes * 60
        sleepTimerActive = true
        sleepTimerTask?.cancel()
        sleepTimerTask = Task {
            while sleepTimerRemaining ?? 0 > 0 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                await MainActor.run {
                    sleepTimerRemaining = (sleepTimerRemaining ?? 0) - 1
                }
            }
            await MainActor.run {
                sleepTimerActive = false
                sleepTimerRemaining = nil
                pause()
            }
        }
    }

    public func stopSleepTimer() {
        sleepTimerTask?.cancel()
        sleepTimerTask = nil
        sleepTimerActive = false
        sleepTimerRemaining = nil
    }

    private func checkSleepTimer() {
        if sleepTimerActive, let remaining = sleepTimerRemaining, remaining <= 0 {
            pause()
        }
    }

    public func pause() {
        audioService.pause()
    }

    // MARK: - Computed

    public var progress: Double {
        guard duration > 0 else { return 0 }
        return min(max(currentTime / duration, 0), 1)
    }

    public var formattedCurrentTime: String {
        let mins = Int(currentTime) / 60
        let secs = Int(currentTime) % 60
        return String(format: "%d:%02d", mins, secs)
    }

    public var formattedDuration: String {
        let mins = Int(duration) / 60
        let secs = Int(duration) % 60
        return String(format: "%d:%02d", mins, secs)
    }

    public var sleepTimeRemainingFormatted: String {
        guard let remaining = sleepTimerRemaining else { return "Off" }
        let mins = remaining / 60
        let secs = remaining % 60
        return String(format: "%d:%02d", mins, secs)
    }

    // MARK: - Lyrics

    private func loadLyrics(for track: Track) {
        Task { @MainActor in
            do {
                let lyricsResult = try await YouTubeMusicService.shared.fetchLyrics(
                    for: track.id,
                    title: track.title,
                    artist: track.artist
                )
                self.lyrics = lyricsResult.lines
            } catch {
                self.lyrics = []
            }
        }
    }

    private func updateCurrentLyric(time: Double) {
        guard !lyrics.isEmpty else {
            currentLyricIndex = nil
            return
        }
        let foundIndex = lyrics.lastIndex(where: { $0.timestamp <= time })
        if currentLyricIndex != foundIndex {
            currentLyricIndex = foundIndex
        }
    }

    private func updateQueueFromTrack(_ track: Track) {
        if let idx = queue.firstIndex(where: { $0.id == track.id }) {
            queueIndex = idx
        } else {
            queue.append(track)
            queueIndex = queue.count - 1
        }
    }
}
