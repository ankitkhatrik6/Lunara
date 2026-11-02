import SwiftUI

public struct LoginView: View {
    @State private var cookieInput: String = ""
    @State private var visitorData: String = ""
    @State private var dataSyncId: String = ""
    @State private var isSigningIn: Bool = false
    @State private var signInError: String? = nil

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 12) {
                        Image(systemName: "waveform.circle.fill")
                            .font(.system(size: 60, weight: .bold))
                            .foregroundColor(.spotifyGreen)

                        Text("Sign in to YouTube Music")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.spotifyTextPrimary)

                        Text("Enter your YouTube Music session cookie")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(.spotifyTextMuted)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .padding(.top, 40)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Innertube Cookie")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.spotifyTextPrimary)

                        TextEditor(text: $cookieInput)
                            .font(.system(size: 11, weight: .regular, design: .monospaced))
                            .foregroundColor(.spotifyTextPrimary)
                            .frame(minHeight: 100)
                            .padding(10)
                            .background(Color.spotifyCardSurface)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                        Text("Get it from music.youtube.com → DevTools → Cookies")
                            .font(.system(size: 10, weight: .regular))
                            .foregroundColor(.spotifyTextMuted)
                    }
                    .padding(.horizontal, 24)

                    if let error = signInError {
                        HStack {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(.red)
                            Text(error)
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(.red)
                            Spacer()
                        }
                        .padding(12)
                        .background(Color.red.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .padding(.horizontal, 24)
                    }

                    Button {
                        Task {
                            await signIn()
                        }
                    } label: {
                        HStack {
                            if isSigningIn {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .tint(.black)
                            }
                            Text(isSigningIn ? "Signing in…" : "Sign In")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.black)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.spotifyGreen)
                        .clipShape(Capsule())
                    }
                    .disabled(isSigningIn || cookieInput.isEmpty)
                    .padding(.horizontal, 24)
                    .padding(.top, 8)

                    Spacer(minLength: 40)
                }
            }
            .background(Color.spotifyBackground.ignoresSafeArea())
            .navigationTitle("Sign In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { }
                        .foregroundColor(.spotifyTextPrimary)
                }
            }
        }
    }

    private func signIn() async {
        isSigningIn = true
        signInError = nil

        let visitor = visitorData.isEmpty ? nil : visitorData
        let sync = dataSyncId.isEmpty ? nil : dataSyncId

        let success = await Auth.shared.signIn(
            cookie: cookieInput,
            visitorData: visitor,
            dataSyncId: sync
        )

        await MainActor.run {
            isSigningIn = false
            if !success {
                signInError = "Invalid or expired cookie."
            }
        }
    }
}