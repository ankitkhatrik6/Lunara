import Foundation
import CryptoKit
import Combine

/// YouTube account session with cookie-based auth (SAPISIDHASH).
final class Auth: ObservableObject {
    static let shared = Auth()

    @Published private(set) var isLoggedIn = false
    @Published private(set) var accountName: String?
    @Published private(set) var accountEmail: String?
    @Published private(set) var accountPhoto: String?

    private(set) var cookie: String?
    private(set) var visitorData: String?
    private(set) var dataSyncId: String?

    private let defaults = UserDefaults.standard

    private init() {
        cookie = Keychain.get(Keys.cookie)
        visitorData = defaults.string(forKey: Keys.visitor)
        dataSyncId = defaults.string(forKey: Keys.dataSync)
        accountName = defaults.string(forKey: Keys.name)
        accountEmail = defaults.string(forKey: Keys.email)
        accountPhoto = defaults.string(forKey: Keys.photo)
        isLoggedIn = !(cookie ?? "").isEmpty
    }

    private enum Keys {
        static let cookie = "yt_cookie"
        static let visitor = "yt_visitorData"
        static let dataSync = "yt_dataSyncId"
        static let name = "yt_accountName"
        static let email = "yt_accountEmail"
        static let photo = "yt_accountPhoto"
    }

    private var cookieMap: [String: String] {
        guard let cookie else { return [:] }
        var map: [String: String] = [:]
        for pair in cookie.split(separator: ";") {
            let kv = pair.split(separator: "=", maxSplits: 1)
            guard kv.count == 2 else { continue }
            map[kv[0].trimmingCharacters(in: .whitespaces)] = kv[1].trimmingCharacters(in: .whitespaces)
        }
        return map
    }

    private var sapisid: String? {
        let map = cookieMap
        return map["SAPISID"] ?? map["__Secure-3PAPISID"] ?? map["__Secure-1PAPISID"]
    }

    func headers() -> [String: String] {
        guard let cookie, let sapisid else { return [:] }
        let ts = Int(Date().timeIntervalSince1970)
        let digest = Insecure.SHA1.hash(data: Data("\(ts) \(sapisid) https://music.youtube.com".utf8))
        let hash = digest.map { String(format: "%02x", $0) }.joined()
        return [
            "Cookie": cookie,
            "Authorization": "SAPISIDHASH \(ts)_\(hash)",
            "X-Origin": "https://music.youtube.com",
            "X-Goog-AuthUser": "0",
        ]
    }

    func refreshAccountNameIfMissing() {
        guard isLoggedIn, (accountName ?? "").isEmpty || (accountPhoto ?? "").isEmpty else { return }
        Task { @MainActor in
            guard let info = await YouTubeMusicService.shared.accountInfo() else { return }
            self.accountName = info.name
            self.accountEmail = info.email
            self.accountPhoto = info.photo
            self.defaults.set(info.name, forKey: Keys.name)
            self.defaults.set(info.email, forKey: Keys.email)
            self.defaults.set(info.photo, forKey: Keys.photo)
        }
    }

    func signIn(cookie: String, visitorData: String?, dataSyncId: String?) async -> Bool {
        self.cookie = cookie
        if let visitorData, !visitorData.isEmpty { self.visitorData = visitorData }
        self.dataSyncId = dataSyncId

        guard let info = await YouTubeMusicService.shared.accountInfo() else {
            self.cookie = nil
            return false
        }

        await MainActor.run {
            self.accountName = info.name
            self.accountEmail = info.email
            self.accountPhoto = info.photo
            self.isLoggedIn = true
        }
        Keychain.set(cookie, for: Keys.cookie)
        defaults.set(self.visitorData, forKey: Keys.visitor)
        defaults.set(dataSyncId, forKey: Keys.dataSync)
        defaults.set(info.name, forKey: Keys.name)
        defaults.set(info.email, forKey: Keys.email)
        defaults.set(info.photo, forKey: Keys.photo)
        return true
    }

    func tokenBlob() -> String {
        """
        ***INNERTUBE COOKIE*** =\(cookie ?? "")
        ***VISITOR DATA*** =\(visitorData ?? "")
        ***DATASYNC ID*** =\(dataSyncId ?? "")
        ***ACCOUNT NAME*** =\(accountName ?? "")
        ***ACCOUNT EMAIL*** =\(accountEmail ?? "")
        """
    }

    func signOut() {
        cookie = nil
        dataSyncId = nil
        Keychain.set(nil, for: Keys.cookie)
        for key in [Keys.dataSync, Keys.name, Keys.email, Keys.photo] {
            defaults.removeObject(forKey: key)
        }
        Task { @MainActor in
            self.accountName = nil
            self.accountEmail = nil
            self.accountPhoto = nil
            self.isLoggedIn = false
        }
    }
}