//
//  ContentView.swift
//  SecretJournal
//
//  Created by Maksim Shyshko on 05.06.2026.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Journal", systemImage: "book") {
                    Text("asad")
                }

            Tab("Settings", systemImage: "gear") {
                SettingsView()
            }
        }
    }
}

struct SettingsView: View {
    @AppStorage("username") var username = ""
    @AppStorage("turnBlur") var turnBlur = false

    var body: some View {

        Form {
            Section(header: Text("Profile")) {
                TextField("User Name", text: $username)
            }
            Section(header: Text("App Settigns")) {
                Toggle(isOn: $turnBlur) {
                    Text("Turn Blur ")
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
