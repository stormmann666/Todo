import SwiftUI
import UIKit

struct ContentView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "tray.full")
                }

            ListsView()
                .tabItem {
                    Label("Listas", systemImage: "list.bullet.rectangle.portrait")
                }

            WorkersView()
                .tabItem {
                    Label("Jornadas", systemImage: "clock.badge.checkmark")
                }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                store.reloadFromDisk()
            }
        }
    }
}

private struct DashboardView: View {
    @EnvironmentObject private var store: AppStore
    @State private var newItemTitle = ""

    var body: some View {
        NavigationStack {
            List {
                Section("Entrada rapida") {
                    HStack(alignment: .top, spacing: 12) {
                        TextField("Anota aqui lo que va al dashboard", text: $newItemTitle, axis: .vertical)
                            .textFieldStyle(.roundedBorder)

                        Button("Anadir") {
                            store.addDashboardItem(title: newItemTitle)
                            newItemTitle = ""
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(.vertical, 4)
                }

                TaskSectionView(
                    title: "Pendiente",
                    items: store.dashboardItems.filter { $0.isCompleted == false },
                    location: .dashboard
                )

                if store.dashboardItems.contains(where: \.isCompleted) {
                    TaskSectionView(
                        title: "Realizado",
                        items: store.dashboardItems.filter(\.isCompleted),
                        location: .dashboard
                    )
                }
            }
            .navigationTitle("Dashboard")
            .refreshable {
                store.reloadFromDisk()
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Cerrar") {
                        hideKeyboard()
                    }
                }
            }
        }
    }
}

private struct ListsView: View {
    @EnvironmentObject private var store: AppStore
    @State private var newListName = ""

    var body: some View {
        NavigationStack {
            List {
                Section("Nueva lista") {
                    HStack {
                        TextField("Ej. Pedido AMAR", text: $newListName)
                            .textFieldStyle(.roundedBorder)

                        Button("Crear") {
                            store.addList(name: newListName)
                            newListName = ""
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }

                if store.customLists.isEmpty == false {
                    Section("Resumen") {
                        NavigationLink {
                            AllPendingTasksView()
                        } label: {
                            HStack {
                                Label("Ver todo", systemImage: "square.stack.3d.up")
                                Spacer()
                                Text("\(totalPendingTasks)")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                if store.customLists.isEmpty {
                    Section {
                        ContentUnavailableView(
                            "Sin listas todavia",
                            systemImage: "text.badge.plus",
                            description: Text("Crea listas como pedidos, sanidad o mantenimiento.")
                        )
                    }
                } else {
                    Section("Tus listas") {
                        ForEach(store.customLists) { list in
                            NavigationLink {
                                TaskListDetailView(listID: list.id)
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(list.name)
                                    Text("\(list.items.filter { !$0.isCompleted }.count) pendientes")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .swipeActions {
                                Button(role: .destructive) {
                                    store.deleteList(list.id)
                                } label: {
                                    Label("Borrar", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Listas")
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Cerrar") {
                        hideKeyboard()
                    }
                }
            }
        }
    }

    private var totalPendingTasks: Int {
        store.customLists.reduce(0) { partialResult, list in
            partialResult + list.items.filter { $0.isCompleted == false }.count
        }
    }
}

private struct AllPendingTasksView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        List {
            if pendingLists.isEmpty {
                ContentUnavailableView(
                    "Sin tareas pendientes",
                    systemImage: "checkmark.circle",
                    description: Text("Ahora mismo no hay pedidos o tareas pendientes en tus listas.")
                )
            } else {
                ForEach(pendingLists) { list in
                    Section {
                        categoryHeader(for: list)

                        ForEach(list.items.filter { $0.isCompleted == false }) { item in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.title)
                                Text(list.name)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
            }
        }
        .navigationTitle("Todo pendiente")
    }

    private var pendingLists: [TaskList] {
        store.customLists.filter { list in
            list.items.contains(where: { $0.isCompleted == false })
        }
    }

    @ViewBuilder
    private func categoryHeader(for list: TaskList) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(list.name)
                        .font(.headline)
                    Text("\(list.items.filter { $0.isCompleted == false }.count) pendientes")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            HStack {
                Button("Terminar categoria") {
                    store.markAllPendingTasksCompleted(in: list.id)
                }
                .buttonStyle(.borderedProminent)

                Button("Borrar todo", role: .destructive) {
                    store.deleteAllTasks(in: list.id)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct TaskListDetailView: View {
    @EnvironmentObject private var store: AppStore
    let listID: UUID
    @State private var newItemTitle = ""

    private var taskList: TaskList? {
        store.customLists.first(where: { $0.id == listID })
    }

    var body: some View {
        List {
            Section("Nueva linea") {
                HStack(alignment: .top, spacing: 12) {
                    TextField("Anade una tarea a esta lista", text: $newItemTitle, axis: .vertical)
                        .textFieldStyle(.roundedBorder)

                    Button("Anadir") {
                        guard let listIndex = store.customLists.firstIndex(where: { $0.id == listID }) else { return }
                        let cleaned = newItemTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard cleaned.isEmpty == false else { return }
                        store.customLists[listIndex].items.insert(TaskItem(title: cleaned), at: 0)
                        store.save()
                        newItemTitle = ""
                    }
                    .buttonStyle(.borderedProminent)
                }
            }

            if let taskList {
                Section("Acciones de categoria") {
                    Button("Terminar todo") {
                        store.markAllPendingTasksCompleted(in: taskList.id)
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Borrar todo", role: .destructive) {
                        store.deleteAllTasks(in: taskList.id)
                    }
                }
            }

            if let taskList {
                TaskSectionView(
                    title: "Pendiente",
                    items: taskList.items.filter { !$0.isCompleted },
                    location: .customList(taskList.id)
                )

                if taskList.items.contains(where: \.isCompleted) {
                    TaskSectionView(
                        title: "Terminado",
                        items: taskList.items.filter(\.isCompleted),
                        location: .customList(taskList.id)
                    )
                }
            }
        }
        .navigationTitle(taskList?.name ?? "Lista")
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Cerrar") {
                    hideKeyboard()
                }
            }
        }
    }
}

private struct TaskSectionView: View {
    @EnvironmentObject private var store: AppStore

    let title: String
    let items: [TaskItem]
    let location: TaskLocation

    var body: some View {
        if items.isEmpty == false {
            Section(title) {
                ForEach(items) { item in
                    TaskRowView(item: item, location: location)
                }
            }
        }
    }
}

private struct TaskRowView: View {
    @EnvironmentObject private var store: AppStore

    let item: TaskItem
    let location: TaskLocation

    @State private var showingActions = false

    var body: some View {
        Button {
            showingActions = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(item.isCompleted ? .green : .secondary)

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .strikethrough(item.isCompleted, color: .secondary)
                        .foregroundStyle(item.isCompleted ? .secondary : .primary)
                        .multilineTextAlignment(.leading)

                    Text(item.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .confirmationDialog("Que quieres hacer?", isPresented: $showingActions) {
            if item.isCompleted == false {
                ForEach(Array(moveDestinations.enumerated()), id: \.offset) { _, destination in
                    Button("Mover a \(destination.name)") {
                        store.moveTask(item.id, from: location, to: destination.location)
                    }
                }

                Button(location == .dashboard ? "Marcar como realizado" : "Marcar como terminado") {
                    store.markTaskCompleted(item.id, from: location)
                }
            } else {
                Button("Volver a pendiente") {
                    store.markTaskPending(item.id, from: location)
                }
            }

            Button("Borrar", role: .destructive) {
                store.deleteTask(item.id, from: location)
            }
        }
    }

    private var moveDestinations: [(name: String, location: TaskLocation)] {
        var destinations: [(String, TaskLocation)] = []

        if location != .dashboard {
            destinations.append(("Dashboard", .dashboard))
        }

        for list in store.customLists where location != .customList(list.id) {
            destinations.append((list.name, .customList(list.id)))
        }

        return destinations
    }
}

private struct WorkersView: View {
    @EnvironmentObject private var store: AppStore
    @State private var newWorkerName = ""

    var body: some View {
        NavigationStack {
            List {
                Section("Alta de trabajador") {
                    HStack {
                        TextField("Nombre del trabajador", text: $newWorkerName)
                            .textFieldStyle(.roundedBorder)

                        Button("Guardar") {
                            store.addWorker(name: newWorkerName)
                            newWorkerName = ""
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }

                if store.workers.isEmpty {
                    Section {
                        ContentUnavailableView(
                            "Sin trabajadores",
                            systemImage: "person.badge.plus",
                            description: Text("Da de alta trabajadores para empezar a registrar jornadas.")
                        )
                    }
                } else {
                    Section("Trabajadores") {
                        ForEach(store.workers) { worker in
                            NavigationLink {
                                WorkerDetailView(workerID: worker.id)
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(worker.name)
                                    Text(resume(for: worker))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .swipeActions {
                                Button(role: .destructive) {
                                    store.deleteWorker(worker.id)
                                } label: {
                                    Label("Borrar", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Jornadas")
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Cerrar") {
                        hideKeyboard()
                    }
                }
            }
        }
    }

    private func resume(for worker: Worker) -> String {
        let totalHours = worker.logs.reduce(0) { $0 + $1.hours }
        return "\(worker.logs.count) registros, \(totalHours.formattedHours)"
    }
}

private struct WorkerDetailView: View {
    @EnvironmentObject private var store: AppStore
    let workerID: UUID

    @State private var selectedDate = Date()
    @State private var customHours = 8.0
    @State private var note = ""
    @State private var selectedQuickOption: QuickHoursOption = .fullDay

    private var worker: Worker? {
        store.workers.first(where: { $0.id == workerID })
    }

    var body: some View {
        List {
            Section("Anadir jornada") {
                DatePicker("Dia", selection: $selectedDate, displayedComponents: .date)

                Picker("Tipo", selection: $selectedQuickOption) {
                    ForEach(QuickHoursOption.allCases) { option in
                        Text(option.title).tag(option)
                    }
                }
                .pickerStyle(.segmented)

                if selectedQuickOption == .custom {
                    Stepper(value: $customHours, in: 0.5...24, step: 0.5) {
                        Text("Horas: \(customHours.formattedHours)")
                    }
                }

                TextField("Nota opcional", text: $note)

                Button("Guardar jornada") {
                    store.addLog(
                        to: workerID,
                        date: selectedDate,
                        hours: selectedQuickOption.hours ?? customHours,
                        note: note
                    )
                    note = ""
                    selectedQuickOption = .fullDay
                    customHours = 8
                    selectedDate = Date()
                }
                .buttonStyle(.borderedProminent)
            }

            if let worker {
                Section("Resumen") {
                    LabeledContent("Registros", value: "\(worker.logs.count)")
                    LabeledContent("Total horas", value: worker.logs.reduce(0) { $0 + $1.hours }.formattedHours)
                }

                Section("Historial") {
                    if worker.logs.isEmpty {
                        ContentUnavailableView(
                            "Sin jornadas",
                            systemImage: "calendar.badge.plus",
                            description: Text("Anade dias completos, medios dias o horas concretas.")
                        )
                    } else {
                        ForEach(worker.logs) { log in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(log.date.formatted(date: .complete, time: .omitted))
                                    .font(.headline)
                                Text(log.hours.formattedHours)
                                    .foregroundStyle(.secondary)
                                if log.note.isEmpty == false {
                                    Text(log.note)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .swipeActions {
                                Button(role: .destructive) {
                                    store.deleteLog(workerID: workerID, logID: log.id)
                                } label: {
                                    Label("Borrar", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(worker?.name ?? "Trabajador")
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Cerrar") {
                    hideKeyboard()
                }
            }
        }
    }
}

private extension Double {
    var formattedHours: String {
        if truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(self)) h"
        }

        return "\(self.formatted(.number.precision(.fractionLength(1)))) h"
    }
}

private func hideKeyboard() {
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
}
