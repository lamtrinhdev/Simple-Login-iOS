//
//  SimpleLoginApp.swift
//  SimpleLogin
//
//  Created by Thanh-Nhon Nguyen on 28/06/2021.
//

import CoreData
import SimpleLoginPackage
import SwiftUI

@main
struct SimpleLoginApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @AppStorage(kBiometricAuthEnabled) var biometricAuthEnabled = false
    @AppStorage(kUltraProtectionEnabled) var ultraProtectionEnabled = false
    @AppStorage(kForceDarkMode) private var forceDarkMode = false
    @AppStorage(kAliasDisplayMode) private var displayMode: AliasDisplayMode = .default
    @AppStorage(kDidShowTips) private var didShowTips = false
    @State private var preferences = Preferences.shared
    @State private var apiKey: ApiKey?
    @State private var apiService: APIServiceProtocol?
    private let reachabilityObserver = ReachabilityObserver()
    private let persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "SimpleLogin")
        container.loadPersistentStores { _, error in
            if let error = error {
                print("Unable to load persistent stores: \(error)")
            }
        }
        return container
    }()

    var body: some Scene {
        WindowGroup {
            if let apiKey = apiKey, let apiService = apiService {
                MainView {
                    try? KeychainService.shared.setApiKey(nil)
                    try? DataController(context: persistentContainer.viewContext).reset()
                    self.apiKey = nil
                    self.apiService = nil
                    self.biometricAuthEnabled = false
                    self.ultraProtectionEnabled = false
                    self.forceDarkMode = false
                    self.displayMode = .default
                    self.didShowTips = false
                    if let cookies = HTTPCookieStorage.shared.cookies {
                        for cookie in cookies {
                            HTTPCookieStorage.shared.deleteCookie(cookie)
                        }
                    }
                }
                .accentColor(.slPurple)
                .environment(\.managedObjectContext, persistentContainer.viewContext)
                .environmentObject(preferences)
                .environmentObject(Session(apiKey: apiKey, apiService: apiService))
                .environmentObject(reachabilityObserver)
                .sensitiveContent {
                    ZStack {
                        Color(.systemBackground)
                        Image("LogoWithName")
                    }
                    .ignoresSafeArea()
                }
            } else {
                LogInView(apiUrl: preferences.apiUrl) { apiKey, apiService in
                    try? KeychainService.shared.setApiKey(apiKey)
                    self.apiKey = apiKey
                    self.apiService = apiService
                }
                .accentColor(.slPurple)
                .environmentObject(preferences)
            }
        }
        .onChange(of: scenePhase) { _ in
            if forceDarkMode {
                UIApplication.shared.windows.first?.overrideUserInterfaceStyle = .dark
            }
        }
    }
}
