import Foundation

@MainActor
final class LaunchModeManager {
    enum Mode: String { case undefined, webview, fan }

    static let shared = LaunchModeManager()
    private init() {}

    private let ud = UserDefaults.standard
    private let urlKey = "savedWebURL"
    private let modeKey = "launchMode"
    private let expiresKey = "webURLExpires"

    var currentMode: Mode {
        get { Mode(rawValue: ud.string(forKey: modeKey) ?? "") ?? .undefined }
        set { ud.set(newValue.rawValue, forKey: modeKey) }
    }

    var cachedURL: URL? {
        guard let s = ud.string(forKey: urlKey) else { return nil }
        return URL(string: s)
    }

    func cache(url: String?, expires: TimeInterval?) {
        if let url { ud.set(url, forKey: urlKey); print("💾 [Mode] Cached URL") }
        if let expires { ud.set(expires, forKey: expiresKey); print("⏳ [Mode] Cached expires: \(expires)") }
    }

    func isExpired(now: Date = .init()) -> Bool {
        let exp = ud.double(forKey: expiresKey)
        guard exp > 0 else { return false } // treat as non-expiring if missing
        return now.timeIntervalSince1970 >= exp
    }

    func resetMode() {
        ud.removeObject(forKey: modeKey)
        ud.removeObject(forKey: urlKey)
        ud.removeObject(forKey: expiresKey)
        print("🧹 [Mode] Reset")
    }
}
