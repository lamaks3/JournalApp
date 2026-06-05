//
//  ContentView.swift
//  SecretJournal
//
//  Created by Maksim Shyshko on 05.06.2026.
//

import SwiftUI
import KeychainAccess

struct ContentView: View {
    @State private var isUnlocked = false
    var body: some View {
        if isUnlocked {
            TabView {
                Tab("Journal", systemImage: "book") {
                        Text("asad")
                    }

                Tab("Settings", systemImage: "gear") {
                    SettingsView()
                }
            }
        } else {
            EnterPinView(isUnlocked: $isUnlocked)
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

struct EnterPinView: View {
    @State var pinCode = ""
    @Binding var isUnlocked: Bool

    func checkPIN() {
        if KeychainService().checkPIN(pinCode) {
            isUnlocked = true
        }
    }
    var body: some View {
        VStack(spacing: 20) {
            Text("Enter your PIN code")
            TextField("PIN", text: $pinCode)
            Button(action: checkPIN) {
                Text("Check PIN")
            }
        }
    }
}

class KeychainService {
    let keychain = Keychain(service: "com.yourname.SecretJournal")

    func setPIN(_ pin: String) {
        keychain["userPIN"] = pin
    }

    func checkPIN(_ pin: String) -> Bool {
        keychain["userPIN"] == pin
    }

    init () {
        keychain["userPIN"] = "1234"
    }
}

#Preview {
    ContentView()
}
