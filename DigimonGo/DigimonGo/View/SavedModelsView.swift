//
//  SavedModelsView.swift
//  DigimonGo
//
//  Created by Rashad Milton on 3/11/25.
//

import SwiftUI

struct SavedModelsView: View {
    @StateObject var viewModel = DigimonViewModel(apiService: APIService())
    var savedDigimon: [SavedDigimon]?
    
    var body: some View {
        VStack {
            
            List(viewModel.fetchSavedModels(), id: \.id) { model in
                Text(model.usdz_url ?? "No URL")
                // Add any additional views or actions for the saved models
            }
            .onAppear {
                viewModel.fetchSavedModels() // Fetch saved models when the view appears
            }
        }
    }
}


#Preview {
    SavedModelsView()
}
