import SwiftUI

public struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isHighQuality: Bool = StorageService.shared.isHighQualityAudioEnabled()
    @State private var isCacheCleared: Bool = false
    @State private var showingLogin: Bool = false
    @State private var showingLastFM: Bool = false

    public init() {}

    public var body: some View {
        NavigationStack {
            List {
                Section(header: Text("ACCOUNT").foregroundColor(.spotifyTextMuted)) {
                    Button {
                        showingLogin = true
                    } label: {
                        HStack {
                            Text(Auth.shared.isLoggedIn ? "Signed In" : "Sign In to YouTube Music")
                                .foregroundColor(Auth.shared.isLoggedIn ? .spotifyGreen : .spotifyTextPrimary)
                            Spacer()
                            if Auth.shared.isLoggedIn {
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.spotifyTextMuted)
                            }
                        }
                    }

                    if Auth.shared.isLoggedIn {
                        Button {
                            Auth.shared.signOut()
                        } label: {
                            Text("Sign Out")
                                .foregroundColor(.red)
                        }
                    }
                }
                .listRowBackground(Color.spotifyCardSurface)

                Section(header: Text("APPEARANCE").foregroundColor(.spotifyTextMuted)) {
                    NavigationLink {
                        AppearanceSettingsView()
                    } label: {
                        Text("Theme & Appearance")
                    }
                }
                .listRowBackground(Color.spotifyCardSurface)

                Section(header: Text("AUDIO QUALITY").foregroundColor(.spotifyTextMuted)) {
                    Toggle("Very High Quality (256 kbps)", isOn: $isHighQuality)
                        .tint(.spotifyGreen)
                        .foregroundColor(.spotifyTextPrimary)
                        .onChange(of: isHighQuality) { _, enabled in
                            StorageService.shared.setHighQualityAudio(enabled: enabled)
                        }

                    NavigationLink {
                        EqualizerView()
                    } label: {
                        Text("Equalizer")
                    }
                }
                .listRowBackground(Color.spotifyCardSurface)
                Section(header: Text("LIBRARY").foregroundColor(.spotifyTextMuted)) {
                    NavigationLink {
                        BlockedArtistsView()
                    } label: {
                        Text("Blocked Artists")
                    }

                    NavigationLink {
                        SpeedDialView()
                    } label: {
                        Text("Speed Dial")
                    }

                    NavigationLink {
                        DownloadsView()
                    } label: {
                        Text("Downloads")
                    }
                }
                .listRowBackground(Color.spotifyCardSurface)

                Section(header: Text("LAST.FM").foregroundColor(.spotifyTextMuted)) {
                    Button {
                        showingLastFM = true
                    } label: {
                        HStack {
                            Text("Last.fm Scrobbling")
                            Spacer()
                            Text(LastFM.shared.isConnected ? "Connected" : "Disconnect")
                                .foregroundColor(LastFM.shared.isConnected ? .spotifyGreen : .spotifyTextMuted)
                        }
                    }
                }
                .listRowBackground(Color.spotifyCardSurface)

                Section(header: Text("HISTORY & STATS").foregroundColor(.spotifyTextMuted)) {
                    NavigationLink {
                        HistoryView()
                    } label: {
                        Text("Play History")
                    }

                    NavigationLink {
                        StatsView()
                    } label: {
                        Text("Listening Stats")
                    }

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
            .sheet(isPresented: $showingLogin) {
                LoginView()
            }
            .sheet(isPresented: $showingLastFM) {
                LastFMSettingsView()
            }
        }
    }
}
public struct AppearanceSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var darkMode: Bool = false
    @State private var pureBlack: Bool = true

    public init() {}

    public var body: some View {
        NavigationStack {
            List {
                Section(header: Text("THEME").foregroundColor(.spotifyTextMuted)) {
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
            }
            .scrollContentBackground(.hidden)
            .background(Color.spotifyBackground.ignoresSafeArea())
            .navigationTitle("Appearance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.spotifyGreen)
                }
            }
        }
    }
}

public struct LastFMSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var apiKey: String = ""
    @State private var secret: String = ""
    @State private var statusMessage: String? = nil

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("API Key")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.spotifyTextPrimary)

                        TextField("Last.fm API Key", text: $apiKey)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.spotifyTextPrimary)
                            .padding(10)
                            .background(Color.spotifyCardSurface)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .padding(.horizontal, 20)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("API Secret")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.spotifyTextPrimary)

                        TextField("Last.fm API Secret", text: $secret)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.spotifyTextPrimary)
                            .padding(10)
                            .background(Color.spotifyCardSurface)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .padding(.horizontal, 20)

                    Button {
                        LastFM.shared.saveCredentials(key: apiKey, secret: secret)
                        statusMessage = "Credentials saved."
                    } label: {
                        Text("Save Credentials")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.spotifyGreen)
                            .clipShape(Capsule())
                    }
                    .padding(.horizontal, 20)

                    if LastFM.shared.isConnected {
                        Button {
                            LastFM.shared.disconnect()
                            statusMessage = "Disconnected from Last.fm."
                        } label: {
                            Text("Disconnect")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.red)
                        }
                        .padding(.top, 8)
                    }

                    if let status = statusMessage {
                        Text(status)
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.spotifyGreen)
                            .padding(.top, 8)
                    }

                    Spacer(minLength: 40)
                }
            }
            .background(Color.spotifyBackground.ignoresSafeArea())
            .navigationTitle("Last.fm")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.spotifyGreen)
                }
            }
        }
    }
}
