import Foundation

struct TaskItem: Codable, Identifiable, Hashable {
    let id: UUID
    var title: String
    var createdAt: Date
    var isCompleted: Bool
    var completedAt: Date?

    init(
        id: UUID = UUID(),
        title: String,
        createdAt: Date = .now,
        isCompleted: Bool = false,
        completedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.isCompleted = isCompleted
        self.completedAt = completedAt
    }
}

struct TaskList: Codable, Identifiable, Hashable {
    let id: UUID
    var name: String
    var items: [TaskItem]
    var createdAt: Date

    init(id: UUID = UUID(), name: String, items: [TaskItem] = [], createdAt: Date = .now) {
        self.id = id
        self.name = name
        self.items = items
        self.createdAt = createdAt
    }
}

struct WorkerLog: Codable, Identifiable, Hashable {
    let id: UUID
    var date: Date
    var hours: Double
    var createdAt: Date
    var note: String

    init(
        id: UUID = UUID(),
        date: Date = .now,
        hours: Double,
        createdAt: Date = .now,
        note: String = ""
    ) {
        self.id = id
        self.date = date
        self.hours = hours
        self.createdAt = createdAt
        self.note = note
    }
}

struct Worker: Codable, Identifiable, Hashable {
    let id: UUID
    var name: String
    var logs: [WorkerLog]
    var createdAt: Date

    init(id: UUID = UUID(), name: String, logs: [WorkerLog] = [], createdAt: Date = .now) {
        self.id = id
        self.name = name
        self.logs = logs
        self.createdAt = createdAt
    }
}

struct AppState: Codable {
    var dashboardItems: [TaskItem]
    var customLists: [TaskList]
    var workers: [Worker]

    static let empty = AppState(dashboardItems: [], customLists: [], workers: [])
}

enum TaskLocation: Hashable {
    case dashboard
    case customList(UUID)
}

enum QuickHoursOption: String, CaseIterable, Identifiable {
    case fullDay
    case halfDay
    case custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .fullDay:
            "Dia completo"
        case .halfDay:
            "Medio dia"
        case .custom:
            "Horas"
        }
    }

    var hours: Double? {
        switch self {
        case .fullDay:
            8
        case .halfDay:
            4
        case .custom:
            nil
        }
    }
}
