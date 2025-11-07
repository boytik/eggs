import Foundation
import UIKit

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
