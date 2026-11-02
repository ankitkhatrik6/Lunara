import SwiftUI

public struct BlockedArtistsView: View {
    @State private var blocked: [BlockedArtist] = []
    @State private var newArtistName: String = ""

    public init() {}

    public var body: some View {
        NavigationStack {
            Group {
                if blocked.isEmpty {
                    ContentUnavailableView(
                        "No Blocked Artists",
                        systemImage: "person.slash",
                        description: Text("Blocked artists won't appear in recommendations.")
                    )
                } else {
                    List {
                        ForEach(blocked) { artist in
                            HStack {
                                Text(artist.name)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.spotifyTextPrimary)

                                Spacer()

                                Button {
                                    StorageService.shared.unblockArtist(id: artist.id)
                                    blocked.removeAll { $0.id == artist.id }
                                } label: {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("Blocked Artists")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        // Add blocked artist
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .onAppear {
                blocked = StorageService.shared.getBlockedArtists()
            }
        }
    }
}