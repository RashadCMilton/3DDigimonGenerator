//
//  RealDigimonView.swift
//  DigimonGo
//
//  Created by Rashad Milton on 3/10/25.
//

import SwiftUI
import RealityKit
import ARKit

struct RealDigimonView: View {
    let digimon: Digimon
    @StateObject var viewModel = DigimonViewModel(apiService: APIService())
    
    var body: some View {
        NavigationStack {
            VStack {
                NavigationLink(destination: SavedModelsView(viewModel: viewModel), label: { Text("Saved Models") })
                Button("Generate 3D Digimon") {
                    Task {
                        await viewModel.generate3DModel(from: digimon.img)
                    }
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                
                ARViewContainer(modelUrl: viewModel.modelUrl)
                    .edgesIgnoringSafeArea(.all)
            }
            .padding()
        }
        
    }
}

struct ARViewContainer: UIViewRepresentable {
    var modelUrl: URL?
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        
        // Show debug visualization for plane detection
        arView.debugOptions = [.showAnchorOrigins, .showFeaturePoints]
        
        // Configure the AR session
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        arView.session.run(config)
        
        // Add coaching overlay
        let coachingOverlay = ARCoachingOverlayView()
        coachingOverlay.session = arView.session
        coachingOverlay.goal = .horizontalPlane
        coachingOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        arView.addSubview(coachingOverlay)
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        if let modelUrl = modelUrl {
            if context.coordinator.currentModelUrl != modelUrl {
                context.coordinator.currentModelUrl = modelUrl
                
                // Clear existing anchors
                uiView.scene.anchors.removeAll()
                
                // Reconfigure AR session
                let config = ARWorldTrackingConfiguration()
                config.planeDetection = [.horizontal]
                uiView.session.run(config, options: [.resetTracking, .removeExistingAnchors])
                
                // Load new model
                loadModel(from: modelUrl, into: uiView)
                
                print("🔄 Loading new model: \(modelUrl)")
            }
        }
    }

    // Add a Coordinator class to track the current model URL
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        var currentModelUrl: URL?
    }
    
    func loadModel(from url: URL, into arView: ARView) {
        // Clear any existing anchors
        arView.scene.anchors.removeAll()
        print("🔄 Starting model download from: \(url)")

        // Create a download task for the model
        let downloadTask = URLSession.shared.downloadTask(with: url) { localURL, response, error in
            guard let localURL = localURL else {
                print("❌ Failed to download model: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            do {
                // Create a local file URL in the documents directory
                let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                let destinationURL = documentsDirectory.appendingPathComponent("digimon_model.usdz")
                
                // Remove any existing file
                try? FileManager.default.removeItem(at: destinationURL)
                
                // Copy the downloaded file to the documents directory
                try FileManager.default.copyItem(at: localURL, to: destinationURL)
                
                // Load the model on the main thread
                DispatchQueue.main.async {
                    do {
                        // Create an entity from the local file
                        let modelEntity = try ModelEntity.load(contentsOf: destinationURL)
                        
                        // Create an anchor and add the entity to it
                        let anchor = AnchorEntity(plane: .horizontal)
                        anchor.addChild(modelEntity)
                        
                        // Add some basic transformations to position and scale the model
                        // Try different scale values
                        modelEntity.setScale(SIMD3<Float>(0.5, 0.5, 0.5), relativeTo: anchor)

                        // Position it slightly above the detected plane
                        modelEntity.position = SIMD3<Float>(0, 0.1, 0)
                        
                        // Add the anchor to the scene
                        arView.scene.anchors.append(anchor)
                        
                        // Configure the AR session
                        let config = ARWorldTrackingConfiguration()
                        config.planeDetection = [.horizontal]
                        arView.session.run(config)
                        
                        print("✅ Successfully loaded 3D model")
                    } catch {
                        print("❌ Failed to load model entity: \(error)")
                    }
                }
            } catch {
                print("❌ Failed to save downloaded model: \(error)")
            }
        }
        
        downloadTask.resume()
    }
}

#Preview {
    RealDigimonView(digimon: Digimon(name: "Sukamon", img: "https://digimon.shadowsmith.com/img/sukamon.jpg", level: "Champion"))
}
