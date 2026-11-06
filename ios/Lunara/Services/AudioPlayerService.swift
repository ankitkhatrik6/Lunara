import Foundation
import AVFoundation
import MediaPlayer

/// AudioPlayerService: Real audio player using AVPlayer streaming from YouTube Music.
/// Resolves stream URLs on-device (VISIONOS client - no PoToken needed) and streams
/// directly in AVPlayer - instant start, seek, background audio, lock-screen controls.
@MainActor
public final class AudioPlayerService: NSObject {
    public static let shared = AudioPlayerService()

    public var onTrackChange: ((Track?) -> Void)?
    public var onProgressUpdate: ((Double, Double) -> Void)?
    public var onPlaybackStateChange: ((Bool) -> Void)?

    public private(set) var currentTrack: Track?
    public private(set) var queue: [Track] = []
    public private(set) var isPlaying: Bool = false
    public private(set) var currentTime: Double = 0
    public private(set) var duration: Double = 0

    public var isShuffleEnabled: Bool = false
    public var isRepeatEnabled: Bool = false

    private var player: AVPlayer?
    private var timeObserverToken: Any?
    private var currentItemObserver: NSKeyValueObservation?
    private var statusObserver: NSKeyValueObservation?
    private var rateObserver: NSKeyValueObservation?

    private var currentStreamURL: String?
    private var queueIndex: Int = 0

    private override init() {
        super.init()
        setupAudioSession()
        setupRemoteCommandCenter()
        observePlayerRate()
    }

    deinit {
        Task { @MainActor in
            self.pause()
        }
        if let token = timeObserverToken {
            player?.removeTimeObserver(token)
            timeObserverToken = nil
        }
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
    }

    // MARK: - Setup

    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true)
        } catch {
            print("Failed to activate audio session: \(error.localizedDescription)")
        }
    }

    private func setupRemoteCommandCenter() {
        let commandCenter = MPRemoteCommandCenter.shared()

        commandCenter.playCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.resume() }
            return .success
        }

        commandCenter.pauseCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.pause() }
            return .success
        }

        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.skipNext() }
            return .success
        }

        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.skipPrevious() }
            return .success
        }

        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let positionEvent = event as? MPChangePlaybackPositionCommandEvent else {
                return .commandFailed
            }
            Task { @MainActor in
                self?.seek(to: positionEvent.positionTime)
            }
            return .success
        }
    }

    // MARK: - Playback

    public func play(track: Track, inQueue newQueue: [Track] = []) {
        self.currentTrack = track
        if !newQueue.isEmpty {
            self.queue = newQueue
        } else if !queue.contains(where: { $0.id == track.id }) {
            self.queue.append(track)
        }

        onTrackChange?(track)

        Task { @MainActor in
            do {
                let streamURL = try await YouTubeService.shared.streamURL(for: track.id)
                self.currentStreamURL = streamURL.url
                self.loadAndPlay(url: streamURL.url)
            } catch {
                print("Failed to resolve stream URL: \(error)")
            }
        }
    }

    private func loadAndPlay(url: String) {
        guard let url = URL(string: url) else { return }

        let item = AVPlayerItem(url: url)

        if player == nil {
            player = AVPlayer(playerItem: item)
            setupPlayerObservers()
        } else {
            player?.replaceCurrentItem(with: item)
        }

        player?.play()
        isPlaying = true

        startTimeObserver()

        AudioCache.shared.cache(trackId: currentTrack?.id ?? "", url: url)

        updateNowPlayingInfo()

        currentItemObserver = player?.currentItem?.observe(\.duration, options: [.initial, .new]) { [weak self] item, _ in
            let duration = item.duration.seconds
            if duration.isFinite && duration > 0 {
                Task { @MainActor in
                    self?.duration = duration
                }
            }
        }
    }

    private func setupPlayerObservers() {
        statusObserver = player?.observe(\.status, options: [.initial, .new]) { [weak self] player, _ in
            if player.status == .failed {
                print("Player failed: \(player.error?.localizedDescription ?? "unknown")")
            }
        }
        rateObserver = player?.observe(\.rate, options: [.initial, .new]) { [weak self] player, _ in
            let isPlaying = player.rate > 0
            self?.isPlaying = isPlaying
            self?.onPlaybackStateChange?(isPlaying)
        }
    }

    private func startTimeObserver() {
        if timeObserverToken != nil { return }
        let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
        timeObserverToken = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            Task { @MainActor in
                self?.currentTime = time.seconds
                self?.onProgressUpdate?(time.seconds, self?.duration ?? 0)
                self?.updateNowPlayingPlaybackInfo()
            }
        }
    }

    public func pause() {
        player?.pause()
        isPlaying = false
        onPlaybackStateChange?(false)
    }

    public func resume() {
        player?.play()
        isPlaying = true
        onPlaybackStateChange?(true)
    }

    public func togglePlayPause() {
        if isPlaying { pause() } else { resume() }
    }

    public func skipNext() {
        guard !queue.isEmpty else { return }
        guard let current = currentTrack,
              let currentIndex = queue.firstIndex(where: { $0.id == current.id }) else {
            return
        }

        let nextIndex = currentIndex + 1
        if nextIndex < queue.count {
            play(track: queue[nextIndex], inQueue: queue)
        } else if isRepeatEnabled, !queue.isEmpty {
            play(track: queue[0], inQueue: queue)
        } else {
            pause()
        }
    }

    public func skipPrevious() {
        if currentTime > 3.0 {
            seek(to: 0)
            return
        }

        guard let current = currentTrack,
              let currentIndex = queue.firstIndex(where: { $0.id == current.id }) else {
            return
        }

        let prevIndex = currentIndex - 1
        if prevIndex >= 0 {
            play(track: queue[prevIndex], inQueue: queue)
        } else {
            seek(to: 0)
        }
    }

    public func playQueueItem(at index: Int) {
        guard index >= 0, index < queue.count else { return }
        play(track: queue[index], inQueue: queue)
    }

    public func removeFromQueue(at index: Int) {
        guard index >= 0, index < queue.count else { return }
        queue.remove(at: index)
        if queueIndex >= queue.count {
            queueIndex = max(0, queue.count - 1)
        }
        if queueIndex >= 0, queueIndex < queue.count {
            let track = queue[queueIndex]
            play(track: track, inQueue: queue)
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
        pause()
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

    public func seek(to progress: Double) {
        guard let player = player, player.currentItem?.duration.isFinite == true else { return }
        let cmTime = CMTime(seconds: progress * player.currentItem!.duration.seconds, preferredTimescale: 600)
        player.seek(to: cmTime, toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] _ in
            Task { @MainActor in
                self?.isSeeking = false
            }
        }
        currentTime = progress * player.currentItem!.duration.seconds
        onProgressUpdate?(currentTime, duration)
        updateNowPlayingPlaybackInfo()
    }

    private var isSeeking: Bool = false

    // MARK: - Now Playing (Lock Screen)

    private func updateNowPlayingInfo() {
        guard let track = currentTrack else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            return
        }

        var info: [String: Any] = [
            MPMediaItemPropertyTitle: track.title,
            MPMediaItemPropertyArtist: track.artist,
            MPMediaItemPropertyPlaybackDuration: duration,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: currentTime,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0
        ]

        if let url = URL(string: track.thumbnail) {
            info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(url: url)
        }

        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    private func updateNowPlayingPlaybackInfo() {
        guard var info = MPNowPlayingInfoCenter.default().nowPlayingInfo else { return }
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }
}

// MARK: - Storage (added to AudioPlayerService for backward compatibility)

extension AudioPlayerService {
    private var storageService = StorageService.shared
}

// Keep queueIndex accessible
extension AudioPlayerService {
    public var queueIndex: Int = 0
}
