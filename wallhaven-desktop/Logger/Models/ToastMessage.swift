import SwiftUI

struct ToastMessage: Identifiable, Equatable {
    let id = UUID()
    let message: String
    let level: LogLevel
    let timestamp = Date()
    let duration: Double

    static func == (lhs: ToastMessage, rhs: ToastMessage) -> Bool {
        lhs.id == rhs.id
    }
}
