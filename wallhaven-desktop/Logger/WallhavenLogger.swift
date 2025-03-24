import Combine
import os
import SwiftUI

class WallhavenLogger: ObservableObject {
    static let shared = WallhavenLogger()
    private let logger = Logger()
    private var cancellables = Set<AnyCancellable>()
    
    @Published var activeToasts: [ToastMessage] = []
    @Published var logEntries: [String] = []
    
    private init() {}
    
    // MARK: - Logging Methods

    func log(_ message: String, level: LogLevel, showToast: Bool = false, duration: Double = 3.0) {
        if showToast {
            showToastMessage(message, level: level, duration: duration)
        }
    }
    
    func info(_ message: String, showToast: Bool = false) {
        logger.info("\(message)")
        log(message, level: .info, showToast: showToast)
    }
    
    func success(_ message: String, showToast: Bool = true) {
        logger.notice("\(message)")
        log(message, level: .success, showToast: showToast)
    }
    
    func warning(_ message: String, showToast: Bool = true) {
        logger.warning("\(message)")
        log(message, level: .warning, showToast: showToast)
    }
    
    func error(_ message: String, showToast: Bool = true) {
        logger.error("\(message)")
        log(message, level: .error, showToast: showToast)
    }
    
    // MARK: - Toast Management

    func showToastMessage(_ message: String, level: LogLevel, duration: Double) {
        let toast = ToastMessage(message: message, level: level, duration: duration)
        
        // Add the toast to the active toasts
        DispatchQueue.main.async {
            withAnimation(.easeInOut) {
                self.activeToasts.append(toast)
            }
            
            // Remove toast after duration
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                withAnimation(.easeInOut) {
                    self.activeToasts.removeAll(where: { $0.id == toast.id })
                }
            }
        }
    }
    
    // MARK: - Helper Methods

    private func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter.string(from: Date())
    }
}
