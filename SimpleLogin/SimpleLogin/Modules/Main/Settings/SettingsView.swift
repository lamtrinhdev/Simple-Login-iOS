//
//  SettingsView.swift
//  SimpleLogin
//
//  Created by Nhon Nguyen on 08/04/2022.
//

import AlertToast
import SimpleLoginPackage
import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @StateObject private var localAuthenticator = LocalAuthenticator()
    @State private var showingAboutView = false

    var body: some View {
        NavigationView {
            Form {
                if localAuthenticator.biometryType != .none {
                    BiometricAuthenticationSection()
                        .environmentObject(localAuthenticator)
                }
                LocalSettingsSection()
                AliasDisplayModeSection()
                KeyboardExtensionSection()
                RateAndTipsSection()
                AboutSection(showingAboutView: $showingAboutView)
            }
            .navigationTitle("Settings")
            .onAppear {
                if UIDevice.current.userInterfaceIdiom != .phone, !showingAboutView {
                    showingAboutView = true
                }
            }
        }
        .slNavigationView()
        .alertToastMessage($localAuthenticator.message)
        .alertToastError($localAuthenticator.error)
    }
}

private struct BiometricAuthenticationSection: View {
    @EnvironmentObject private var localAuthenticator: LocalAuthenticator
    @AppStorage(kUltraProtectionEnabled) var ultraProtectionEnabled = false

    var body: some View {
        Section(content: {
            Toggle(isOn: $localAuthenticator.biometricAuthEnabled) {
                Label(localAuthenticator.biometryType.description,
                      systemImage: localAuthenticator.biometryType.systemImageName)
            }
            .toggleStyle(SwitchToggleStyle(tint: .slPurple))

            if localAuthenticator.biometricAuthEnabled {
                VStack {
                    Toggle(isOn: $ultraProtectionEnabled) {
                        Label {
                            Text("Ultra-protection")
                        } icon: {
                            if #available(iOS 15, *) {
                                Image(systemName: "bolt.shield")
                            } else {
                                Image(systemName: "shield")
                            }
                        }
                    }
                    .toggleStyle(SwitchToggleStyle(tint: .slPurple))

                    Text("Request local authentication everytime the app goes in foreground")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }, header: {
            Text("Local authentication")
        }, footer: {
            Text("Restrict unwelcome access to your SimpleLogin application on this device")
        })
    }
}

/// For settings that are local like haptic effect & dark mode
private struct LocalSettingsSection: View {
    @AppStorage(kHapticFeedbackEnabled) private var hapticEffectEnabled = true
    @AppStorage(kForceDarkMode) private var forceDarkMode = false

    var body: some View {
        Section {
            Toggle("Haptic feedback", isOn: $hapticEffectEnabled)
                .toggleStyle(SwitchToggleStyle(tint: .slPurple))

            VStack {
                Toggle("Force dark mode", isOn: $forceDarkMode)
                    .toggleStyle(SwitchToggleStyle(tint: .slPurple))

                Text("You need to restart the application for this option to take effect")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private struct AliasDisplayModeSection: View {
    @AppStorage(kAliasDisplayMode) var aliasDisplayMode: AliasDisplayMode = .default
    @State private var showingSampleData = false

    var body: some View {
        Section(content: {
            VStack {
                Picker(selection: $aliasDisplayMode,
                       label: Text(aliasDisplayMode.description)) {
                    ForEach(AliasDisplayMode.allCases, id: \.self) { mode in
                        Text(mode.description)
                            .tag(mode)
                    }
                }
                       .pickerStyle(SegmentedPickerStyle())

                if showingSampleData {
                    AliasCompactView(alias: Alias.sample,
                                     onCopy: {},
                                     onSendMail: {},
                                     onToggle: {},
                                     onPin: {},
                                     onUnpin: {},
                                     onDelete: {})
                }
            }
        }, header: {
            Text("Alias display mode")
        })
        .onChange(of: aliasDisplayMode) { _ in
            showingSampleData = true
        }
    }
}

private struct KeyboardExtensionSection: View {
    @AppStorage(kKeyboardExtensionMode, store: .shared)
    private var keyboardExtensionMode: KeyboardExtensionMode = .all
    @State private var showingExplanation = false

    var body: some View {
        Section(header: Text("Keyboard extension"),
                footer: footerView) {
            Picker(selection: $keyboardExtensionMode,
                   label: Text(keyboardExtensionMode.title)) {
                ForEach(KeyboardExtensionMode.allCases, id: \.self) { mode in
                    Text(mode.title)
                        .tag(mode)
                }
            }
                   .pickerStyle(SegmentedPickerStyle())
                   .sheet(isPresented: $showingExplanation) {
                       KeyboardFullAccessExplanationView()
                   }
        }
    }

    private var footerView: some View {
        VStack {
            // swiftlint:disable:next line_length
            Text("You need to enable and give the keyboard full access in order to use it.\nGo to Settings ➝ General ➝ Keyboard ➝ Keyboards.")
            HStack {
                Button(action: {
                    UIApplication.shared.openSettings()
                }, label: {
                    Text("Open Settings")
                        .fontWeight(.medium)
                        .foregroundColor(.slPurple)
                })

                Text("•")

                Button(action: {
                    showingExplanation = true
                }, label: {
                    Text("Why full access?")
                        .fontWeight(.medium)
                        .foregroundColor(.slPurple)
                })

                Spacer()
            }
        }
    }
}

private struct KeyboardFullAccessExplanationView: View {
    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    // swiftlint:disable line_length
                    Text("""
        Most of the functionalities of this application are based on making requests to our server. Every request is attached with an API key in order for our server to authenticate you.

        When you successfully log in, our server sends a valid API key to the application. The application then saves this API key to a Keychain Group in order to reuse it without asking you to authenticate again.

        The keyboard extension needs to use the API key saved in Keychain Group by the host application to make requests by itself (get the list of aliases and create new aliases). Such access to Keychain Group and requests require full access. The keyboard extension does not record or share anything you type.

        More technical information [here]( https://developer.apple.com/documentation/uikit/keyboards_and_input/creating_a_custom_keyboard/configuring_open_access_for_a_custom_keyboard).
        """)
                    // swiftlint:enable line_length
                    HStack {
                        Text("Need more information?")
                        URLButton(urlString: "mailto:support@simplelogin.zendesk.com",
                                  foregroundColor: .slPurple) {
                            Label("Email us", systemImage: "envelope.fill")
                        }
                    }
                    .padding(.top)
                }
                    .padding()
            }
            .navigationTitle("Why full access?")
            .navigationBarItems(leading: closeButton)
        }
    }

    private var closeButton: some View {
        Button(action: {
            presentationMode.wrappedValue.dismiss()
        }, label: {
            Text("Close")
        })
    }
}

private struct RateAndTipsSection: View {
    var body: some View {
        Section {
            Button(action: openAppStore) {
                Label(title: {
                    Text("Rate & review on App Store")
                        .foregroundColor(Color(.label))
                }, icon: {
                    Text("🌟")
                })
            }

            NavigationLink(destination: {
                TipsView(isFirstTime: false)
            }, label: {
                Label(title: {
                    Text("Tips")
                }, icon: {
                    Text("💡")
                })
            })
        }
    }

    private func openAppStore() {
        let urlString = "https://apps.apple.com/app/id1494359858?action=write-review"
        guard let writeReviewURL = URL(string: urlString) else { return }
        UIApplication.shared.open(writeReviewURL, options: [:])
    }
}

private struct AboutSection: View {
    @Binding var showingAboutView: Bool

    var body: some View {
        Section {
            NavigationLink(
                isActive: $showingAboutView,
                destination: {
                    AboutView()
                },
                label: {
                    Label("About SimpleLogin", systemImage: "info.circle")
                })
        }
    }
}

enum AliasDisplayMode: Int, CaseIterable {
    // swiftlint:disable:next explicit_enum_raw_value
    case `default` = 0, comfortable, compact

    var description: String {
        switch self {
        case .default: return "Default"
        case .comfortable: return "Comfortable"
        case .compact: return "Compact"
        }
    }
}
