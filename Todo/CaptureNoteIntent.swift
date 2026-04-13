import AppIntents

struct CaptureDashboardNoteIntent: AppIntent {
    static let title: LocalizedStringResource = "Anotar pedido"
    static let description = IntentDescription("Guarda un texto directamente en el dashboard.")
    static let openAppWhenRun = false

    @Parameter(title: "Texto")
    var text: String

    func perform() async throws -> some IntentResult & ProvidesDialog {
        await MainActor.run {
            AppRepository.addDashboardItem(title: text)
        }
        return .result(dialog: "Anotado en el dashboard.")
    }
}

struct TodoShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: CaptureDashboardNoteIntent(),
            phrases: [
                "Anota pedido en \(.applicationName)",
                "Anotar pedido con \(.applicationName)",
                "Nueva nota en \(.applicationName)"
            ],
            shortTitle: "Anotar pedido",
            systemImageName: "text.badge.plus"
        )
    }
}
