//
//  TodoApp.swift
//  Todo
//
//  Created by Antonio Muñoz on 13/4/26.
//

import SwiftUI

@main
struct TodoApp: App {
    @StateObject private var store = AppStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}
