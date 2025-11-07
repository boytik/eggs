import Foundation
import UIKit
import UserNotifications
import SystemConfiguration

/// Сервис для сбора и управления логами приложения
final class LogCollector {
    static let shared = LogCollector()
    
    private var logs: [LogEntry] = []
    private let maxLogs = 1000 // Максимальное количество логов в памяти
    private let queue = DispatchQueue(label: "LogCollector", qos: .utility)
    
    private init() {}
    
    struct LogEntry {
        let timestamp: Date
        let message: String
        let category: String
        
        var formattedString: String {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm:ss.SSS"
            return "[\(formatter.string(from: timestamp))] [\(category)] \(message)"
        }
    }
    
    /// Добавить лог
    func log(_ message: String, category: String = "App") {
        queue.async {
            let entry = LogEntry(timestamp: Date(), message: message, category: category)
            self.logs.append(entry)
            
            // Ограничиваем количество логов
            if self.logs.count > self.maxLogs {
                self.logs.removeFirst(self.logs.count - self.maxLogs)
            }
            
            // Также выводим в консоль
            print("📋 [\(category)] \(message)")
        }
    }
    
    /// Получить все логи как строку
    func getAllLogs() -> String {
        return queue.sync {
            return logs.map { $0.formattedString }.joined(separator: "\n")
        }
    }
    
    /// Получить логи за последние N минут
    func getRecentLogs(minutes: Int = 10) -> String {
        return queue.sync {
            let cutoffTime = Date().addingTimeInterval(-TimeInterval(minutes * 60))
            let recentLogs = logs.filter { $0.timestamp >= cutoffTime }
            return recentLogs.map { $0.formattedString }.joined(separator: "\n")
        }
    }
    
    /// Скопировать все логи в буфер обмена
    func copyAllLogsToClipboard() {
        let allLogs = getAllLogs()
        DispatchQueue.main.async {
            UIPasteboard.general.string = allLogs
            print("📋 [LogCollector] Скопировано \(self.logs.count) логов в буфер обмена")
        }
    }
    
    /// Скопировать недавние логи в буфер обмена
    func copyRecentLogsToClipboard(minutes: Int = 10) {
        let recentLogs = getRecentLogs(minutes: minutes)
        DispatchQueue.main.async {
            UIPasteboard.general.string = recentLogs
            print("📋 [LogCollector] Скопированы логи за последние \(minutes) минут в буфер обмена")
        }
    }
    
    /// Очистить все логи
    func clearLogs() {
        queue.async {
            self.logs.removeAll()
            print("📋 [LogCollector] Все логи очищены")
        }
    }
    
    /// Получить статистику логов
    func getLogStats() -> String {
        return queue.sync {
            let totalLogs = logs.count
            let categories = Set(logs.map { $0.category })
            let oldestLog = logs.first?.timestamp
            let newestLog = logs.last?.timestamp
            
            var stats = "📊 Статистика логов:\n"
            stats += "Всего логов: \(totalLogs)\n"
            stats += "Категории: \(categories.sorted().joined(separator: ", "))\n"
            
            if let oldest = oldestLog, let newest = newestLog {
                let formatter = DateFormatter()
                formatter.dateFormat = "HH:mm:ss"
                stats += "Период: \(formatter.string(from: oldest)) - \(formatter.string(from: newest))\n"
            }
            
            return stats
        }
    }
    
    /// Получить полную диагностику Push уведомлений
    func getPushDiagnostics() async -> String {
        var diagnostics = "🔔 === ПОЛНАЯ ДИАГНОСТИКА PUSH УВЕДОМЛЕНИЙ ===\n\n"
        
        // 1. Системная информация
        diagnostics += "📱 СИСТЕМНАЯ ИНФОРМАЦИЯ:\n"
        diagnostics += "iOS версия: \(UIDevice.current.systemVersion)\n"
        diagnostics += "Модель устройства: \(UIDevice.current.model)\n"
        diagnostics += "Время диагностики: \(DateFormatter.fullDateTime.string(from: Date()))\n\n"
        
        // 2. Статус разрешений
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        diagnostics += "🔐 СТАТУС РАЗРЕШЕНИЙ:\n"
        diagnostics += "Authorization Status: \(settings.authorizationStatus.rawValue) (\(authorizationStatusDescription(settings.authorizationStatus)))\n"
        diagnostics += "Alert Setting: \(settings.alertSetting.rawValue) (\(notificationSettingDescription(settings.alertSetting)))\n"
        diagnostics += "Badge Setting: \(settings.badgeSetting.rawValue) (\(notificationSettingDescription(settings.badgeSetting)))\n"
        diagnostics += "Sound Setting: \(settings.soundSetting.rawValue) (\(notificationSettingDescription(settings.soundSetting)))\n"
        diagnostics += "Notification Center: \(settings.notificationCenterSetting.rawValue) (\(notificationSettingDescription(settings.notificationCenterSetting)))\n"
        diagnostics += "Lock Screen: \(settings.lockScreenSetting.rawValue) (\(notificationSettingDescription(settings.lockScreenSetting)))\n"
        diagnostics += "Critical Alert: \(settings.criticalAlertSetting.rawValue) (\(notificationSettingDescription(settings.criticalAlertSetting)))\n\n"
        
        // 3. Токены
        diagnostics += "🔑 ТОКЕНЫ:\n"
        if let fcmToken = await PushPermissionService.shared.getCurrentFCMToken(timeout: 5.0) {
            diagnostics += "FCM Token: \(fcmToken.prefix(30))... (длина: \(fcmToken.count))\n"
            diagnostics += "FCM Token полный: \(fcmToken)\n"
        } else {
            diagnostics += "FCM Token: ❌ НЕ ПОЛУЧЕН\n"
        }
        
        let apnsToken = await getAPNSTokenString()
        if let apnsToken = apnsToken {
            diagnostics += "APNs Token: \(apnsToken)\n"
        } else {
            diagnostics += "APNs Token: ❌ НЕ ПОЛУЧЕН\n"
        }
        diagnostics += "\n"
        
        // 4. Firebase конфигурация
        diagnostics += "🔥 FIREBASE КОНФИГУРАЦИЯ:\n"
        if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
           let plist = NSDictionary(contentsOfFile: path) {
            diagnostics += "PROJECT_ID: \(plist["PROJECT_ID"] ?? "не найден")\n"
            diagnostics += "BUNDLE_ID: \(plist["BUNDLE_ID"] ?? "не найден")\n"
            diagnostics += "GCM_SENDER_ID: \(plist["GCM_SENDER_ID"] ?? "не найден")\n"
            diagnostics += "IS_GCM_ENABLED: \(plist["IS_GCM_ENABLED"] ?? "не найден")\n"
        } else {
            diagnostics += "❌ GoogleService-Info.plist не найден\n"
        }
        diagnostics += "\n"
        
        // 5. Entitlements
        diagnostics += "📋 ENTITLEMENTS:\n"
        if let entitlements = Bundle.main.entitlements {
            diagnostics += "aps-environment: \(entitlements["aps-environment"] ?? "не найден")\n"
            if let domains = entitlements["com.apple.developer.associated-domains"] as? [String] {
                diagnostics += "Associated domains: \(domains.joined(separator: ", "))\n"
            }
        }
        diagnostics += "\n"
        
        // 6. Логи Push уведомлений
        diagnostics += "📋 ЛОГИ PUSH УВЕДОМЛЕНИЙ (последние 50):\n"
        let pushLogs = queue.sync {
            return logs.filter { $0.category == "Push" || $0.category == "ERROR" }
                      .suffix(50)
                      .map { $0.formattedString }
                      .joined(separator: "\n")
        }
        diagnostics += pushLogs.isEmpty ? "Нет логов Push уведомлений" : pushLogs
        diagnostics += "\n\n"
        
        // 7. Настройки приложения
        diagnostics += "⚙️ НАСТРОЙКИ ПРИЛОЖЕНИЯ:\n"
        diagnostics += "Push permission asked: \(UserDefaults.standard.bool(forKey: "push_permission_asked"))\n"
        if let nextAskDate = UserDefaults.standard.object(forKey: "push_next_ask_date") as? Date {
            diagnostics += "Next ask date: \(DateFormatter.fullDateTime.string(from: nextAskDate))\n"
        } else {
            diagnostics += "Next ask date: не установлена\n"
        }
        diagnostics += "Background refresh: \(UIApplication.shared.backgroundRefreshStatus.rawValue) (\(backgroundRefreshDescription(UIApplication.shared.backgroundRefreshStatus)))\n"
        diagnostics += "\n"
        
        // 8. Сетевое соединение
        diagnostics += "🌐 СЕТЕВОЕ СОЕДИНЕНИЕ:\n"
        diagnostics += "Reachability: \(getNetworkStatus())\n"
        diagnostics += "\n"
        
        // 9. Информация о приложении
        diagnostics += "📱 ИНФОРМАЦИЯ О ПРИЛОЖЕНИИ:\n"
        diagnostics += "Bundle ID: \(Bundle.main.bundleIdentifier ?? "не найден")\n"
        diagnostics += "Version: \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "не найден")\n"
        diagnostics += "Build: \(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "не найден")\n"
        diagnostics += "App State: \(UIApplication.shared.applicationState.rawValue) (\(applicationStateDescription(UIApplication.shared.applicationState)))\n"
        diagnostics += "\n"
        
        // 10. Последние события Push
        diagnostics += "🕐 ПОСЛЕДНИЕ СОБЫТИЯ PUSH:\n"
        let recentPushEvents = queue.sync {
            return logs.filter { $0.category == "Push" }
                      .suffix(10)
                      .map { "[\(DateFormatter.fullDateTime.string(from: $0.timestamp))] \($0.message)" }
                      .joined(separator: "\n")
        }
        diagnostics += recentPushEvents.isEmpty ? "Нет недавних событий Push" : recentPushEvents
        diagnostics += "\n\n"
        
        diagnostics += "=== КОНЕЦ ДИАГНОСТИКИ ===\n"
        
        return diagnostics
    }
    
    private func getAPNSTokenString() async -> String? {
        return await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                let apnsToken = PushPermissionService.shared.getAPNSTokenForDiagnostics()
                continuation.resume(returning: apnsToken)
            }
        }
    }
    
    private func authorizationStatusDescription(_ status: UNAuthorizationStatus) -> String {
        switch status {
        case .notDetermined: return "Not Determined"
        case .denied: return "Denied"
        case .authorized: return "Authorized"
        case .provisional: return "Provisional"
        case .ephemeral: return "Ephemeral"
        @unknown default: return "Unknown"
        }
    }
    
    private func notificationSettingDescription(_ setting: UNNotificationSetting) -> String {
        switch setting {
        case .notSupported: return "Not Supported"
        case .disabled: return "Disabled"
        case .enabled: return "Enabled"
        @unknown default: return "Unknown"
        }
    }
    
    private func backgroundRefreshDescription(_ status: UIBackgroundRefreshStatus) -> String {
        switch status {
        case .available: return "Available"
        case .denied: return "Denied"
        case .restricted: return "Restricted"
        @unknown default: return "Unknown"
        }
    }
    
    private func applicationStateDescription(_ state: UIApplication.State) -> String {
        switch state {
        case .active: return "Active"
        case .inactive: return "Inactive"
        case .background: return "Background"
        @unknown default: return "Unknown"
        }
    }
    
    private func getNetworkStatus() -> String {
        // Простая проверка сетевого соединения
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        guard let defaultRouteReachability = withUnsafePointer(to: &zeroAddress, {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                SCNetworkReachabilityCreateWithAddress(nil, $0)
            }
        }) else {
            return "Неизвестно"
        }
        
        var flags: SCNetworkReachabilityFlags = []
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) {
            return "Неизвестно"
        }
        
        let isReachable = flags.contains(.reachable)
        let needsConnection = flags.contains(.connectionRequired)
        let isNetworkReachable = isReachable && !needsConnection
        
        if isNetworkReachable {
            if flags.contains(.isWWAN) {
                return "Мобильная сеть"
            } else {
                return "Wi-Fi"
            }
        } else {
            return "Нет соединения"
        }
    }
}

// MARK: - Удобные методы для логирования

extension LogCollector {
    func logAppsFlyer(_ message: String) {
        log(message, category: "AF")
    }
    
    func logWebView(_ message: String) {
        log(message, category: "WebView")
    }
    
    func logConfig(_ message: String) {
        log(message, category: "Config")
    }
    
    func logPush(_ message: String) {
        log(message, category: "Push")
    }
    
    func logFirebase(_ message: String) {
        log(message, category: "Firebase")
    }
    
    func logNavigation(_ message: String) {
        log(message, category: "Navigation")
    }
    
    func logKeyboard(_ message: String) {
        log(message, category: "Keyboard")
    }
    
    func logError(_ message: String) {
        log(message, category: "ERROR")
    }
}

// MARK: - Extensions

extension Bundle {
    var entitlements: [String: Any]? {
        guard let path = self.path(forResource: "Eggonomics Road", ofType: "entitlements"),
              let plist = NSDictionary(contentsOfFile: path) as? [String: Any] else {
            return nil
        }
        return plist
    }
}

extension DateFormatter {
    static let fullDateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter
    }()
}

