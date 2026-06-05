//
//  ContentView.swift
//  SecretJournal
//
//  Created by Maksim Shyshko on 05.06.2026.
//

import SwiftUI
import KeychainAccess
import Combine

struct ContentView: View {
    @State private var isUnlocked = false
    var body: some View {
        if isUnlocked {
            TabView {
                Tab("Journal", systemImage: "book") {
                        Text("asad")
                    }

                Tab("Settings", systemImage: "gear") {
                    SettingsView(isUnlocked: $isUnlocked)
                }
            }
        } else {
            if KeychainService().isPINSet() {
                EnterPinView(isUnlocked: $isUnlocked)
            } else {
                CreatePINView(isUnlocked: $isUnlocked)
            }
        }

    }
}

struct SettingsView: View {
    @AppStorage("username") var username = ""
    @AppStorage("turnBlur") var turnBlur = false
    @Binding var isUnlocked: Bool

    func resetPassword() {
        KeychainService().keychain["userPIN"] = nil
        isUnlocked = false
    }
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
            Section(header: Text("Change Password")) {
                Button("Reset Password") {
                    resetPassword()
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
            SecureField("PIN", text: $pinCode)
            Button(action: checkPIN) {
                Text("Check PIN")
            }
        }
    }
}

struct CreatePINView: View {
    @State var pinCode = ""
    @Binding var isUnlocked: Bool

    func setPIN() {
        KeychainService().setPIN(pinCode)
        isUnlocked = true
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("Create your PIN code")
            SecureField("PIN", text: $pinCode)
            Button(action: setPIN) {
                Text("Set PIN")
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

    func isPINSet() -> Bool {
        if let pin = keychain["userPIN"] {
            return !pin.isEmpty
        }
        return false
    }
}

#Preview {
    ContentView()
}
