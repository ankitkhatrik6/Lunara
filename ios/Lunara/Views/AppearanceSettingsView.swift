import SwiftUI

public struct AppearanceSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var darkMode: Bool = false
    @State private var pureBlack: Bool = true

    public init() {}

    public var body: some View {
        NavigationStack {
            List {
                Section(header: Text("THEME").foregroundColor(.spotifyTextMuted)) {
                    Toggle("Dark Mode", isOn: $darkMode)
                        .tint(.spotifyGreen)
                        .foregroundColor(.spotifyTextPrimary)

                    Toggle("Pure Black", isOn: $pureBlack)
                        .tint(.spotifyGreen)
                        .foregroundColor(.spotifyTextPrimary)
                }
                .listRowBackground(Color.spotifyCardSurface)
            }
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