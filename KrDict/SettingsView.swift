//
//  SettingsView.swift
//  KrDict
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("About") {
                    LabeledContent("Version", value: appVersion)
                }

                Section {
                    Link(destination: URL(string: "https://krdict.korean.go.kr")!) {
                        LabeledContent("Dictionary", value: "국립국어원 한국어기초사전")
                    }
                    Link(destination: URL(string: "https://creativecommons.org/licenses/by-sa/2.0/kr/")!) {
                        LabeledContent("License", value: "CC BY-SA 2.0 KR")
                    }
                } header: {
                    Text("Data")
                } footer: {
                    Text("Dictionary data from the Korean Learners' Dictionary by the National Institute of Korean Language, used under CC BY-SA 2.0 KR.")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }
}

#Preview {
    SettingsView()
}
