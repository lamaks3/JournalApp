//
//  ContentView.swift
//  SecretJournal
//
//  Created by Maksim Shyshko on 05.06.2026.
//

import SwiftUI
import KeychainAccess
import Combine
import PhotosUI

struct ContentView: View {
    @State private var isUnlocked = false
    @State var showAddEntry: Bool = false
    var body: some View {
        VStack{
            if isUnlocked {
                TabView {
                    Tab("Journal", systemImage: "book") {
                        Button("Add entry") {
                            showAddEntry.toggle()
                        }
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
        .sheet(isPresented: $showAddEntry) {
            AddEntryView()
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

struct AddEntryView: View {
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @SceneStorage("title") var title = ""
    @SceneStorage("content") var content = ""

    @Environment(\.dismiss) var dismiss
    var body: some View {
        NavigationStack {
            Form {
                TextField("Title", text: $title)
                TextEditor(text: $content)
                Section {
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        Label("Select Photo", systemImage: "photo")
                    }

                    if let image = selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                    }
                }
            }
            .navigationTitle("New Entry")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let image = selectedImage {
                            title = ""
                            content = ""
                            print(ImageManager.saveImage(image))
                            dismiss()
                        }
                    }
                }
            }
            .onChange(of: selectedItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        selectedImage = uiImage
                    }
                }
            }
        }
    }
}

class ImageManager {
    static let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!

    static func saveImage(_ image: UIImage) -> String? {
        let fileName = UUID().uuidString + ".jpg"
        let fileURL = documentsDirectory.appendingPathComponent(fileName)

        if let data = image.jpegData(compressionQuality: 0.8) {
            do {
                try data.write(to: fileURL)
                return fileName
            } catch {
                print("Save error: \(error)")
                return nil
            }
        }
        return nil
    }

    static func loadImage(fileName: String) -> UIImage? {
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        if let data = try? Data(contentsOf: fileURL) {
            return UIImage(data: data)
        }
        return nil
    }
}

#Preview {
    ContentView()
}

