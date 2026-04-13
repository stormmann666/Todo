import Foundation

enum AppRepository {
    static let storageKey = "todo.app.state"

    static func load(defaults: UserDefaults = .standard) -> AppState {
        guard let data = defaults.data(forKey: storageKey) else {
            return .empty
        }

        do {
            return try JSONDecoder().decode(AppState.self, from: data)
        } catch {
            return .empty
        }
    }

    static func save(_ state: AppState, defaults: UserDefaults = .standard) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]

        guard let data = try? encoder.encode(state) else {
            return
        }

        defaults.set(data, forKey: storageKey)
    }

    static func addDashboardItem(title: String, defaults: UserDefaults = .standard) {
        let cleaned = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard cleaned.isEmpty == false else { return }

        var state = load(defaults: defaults)
        state.dashboardItems.insert(TaskItem(title: cleaned), at: 0)
        save(state, defaults: defaults)
    }
}
