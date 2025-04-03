//
//  DigimonViewModel.swift
//  DigimonGo
//
//  Created by Rashad Milton on 3/10/25.
//
import Foundation
import CoreData

class DigimonViewModel: ObservableObject {
    var apiService: APIServicing
    @Published var list: [Digimon] = []
    @Published var modelUrl: URL?
    
    init(apiService: APIServicing) {
        self.apiService = apiService
    }
    @MainActor
    func getDigimonList() async {
        do {
            list = try await apiService.fetchData(modelType: [Digimon].self)
        } catch let error {
            print(error.localizedDescription)
        }
    }

    func generate3DModel(from imageUrl: String) async {
        do {
            let url = try await apiService.generate3DModel(from: imageUrl)
            DispatchQueue.main.async {
                self.modelUrl = url
                print("✅ Model URL set: \(url)")

                // Save the 3D model to Core Data after fetching
                self.saveModelToCoreData(url: url, imageUrl: imageUrl)
            }
        } catch {
            print("❌ Error generating 3D model: \(error.localizedDescription)")
        }
    }

    // Save the 3D model URL and associated data to Core Data
    func saveModelToCoreData(url: URL, imageUrl: String) {
        let context = PersistenceController.shared.viewContext
        
        // Create a new Saved3DModel object
        let savedModel = SavedDigimon(context: context)
        savedModel.id = UUID().uuidString
        savedModel.usdz_url = url.absoluteString
       
        
        do {
            try context.save()
            print("✅ Successfully saved 3D model to Core Data")
        } catch {
            print("❌ Error saving 3D model to Core Data: \(error.localizedDescription)")
        }
    }
}
extension DigimonViewModel {
    func fetchSavedModels() -> [SavedDigimon] {
        let context = PersistenceController.shared.viewContext
        let fetchRequest: NSFetchRequest<SavedDigimon> = SavedDigimon.fetchRequest()
        
        do {
            let savedModels = try context.fetch(fetchRequest)
            return savedModels
        } catch {
            print("❌ Error fetching saved models from Core Data: \(error.localizedDescription)")
            return []
        }
    }
}
