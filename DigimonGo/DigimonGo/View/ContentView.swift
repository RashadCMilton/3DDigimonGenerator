//
//  ContentView.swift
//  DigimonGo
//
//  Created by Rashad Milton on 3/10/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = DigimonViewModel(apiService: APIService())
    var body: some View {
        NavigationStack {
            VStack {
                List(viewModel.list) { digimon in
                    NavigationLink(destination:RealDigimonView(digimon: digimon)) {
                        Text(digimon.name)
                    }
                }
            }.onAppear() {
                Task{
                    await viewModel.getDigimonList()
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
