import SwiftUI

public struct EqualizerView: View {
    @State private var bands: [Float] = Array(repeating: 0.0, count: 10)
    @State private var isEnabled: Bool = StorageService.shared.isHighQualityAudioEnabled()

    private let frequencies = ["32", "64", "125", "250", "500", "1k", "2k", "4k", "8k", "16k"]

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Equalizer")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.spotifyTextPrimary)

                        Toggle("Enable Equalizer", isOn: $isEnabled)
                            .tint(.spotifyGreen)
                            .foregroundColor(.spotifyTextPrimary)
                    }
                    .padding(.horizontal, 16)

                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 20) {
                        ForEach(0..<10, id: \.self) { index in
                            EqualizerBand(
                                frequency: frequencies[index],
                                value: $bands[index]
                            )
                        }
                    }
                    .padding(.horizontal, 16)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Presets")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.spotifyTextPrimary)

                        HStack(spacing: 12) {
                            ForEach(["Flat", "Bass Boost", "Vocal", "Treble"], id: \.self) { preset in
                                Button(preset) {
                                    // Apply preset
                                }
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.spotifyTextPrimary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.spotifyCardSurface)
                                .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.horizontal, 16)

                    Spacer(minLength: 40)
                }
            }
            .background(Color.spotifyBackground.ignoresSafeArea())
            .navigationTitle("Equalizer")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

public struct EqualizerBand: View {
    let frequency: String
    @Binding var value: Float

    public init(frequency: String, value: Binding<Float>) {
        self.frequency = frequency
        self._value = value
    }

    public var body: some View {
        VStack(spacing: 8) {
            Text(frequency)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.spotifyTextMuted)

            GeometryReader { geo in
                ZStack(alignment: .bottom) {
                    Rectangle()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 20, height: 120)

                    Rectangle()
                        .fill(Color.spotifyGreen)
                        .frame(width: 20, height: CGFloat(abs(value)) * 12)
                        .offset(y: value < 0 ? 0 : -CGFloat(value) * 12)
                }
            }
            .frame(height: 120)

            Text(value > 0 ? "+\(Int(value))" : "\(Int(value))")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.spotifyTextPrimary)
        }
    }
}