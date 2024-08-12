//
//  CountryPickerView.swift
//  visibl
//
//

import SwiftUI

enum NavigationTarget {
    case nextPage
}

struct CountryPickerView: View {
    @ObservedObject var aaxManager: AAXManager
    @State private var isNavigatingToAAXLogin = false
    @State private var loginURL: URL?
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            VStack {
                List(aaxManager.countries) { country in
                    HStack {
                        Text(country.flag)
                        Text(country.name)
                            .font(.system(size: 15, weight: .medium))
                        Spacer()
                        if country.code == self.aaxManager.selectedCountryCode {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.green)
                        }
                    }
                    .onTapGesture {
                        self.aaxManager.selectedCountryCode = country.code
                    }
                }
                .scrollContentBackground(.hidden)
                .listStyle(.plain)
                
                Button(action: {
                    isLoading = true
                    Task {
                        do {
                            loginURL = try await aaxManager.getAAXLoginURL()
                            isLoading = false
                            isNavigatingToAAXLogin = true
                        } catch {
                            print("Error fetching AAX login URL: \(error.localizedDescription)")
                        }
                    }
                }) {
                    HStack (spacing: 8) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .tint(.white)
                            .opacity(isLoading ? 1 : 0)
                        Text("aax_continue_button".localized)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.blue)
                    .cornerRadius(8)
                    .padding(.horizontal, 14)
                }
                
                Spacer()
            }
            .navigationBarTitle("aax_locale_title", displayMode: .inline)
            .navigationBarItems(
                trailing: AccountBarTextButton(
                    title: "done_button".localized
                ) {
                    aaxManager.eventSender.send(.dismiss)
                }
            )
            .navigationDestination(isPresented: $isNavigatingToAAXLogin) {
                if let url = loginURL {
                    AAXLoginView(aaxManager: aaxManager, url: url)
                }
            }
        }
    }
}
