import Foundation
import Combine

final class AppStore: ObservableObject {
    @Published var dashboardItems: [TaskItem]
    @Published var customLists: [TaskList]
    @Published var workers: [Worker]

    init(state: AppState = AppRepository.load()) {
        self.dashboardItems = state.dashboardItems
        self.customLists = state.customLists
        self.workers = state.workers
    }

    var state: AppState {
        AppState(
            dashboardItems: dashboardItems,
            customLists: customLists,
            workers: workers
        )
    }

    func save() {
        AppRepository.save(state)
    }

    func addDashboardItem(title: String) {
        let cleaned = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard cleaned.isEmpty == false else { return }

        dashboardItems.insert(TaskItem(title: cleaned), at: 0)
        save()
    }

    func addList(name: String) {
        let cleaned = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard cleaned.isEmpty == false else { return }

        customLists.append(TaskList(name: cleaned))
        customLists.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        save()
    }

    func deleteList(_ listID: UUID) {
        customLists.removeAll { $0.id == listID }
        save()
    }

    func markTaskCompleted(_ itemID: UUID, from location: TaskLocation) {
        updateTask(itemID, in: location) { item in
            item.isCompleted = true
            item.completedAt = .now
        }
    }

    func markTaskPending(_ itemID: UUID, from location: TaskLocation) {
        updateTask(itemID, in: location) { item in
            item.isCompleted = false
            item.completedAt = nil
        }
    }

    func deleteTask(_ itemID: UUID, from location: TaskLocation) {
        switch location {
        case .dashboard:
            dashboardItems.removeAll { $0.id == itemID }
        case .customList(let listID):
            guard let listIndex = customLists.firstIndex(where: { $0.id == listID }) else { return }
            customLists[listIndex].items.removeAll { $0.id == itemID }
        }
        save()
    }

    func markAllPendingTasksCompleted(in listID: UUID) {
        guard let listIndex = customLists.firstIndex(where: { $0.id == listID }) else { return }

        for itemIndex in customLists[listIndex].items.indices where customLists[listIndex].items[itemIndex].isCompleted == false {
            customLists[listIndex].items[itemIndex].isCompleted = true
            customLists[listIndex].items[itemIndex].completedAt = .now
        }

        save()
    }

    func deleteAllTasks(in listID: UUID) {
        guard let listIndex = customLists.firstIndex(where: { $0.id == listID }) else { return }
        customLists[listIndex].items.removeAll()
        save()
    }

    func moveTask(_ itemID: UUID, from source: TaskLocation, to destination: TaskLocation) {
        guard source != destination else { return }
        guard var item = removeTask(itemID, from: source) else { return }

        item.isCompleted = false
        item.completedAt = nil

        switch destination {
        case .dashboard:
            dashboardItems.insert(item, at: 0)
        case .customList(let listID):
            guard let listIndex = customLists.firstIndex(where: { $0.id == listID }) else { return }
            customLists[listIndex].items.insert(item, at: 0)
        }

        save()
    }

    func addWorker(name: String) {
        let cleaned = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard cleaned.isEmpty == false else { return }

        workers.append(Worker(name: cleaned))
        workers.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        save()
    }

    func deleteWorker(_ workerID: UUID) {
        workers.removeAll { $0.id == workerID }
        save()
    }

    func addLog(to workerID: UUID, date: Date, hours: Double, note: String = "") {
        guard hours > 0 else { return }
        guard let index = workers.firstIndex(where: { $0.id == workerID }) else { return }

        workers[index].logs.insert(
            WorkerLog(
                date: Calendar.current.startOfDay(for: date),
                hours: hours,
                note: note.trimmingCharacters(in: .whitespacesAndNewlines)
            ),
            at: 0
        )
        workers[index].logs.sort { $0.date > $1.date }
        save()
    }

    func deleteLog(workerID: UUID, logID: UUID) {
        guard let index = workers.firstIndex(where: { $0.id == workerID }) else { return }
        workers[index].logs.removeAll { $0.id == logID }
        save()
    }

    private func updateTask(_ itemID: UUID, in location: TaskLocation, mutate: (inout TaskItem) -> Void) {
        switch location {
        case .dashboard:
            guard let index = dashboardItems.firstIndex(where: { $0.id == itemID }) else { return }
            mutate(&dashboardItems[index])
        case .customList(let listID):
            guard let listIndex = customLists.firstIndex(where: { $0.id == listID }) else { return }
            guard let itemIndex = customLists[listIndex].items.firstIndex(where: { $0.id == itemID }) else { return }
            mutate(&customLists[listIndex].items[itemIndex])
        }

        save()
    }

    private func removeTask(_ itemID: UUID, from location: TaskLocation) -> TaskItem? {
        switch location {
        case .dashboard:
            guard let index = dashboardItems.firstIndex(where: { $0.id == itemID }) else { return nil }
            return dashboardItems.remove(at: index)
        case .customList(let listID):
            guard let listIndex = customLists.firstIndex(where: { $0.id == listID }) else { return nil }
            guard let itemIndex = customLists[listIndex].items.firstIndex(where: { $0.id == itemID }) else { return nil }
            return customLists[listIndex].items.remove(at: itemIndex)
        }
    }
}
