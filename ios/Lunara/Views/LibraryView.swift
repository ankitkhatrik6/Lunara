import SwiftUI

public struct LibraryView: View {
    public let libraryVM: LibraryViewModel
    public let playerVM: PlayerViewModel
    @State private var isCreatePlaylistPresented: Bool = false

    public init(libraryVM: LibraryViewModel, playerVM: PlayerViewModel) {
        self.libraryVM = libraryVM
        self.playerVM = playerVM
    }

    public var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack(spacing: 12) {
                Text("Your Library")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.spotifyTextPrimary)

                Spacer()

                Button {
                    libraryVM.isCreatePlaylistPresented = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.spotifyTextPrimary)
                        .frame(width: 44, height: 44)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)

            // Filter Pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(LibraryFilter.allCases, id: \.self) { filter in
                        Button {
                            libraryVM.selectedFilter = filter
                        } label: {
                            Text(filter.rawValue)
                                .font(.system(size: 13, weight: .semibold))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 7)
                                .background(libraryVM.selectedFilter == filter ? Color.spotifyGreen : Color.spotifyCardSurface)
                                .foregroundColor(libraryVM.selectedFilter == filter ? .black : .spotifyTextPrimary)
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding(.horizontal, 16)
            }

            // Library List
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 12) {
                    // Liked Songs row
                    Button {
                        if let first = libraryVM.likedTracks.first {
                            playerVM.play(track: first, queue: libraryVM.likedTracks)
                        }
                    } label: {
                        HStack(spacing: 14) {
                            ZStack {
                                LinearGradient(
                                    colors: [Color(red: 69/255, green: 56/255, blue: 184/255), Color(red: 142/255, green: 172/255, blue: 153/255)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                Image(systemName: "heart.fill")
                                    .foregroundColor(.white)
                                    .font(.system(size: 24))
                            }
                            .frame(width: 64, height: 64)
                            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Liked Songs")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.spotifyTextPrimary)

                                Text("\(libraryVM.likedTracks.count) songs")
                                    .font(.system(size: 13))
                                    .foregroundColor(.spotifyTextMuted)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                    }
                    .buttonStyle(.plain)

                    // Playlists
                    ForEach(libraryVM.playlists) { playlist in
                        Button {
                            if let first = playlist.tracks.first {
                                playerVM.play(track: first, queue: playlist.tracks)
                            }
                        } label: {
                            HStack(spacing: 14) {
                                ZStack {
                                    if let artworkUrl = playlist.artworkUrl,
                                       let url = URL(string: artworkUrl) {
                                        AsyncImage(url: url) { phase in
                                            if let image = phase.image {
                                                image
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                            } else {
                                                Rectangle()
                                                    .fill(Color.spotifyCardSurface)
                                                    .overlay(
                                                        Image(systemName: "music.note.list")
                                                            .foregroundColor(.spotifyTextMuted)
                                                    )
                                            }
                                        }
                                    } else {
                                        Rectangle()
                                            .fill(Color.spotifyCardSurface)
                                            .overlay(
                                                Image(systemName: "music.note.list")
                                                    .foregroundColor(.spotifyTextMuted)
                                            )
                                    }
                                }
                                .frame(width: 64, height: 64)
                                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(playlist.title)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.spotifyTextPrimary)

                                    Text("Playlist • \(playlist.authorName)")
                                        .font(.system(size: 13))
                                        .foregroundColor(.spotifyTextMuted)
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                        }
                        .buttonStyle(.plain)
                    }

                    Spacer(minLength: 80)
                }
                .padding(.top, 8)
            }
        }
        .background(Color.spotifyBackground.ignoresSafeArea())
        .sheet(isPresented: $isCreatePlaylistPresented) {
            CreatePlaylistSheet(libraryVM: libraryVM)
        }
        .onChange(of: libraryVM.isCreatePlaylistPresented) { _, isPresented in
            isCreatePlaylistPresented = isPresented
        }
        .onChange(of: isCreatePlaylistPresented) { _, isPresented in
            if !isPresented {
                libraryVM.isCreatePlaylistPresented = false
            }
        }
    }
}

public struct CreatePlaylistSheet: View {
    public let libraryVM: LibraryViewModel
    @State private var newPlaylistTitle: String = ""
    @Environment(\.dismiss) private var dismiss

    public var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Give your playlist a name")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.spotifyTextPrimary)
                    .padding(.top, 32)

                TextField("My Playlist", text: $newPlaylistTitle)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.spotifyTextPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .onAppear {
                        newPlaylistTitle = libraryVM.newPlaylistTitle
                    }
                    .onChange(of: newPlaylistTitle) { _, newValue in
                        libraryVM.newPlaylistTitle = newValue
                    }

                Divider()
                    .background(Color.spotifyDivider)
                    .padding(.horizontal, 32)

                Button {
                    libraryVM.createPlaylist()
                    dismiss()
                } label: {
                    Text("Create")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .background(Color.spotifyGreen)
                        .clipShape(Capsule())
                }
                .padding(.top, 16)

                Spacer()
            }
            .background(Color.spotifyElevatedSurface.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.spotifyTextPrimary)
                }
            }
        }
        .presentationDetents([.medium])
    }
}
