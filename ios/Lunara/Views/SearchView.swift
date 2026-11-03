import SwiftUI

public struct SearchBarView: View {
    @Binding public var text: String
    public let onClear: () -> Void

    public init(text: Binding<String>, onClear: @escaping () -> Void) {
        self._text = text
        self.onClear = onClear
    }

    public var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.black)
                .font(.system(size: 16, weight: .semibold))

            TextField("Search song, title, artist…", text: $text)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.spotifyTextPrimary)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)

            if !text.isEmpty {
                Button(action: onClear) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .font(.system(size: 16))
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 11)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }
}

public struct SearchResultRow: View {
    public let track: Track
    public let onSelect: () -> Void

    public init(track: Track, onSelect: @escaping () -> Void) {
        self.track = track
        self.onSelect = onSelect
    }

    public var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                AsyncImage(url: URL(string: track.artworkUrl ?? "")) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        Rectangle()
                            .fill(Color.spotifyCardSurface)
                            .overlay(
                                Image(systemName: "music.note")
                                    .foregroundColor(.spotifyTextMuted)
                            )
                    }
                }
                .frame(width: 48, height: 48)
                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(track.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.spotifyTextPrimary)
                        .lineLimit(1)

                    Text("Song • \(track.artistName)")
                        .font(.system(size: 13))
                        .foregroundColor(.spotifyTextMuted)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "ellipsis")
                    .foregroundColor(.spotifyTextMuted)
                    .font(.system(size: 16))
                    .frame(width: 44, height: 44)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

public struct SearchView: View {
    public let searchVM: SearchViewModel
    public let playerVM: PlayerViewModel

    private let genreColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    public init(searchVM: SearchViewModel, playerVM: PlayerViewModel) {
        self.searchVM = searchVM
        self.playerVM = playerVM
    }

    public var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("Search")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.spotifyTextPrimary)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)

            // Search Input
            SearchBarView(text: Binding(
                get: { searchVM.query },
                set: { searchVM.query = $0 }
            )) {
                searchVM.clearQuery()
            }
            .padding(.horizontal, 16)

            // Body Content
            if searchVM.query.isEmpty {
                // Browse Genre Grid
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Browse all")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.spotifyTextPrimary)
                            .padding(.horizontal, 16)

                        LazyVGrid(columns: genreColumns, spacing: 12) {
                            ForEach(searchVM.browseCategories) { cat in
                                Button {
                                    searchVM.query = cat.title
                                } label: {
                                    ZStack(alignment: .topLeading) {
                                        cat.color
                                            .frame(height: 100)
                                            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

                                        Text(cat.title)
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(.white)
                                            .padding(12)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)

                        Spacer(minLength: 80)
                    }
                }
            } else if searchVM.isSearching {
                Spacer()
                ProgressView()
                    .tint(.spotifyGreen)
                    .scaleEffect(1.2)
                Spacer()
            } else {
                // Live Search Results
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 8) {
                        ForEach(searchVM.searchResults) { track in
                            SearchResultRow(track: track) {
                                playerVM.play(track: track, queue: searchVM.searchResults)
                            }
                        }
                    }
                    .padding(.top, 8)
                    Spacer(minLength: 80)
                }
            }
        }
        .background(Color.spotifyBackground.ignoresSafeArea())
    }
}
