//
//  SecretJournalApp.swift
//  SecretJournal
//
//  Created by Maksim Shyshko on 05.06.2026.
//

import SwiftUI
import SwiftData

@main
struct SecretJournalApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: JournalEntry.self) 
    }
}
