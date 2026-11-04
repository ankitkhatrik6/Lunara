import SwiftUI

public struct PlayerSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State var playerVM: PlayerViewModel
    @State private var crossfadeEnabled: Bool = false
    @State private var crossfadeSeconds: Int = 3
    @State private var gaplessPlayback: Bool = true
    @State private var normalizeVolume: Bool = true

    public init(playerVM: PlayerViewModel) {
        self.playerVM = playerVM
    }

    public var body: some View {
        NavigationStack {
            List {
                Section(header: Text("PLAYBACK").foregroundColor(.spotifyTextMuted)) {
                    Toggle("Crossfade", isOn: $crossfadeEnabled)
                        .foregroundColor(.spotifyTextPrimary)
                        .tint(.spotifyGreen)

                    if crossfadeEnabled {
                        HStack {
                            Text("Crossfade Duration")
                                .foregroundColor(.spotifyTextPrimary)
                            Spacer()
                            Picker("\(crossfadeSeconds)s", selection: $crossfadeSeconds) {
                                ForEach([1, 2, 3, 4, 5, 6, 7, 8, 9, 10], id: \.self) {
                                    Text("\($0)s").tag($0)
                                }
                            }
                            .pickerStyle(.menu)
                            .foregroundColor(.spotifyTextPrimary)
                        }
                    }

                    Toggle("Gapless Playback", isOn: $gaplessPlayback)
                        .foregroundColor(.spotifyTextPrimary)
                        .tint(.spotifyGreen)

                    Toggle("Normalize Volume", isOn: $normalizeVolume)
                        .foregroundColor(.spotifyTextPrimary)
                        .tint(.spotifyGreen)
                }
                .listRowBackground(Color.spotifyCardSurface)

                Section(header: Text("SLEEP TIMER").foregroundColor(.spotifyTextMuted)) {
                    HStack {
                        Text("Sleep Timer")
                            .foregroundColor(.spotifyTextPrimary)
                        Spacer()
                        Text(playerVM.sleepTimeRemainingFormatted)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.spotifyGreen)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        playerVM.isSleepTimerPresented = true
                    }

                    HStack(spacing: 12) {
                        SleepTimerButton(minutes: 15, label: "15 min", playerVM: playerVM)
                        SleepTimerButton(minutes: 30, label: "30 min", playerVM: playerVM)
                        SleepTimerButton(minutes: 60, label: "1 hour", playerVM: playerVM)
                    }
                    .padding(.vertical, 8)

                    if playerVM.sleepTimerActive {
                        Button {
                            playerVM.stopSleepTimer()
                        } label: {
                            Text("Cancel Sleep Timer")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.red)
                        }
                    }
                }
                .listRowBackground(Color.spotifyCardSurface)

                Section(header: Text("AUDIO").foregroundColor(.spotifyTextMuted)) {
                    HStack {
                        Text("Audio Quality")
                            .foregroundColor(.spotifyTextPrimary)
                        Spacer()
                        Text("High (256 kbps)")
                            .foregroundColor(.spotifyTextMuted)
                    }
                    .contentShape(Rectangle())

                    HStack {
                        Text("Download Quality")
                            .foregroundColor(.spotifyTextPrimary)
                        Spacer()
                        Text("High (256 kbps)")
                            .foregroundColor(.spotifyTextMuted)
                    }
                    .contentShape(Rectangle())
                }
                .listRowBackground(Color.spotifyCardSurface)
            }
            .background(Color.spotifyBackground.ignoresSafeArea())
            .navigationTitle("Player & Audio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.spotifyGreen)
                }
            }
            .sheet(isPresented: $playerVM.isSleepTimerPresented) {
                SleepTimerView(playerVM: playerVM)
            }
        }
    }
}
public struct SleepTimerButton: View {
    let minutes: Int
    let label: String
    @State var playerVM: PlayerViewModel

    public var body: some View {
        Button {
            playerVM.startSleepTimer(minutes: minutes)
        } label: {
            VStack(spacing: 4) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 20))
                    .foregroundColor(playerVM.sleepTimerActive ? .spotifyGreen : .spotifyTextMuted)
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(playerVM.sleepTimerActive ? .spotifyGreen : .spotifyTextSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(playerVM.sleepTimerActive ? Color.spotifyGreen.opacity(0.15) : Color.spotifyCardSurface)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

public struct SleepTimerView: View {
    @State var playerVM: PlayerViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedMinutes: Int = 30

    public init(playerVM: PlayerViewModel) {
        self.playerVM = playerVM
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                VStack(spacing: 8) {
                    Image(systemName: "moon.zzz.fill")
                        .font(.system(size: 60, weight: .light))
                        .foregroundColor(.spotifyGreen)
                    Text("Sleep Timer")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.spotifyTextPrimary)
                }

                VStack(spacing: 20) {
                    HStack {
                        Text("Stop playback after:")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.spotifyTextPrimary)
                        Spacer()
                        Text(playerVM.sleepTimeRemainingFormatted)
                            .font(.system(size: 32, weight: .bold, design: .monospaced))
                            .foregroundColor(.spotifyGreen)
                    }

                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        ForEach([15, 30, 45, 60, 90, 120], id: \.self) { minutes in
                            SleepTimerButton(
                                minutes: minutes,
                                label: "\(minutes) min",
                                playerVM: playerVM
                            )
                        }
                    }
                }

                Spacer()

                if playerVM.sleepTimerActive {
                    Button {
                        playerVM.stopSleepTimer()
                    } label: {
                        Text("Cancel Timer")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.red.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                } else {
                    Button {
                        playerVM.startSleepTimer(minutes: selectedMinutes)
                        dismiss()
                    } label: {
                        Text("Start Timer")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.spotifyGreen)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
            }
            .padding(24)
            .background(Color.spotifyBackground.ignoresSafeArea())
            .navigationTitle("Sleep Timer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.spotifyGreen)
                }
            }
        }
    }
}
