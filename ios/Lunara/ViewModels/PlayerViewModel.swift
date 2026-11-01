import SwiftUI
import Observation

@Observable
public final class PlayerViewModel {
    public var currentTrack: Track?
    public var isPlaying: Bool = false
    public var currentTime: Double = 0
    public var duration: Double = 0
    public var isMiniPlayerVisible: Bool = false
    public var isFullScreenPresented: Bool = false
    public var isLyricsPresented: Bool = false
    public var lyrics: [LyricLine] = []
    public var currentLyricIndex: Int?
    
    private let audioService = AudioPlayerService.shared
    private let storageService = StorageService.shared
    
    public init() {
        bindAudioService()
    }
    
    private func bindAudioService() {
        audioService.onTrackChange = { [weak self] track in
            guard let self = self else { return }
            self.currentTrack = track
            self.isMiniPlayerVisible = track != nil
            if let track = track {
                self.loadLyrics(for: track)
            }
        }
        
        audioService.onPlaybackStateChange = { [weak self] playing in
            self?.isPlaying = playing
        }
        
        audioService.onProgressUpdate = { [weak self] time, total in
            guard let self = self else { return }
            self.currentTime = time
            self.duration = total
            self.updateCurrentLyric(time: time)
        }
    }
    
    public func play(track: Track, queue: [Track] = []) {
        var trackToPlay = track
        trackToPlay.isLiked = storageService.isTrackLiked(id: track.id)
        audioService.play(track: trackToPlay, inQueue: queue)
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
        guard duration > 0 else { return }
        let targetTime = progress * duration
        audioService.seek(to: targetTime)
    }
    
    public func toggleLike() {
        guard let track = currentTrack else { return }
        let isLiked = storageService.toggleLike(track: track)
        currentTrack?.isLiked = isLiked
    }
    
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
    
    private func loadLyrics(for track: Track) {
        Task { @MainActor in
            self.lyrics = await YouTubeMusicService.shared.fetchLyrics(
                for: track.id,
                title: track.title,
                artist: track.artistName
            )
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
}
