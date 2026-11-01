import Foundation
import AVFoundation
import MediaPlayer

@MainActor
public final class AudioPlayerService: NSObject {
    public static let shared = AudioPlayerService()
    
    private var player: AVQueuePlayer?
    private var timeObserverToken: Any?
    
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
    
    private override init() {
        super.init()
        setupAudioSession()
        setupRemoteCommandCenter()
    }
    
    deinit {
        if let token = timeObserverToken {
            player?.removeTimeObserver(token)
        }
    }
    
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
            Task { @MainActor in
                self?.resume()
            }
            return .success
        }
        
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            Task { @MainActor in
                self?.pause()
            }
            return .success
        }
        
        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            Task { @MainActor in
                self?.skipNext()
            }
            return .success
        }
        
        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            Task { @MainActor in
                self?.skipPrevious()
            }
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
    
    public func play(track: Track, inQueue newQueue: [Track] = []) {
        self.currentTrack = track
        if !newQueue.isEmpty {
            self.queue = newQueue
        } else if !queue.contains(where: { $0.id == track.id }) {
            self.queue.append(track)
        }
        
        onTrackChange?(track)
        
        guard let urlString = track.streamUrl ?? YouTubeMusicService.shared.getStreamUrl(for: track.id),
              let url = URL(string: urlString) else {
            print("Invalid or missing stream URL for track: \(track.title)")
            return
        }
        
        let item = AVPlayerItem(url: url)
        
        if player == nil {
            player = AVQueuePlayer(playerItem: item)
            observeTime()
        } else {
            player?.replaceCurrentItem(with: item)
        }
        
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerItemDidReachEnd),
            name: .AVPlayerItemDidPlayToEndTime,
            object: item
        )
        
        player?.play()
        self.isPlaying = true
        onPlaybackStateChange?(true)
        updateNowPlayingInfo()
    }
    
    public func resume() {
        player?.play()
        isPlaying = true
        onPlaybackStateChange?(true)
        updateNowPlayingPlaybackInfo()
    }
    
    public func pause() {
        player?.pause()
        isPlaying = false
        onPlaybackStateChange?(false)
        updateNowPlayingPlaybackInfo()
    }
    
    public func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            resume()
        }
    }
    
    public func seek(to time: Double) {
        let cmTime = CMTime(seconds: time, preferredTimescale: 600)
        player?.seek(to: cmTime, toleranceBefore: .zero, toleranceAfter: .zero)
        currentTime = time
        onProgressUpdate?(currentTime, duration)
        updateNowPlayingPlaybackInfo()
    }
    
    public func skipNext() {
        guard let current = currentTrack,
              let currentIndex = queue.firstIndex(where: { $0.id == current.id }) else {
            return
        }
        
        let nextIndex = currentIndex + 1
        if nextIndex < queue.count {
            play(track: queue[nextIndex], inQueue: queue)
        } else if isRepeatEnabled, !queue.isEmpty {
            play(track: queue[0], inQueue: queue)
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
    
    @objc private func playerItemDidReachEnd() {
        if isRepeatEnabled {
            seek(to: 0)
            resume()
        } else {
            skipNext()
        }
    }
    
    private func observeTime() {
        let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
        timeObserverToken = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            Task { @MainActor in
                guard let self = self else { return }
                self.currentTime = time.seconds
                if let currentItem = self.player?.currentItem {
                    let durationSecs = currentItem.duration.seconds
                    self.duration = durationSecs.isNaN ? (self.currentTrack?.durationSeconds ?? 0) : durationSecs
                }
                self.onProgressUpdate?(self.currentTime, self.duration)
            }
        }
    }
    
    private func updateNowPlayingInfo() {
        guard let track = currentTrack else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            return
        }
        
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: track.title,
            MPMediaItemPropertyArtist: track.artistName,
            MPMediaItemPropertyPlaybackDuration: track.durationSeconds,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: currentTime,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0
        ]
        
        if let album = track.albumName {
            info[MPMediaItemPropertyAlbumTitle] = album
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
