//
//  AliasContactsView.swift
//  SimpleLogin
//
//  Created by Thanh-Nhon Nguyen on 20/11/2021.
//

import Combine
import SimpleLoginPackage
import SwiftUI

struct AliasContactsView: View {
    @StateObject private var viewModel: AliasContactsViewModel
    @State private var copiedText: String?
    @State private var newContactEmail = ""
    @State private var selectedUrlString: String?
    private let onUpgrade: () -> Void

    init(alias: Alias, session: Session, onUpgrade: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: .init(alias: alias, session: session))
        self.onUpgrade = onUpgrade
    }

    var body: some View {
        let showingCopyAlert = makeShowingCopyAlertBinding()
        let showingCreatedContactAlert = makeShowingCreatedContactAlert()
        List {
            Section(header: Text("Create new contact"),
                    footer: createContactSectionFooter) {
                HStack {
                    TextField("Contact email", text: $newContactEmail)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .textFieldStyle(.roundedBorder)
                    Button("Create") {
                        viewModel.createContact(contactEmail: newContactEmail)
                    }
                    .foregroundColor(.slPurple)
                    .disabled(newContactEmail.isEmpty)
                }
                .buttonStyle(.plain)
            }

            Section {
                if !viewModel.contacts.isEmpty {
                    ForEach(viewModel.contacts, id: \.id) { contact in
                        ContactView(viewModel: viewModel,
                                    copiedText: $copiedText,
                                    contact: contact)
                        .onAppear {
                            viewModel.getMoreContactsIfNeed(currentContact: contact)
                        }
                    }
                } else if !viewModel.isFetchingContacts {
                    Text("No contacts")
                        .foregroundColor(.secondary)
                        .font(.body.italic())
                        .frame(maxWidth: .infinity, alignment: .center)
                }

                if viewModel.isFetchingContacts {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding()
                }
            }
        }
        .listStyle(.insetGrouped)
        .refreshable { await viewModel.refresh() }
        .animation(.default, value: viewModel.contacts.count)
        .toolbar {
            ToolbarItem(placement: .principal) {
                AliasNavigationTitleView(alias: viewModel.alias)
            }
        }
        .onAppear {
            viewModel.getMoreContactsIfNeed(currentContact: nil)
        }
        .onReceive(Just(viewModel.createdContact)) { createdContact in
            if createdContact != nil {
                newContactEmail = ""
            }
        }
        .alert("Please upgrade to create contacts",
               isPresented: $viewModel.shouldUpgrade,
               actions: {
            Button("Upgrade", role: nil, action: onUpgrade)
            Button("Cancel", role: .cancel) {}
        })
        .betterSafariView(urlString: $selectedUrlString)
        .alertToastCopyMessage(isPresenting: showingCopyAlert, message: copiedText)
        .alertToastError($viewModel.error)
        .alertToastLoading(isPresenting: $viewModel.isLoading)
        .alertToastMessage(showingCreatedContactAlert)
    }

    private func makeShowingCopyAlertBinding() -> Binding<Bool> {
        .init(get: {
            copiedText != nil
        }, set: { isShowing in
            if !isShowing {
                copiedText = nil
            }
        })
    }

    private func makeShowingCreatedContactAlert() -> Binding<String?> {
        .init(get: {
            if viewModel.createdContact != nil {
                return "Created new contact"
            } else {
                return nil
            }
        }, set: { message in
            if message == nil {
                viewModel.handledCreatedContact()
            }
        })
    }

    private var createContactSectionFooter: some View {
        Button("How to send emails from your alias?") {
            selectedUrlString = "https://simplelogin.io/docs/getting-started/send-email/"
        }
        .foregroundColor(.slPurple)
    }
}

private struct ContactView: View {
    @ObservedObject var viewModel: AliasContactsViewModel
    @Binding var copiedText: String?
    let contact: Contact

    var body: some View {
        Menu(content: {
            Section {
                Button(action: {
                    Vibration.soft.vibrate()
                    copiedText = contact.reverseAlias
                    UIPasteboard.general.string = contact.reverseAlias
                }, label: {
                    Label("Copy reverse-alias\n(with display name)", systemImage: "doc.on.doc")
                })

                Button(action: {
                    Vibration.soft.vibrate()
                    copiedText = contact.reverseAliasAddress
                    UIPasteboard.general.string = contact.reverseAliasAddress
                }, label: {
                    Label("Copy reverse-alias\n(without display name)", systemImage: "doc.on.doc")
                })
            }

            Section {
                Button(action: {
                    if let mailToUrl = URL(string: "mailto:\(contact.reverseAliasAddress)") {
                        UIApplication.shared.open(mailToUrl)
                    }
                }, label: {
                    Label("Send email", systemImage: "paperplane")
                })
            }

            Section {
                if contact.blockForward {
                    Button(action: {
                        viewModel.toggleContact(contact)
                    }, label: {
                        Label("Unblock", systemImage: "hand.thumbsup")
                    })
                } else {
                    Button(action: {
                        viewModel.toggleContact(contact)
                    }, label: {
                        Label("Block", systemImage: "hand.raised")
                    })
                }
            }

            Section {
                DeleteMenuButton {
                    viewModel.deleteContact(contact)
                }
            }
        }, label: {
            HStack {
                VStack(alignment: .leading) {
                    Text(contact.email)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    Text("\(contact.creationDateString) (\(contact.relativeCreationDateString))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .fixedSize(horizontal: false, vertical: false)
                .opacity(contact.blockForward ? 0.5 : 1)

                Spacer()

                if contact.blockForward {
                    Text("⛔")
                        .font(.title)
                        .padding(.trailing)
                }
            }
            .fixedSize(horizontal: false, vertical: false)
        })
    }
}
