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
import SwiftData

@Model
class JournalEntry {
    var id: UUID = UUID()
    var title: String
    var content: String
    var date: Date = Date()
    var imageFileName: String?

    init(title: String, content: String, imageFileName: String?) {
        self.title = title
        self.content = content
        self.imageFileName = imageFileName
    }
}

struct ContentView: View {
    @Query(sort: \JournalEntry.date, order: .reverse) var entries: [JournalEntry]
    @State private var isUnlocked = false
    @State var showAddEntry: Bool = false
    var body: some View {
        VStack{
            if isUnlocked {
                TabView {
                    Tab("Journal", systemImage: "book") {
                        NavigationStack {
                            List(entries) { entry in
                                VStack(alignment: .leading) {
                                    Text(entry.title).font(.headline)
                                    Text(entry.content).font(.subheadline).lineLimit(2)

                                    if let fileName = entry.imageFileName,
                                       let uiImage = ImageManager.loadImage(fileName: fileName) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(height: 100)
                                            .cornerRadius(8)
                                    }
                                }
                            }
                            .navigationTitle("My Journal")
                            .toolbar {
                                Button("Add") { showAddEntry.toggle() }
                            }
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
    @Environment(\.modelContext) private var modelContext

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
                        var savedFileName: String? = nil
                        if let image = selectedImage {
                            savedFileName = ImageManager.saveImage(image)
                        }

                        let newEntry = JournalEntry(title: title, content: content, imageFileName: savedFileName)

                        modelContext.insert(newEntry)

                        title = ""
                        content = ""
                        dismiss()
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
        .modelContainer(for: JournalEntry.self, inMemory: true)
}

