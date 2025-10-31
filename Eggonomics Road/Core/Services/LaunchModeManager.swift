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
    private let noMoreConfigRequestsKey = "noMoreConfigRequests"

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

    var shouldSkipConfigRequests: Bool {
        get { ud.bool(forKey: noMoreConfigRequestsKey) }
        set { ud.set(newValue, forKey: noMoreConfigRequestsKey) }
    }
    
    func markNoMoreConfigRequests() {
        shouldSkipConfigRequests = true
        print("🚫 [Mode] Marked to skip config requests permanently")
    }
    
    func resetConfigRequestsFlag() {
        shouldSkipConfigRequests = false
        print("🔄 [Mode] Reset config requests flag - will try again")
    }

    func resetMode() {
        ud.removeObject(forKey: modeKey)
        ud.removeObject(forKey: urlKey)
        ud.removeObject(forKey: expiresKey)
        ud.removeObject(forKey: noMoreConfigRequestsKey)
        print("🧹 [Mode] Reset")
    }
}
