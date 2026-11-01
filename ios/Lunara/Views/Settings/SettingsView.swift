import SwiftUI

public struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isHighQuality: Bool = StorageService.shared.isHighQualityAudioEnabled()
    @State private var isCacheCleared: Bool = false
    @State private var darkMode: Bool = false
    @State private var pureBlack: Bool = true

    public init() {}

    public var body: some View {
        NavigationStack {
            List {
                Section(header: Text("APPEARANCE").foregroundColor(.spotifyTextMuted)) {
                    Picker("Theme", selection: $darkMode) {
                        Text("Light").tag(false)
                        Text("Dark").tag(true)
                    }
                    .pickerStyle(.segmented)
                    .foregroundColor(.spotifyTextPrimary)

                    Toggle("Pure Black", isOn: $pureBlack)
                        .foregroundColor(.spotifyTextPrimary)
                        .tint(.spotifyGreen)
                }
                .listRowBackground(Color.spotifyCardSurface)

                Section(header: Text("AUDIO QUALITY").foregroundColor(.spotifyTextMuted)) {
                    Toggle("Very High Quality (256 kbps)", isOn: $isHighQuality)
                        .tint(.spotifyGreen)
                        .foregroundColor(.spotifyTextPrimary)
                        .onChange(of: isHighQuality) { _, enabled in
                            StorageService.shared.setHighQualityAudio(enabled: enabled)
                        }

                    HStack {
                        Text("Equalizer")
                        Spacer()
                        Text("Standard")
                            .foregroundColor(.spotifyTextMuted)
                    }
                }
                .listRowBackground(Color.spotifyCardSurface)

                Section(header: Text("STORAGE & CACHE").foregroundColor(.spotifyTextMuted)) {
                    Button {
                        isCacheCleared = true
                    } label: {
                        HStack {
                            Text(isCacheCleared ? "Cache Cleared (0 MB)" : "Clear Audio Cache")
                                .foregroundColor(isCacheCleared ? .spotifyGreen : .spotifyTextPrimary)
                            Spacer()
                            if !isCacheCleared {
                                Text("142 MB")
                                    .foregroundColor(.spotifyTextMuted)
                            }
                        }
                    }
                }
                .listRowBackground(Color.spotifyCardSurface)

                Section(header: Text("ABOUT").foregroundColor(.spotifyTextMuted)) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0 (Build 1)")
                            .foregroundColor(.spotifyTextMuted)
                    }

                    HStack {
                        Text("Platform")
                        Spacer()
                        Text("iOS Native (SwiftUI)")
                            .foregroundColor(.spotifyTextMuted)
                    }
                }
                .listRowBackground(Color.spotifyCardSurface)
            }
            .scrollContentBackground(.hidden)
            .background(Color.spotifyBackground.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.spotifyGreen)
                }
            }
        }
    }
}
