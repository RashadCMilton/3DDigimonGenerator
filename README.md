# DigimonGo

An iOS AR application that lets you bring Digimon into the real world. This app fetches Digimon data and creates 3D models that can be viewed in augmented reality.

## Project Description

DigimonGo allows users to select from a list of Digimon characters, generate 3D models from their 2D images using the Meshy API, and place them in the real world through AR. The app also allows users to save their favorite 3D Digimon models for later viewing.

## Table of Contents
- [Features](#features)
- [Project Structure](#project-structure)
- [Installation](#installation)
- [Frameworks](#frameworks)
- [Architecture](#architecture)
- [APIs](#apis)
- [Core Data](#core-data)
- [Future Improvements](#future-improvements)

## Features
- Browse a comprehensive list of Digimon characters
- Generate 3D models from 2D Digimon images using AI
- View Digimon in augmented reality
- Place Digimon in your real-world environment
- Save favorite 3D models for later viewing
- AR plane detection and coaching for better AR experience

## Project Structure
The project follows MVVM architecture with clear separation of concerns:

- **Models:**
  - `Digimon.swift` - Data model for Digimon information
  - `DigimonModel.swift` - Data model for 3D model information
  - Core Data entities: `SavedDigimon`

- **Views:**
  - `ContentView.swift` - Main view displaying the list of Digimon
  - `RealDigimonView.swift` - AR view for displaying 3D Digimon models
  - `SavedModelsView.swift` - View for displaying saved 3D models
  - `ARViewContainer` - UIViewRepresentable for handling ARKit integration

- **ViewModels:**
  - `DigimonViewModel.swift` - Handles business logic and data flow

- **Services:**
  - `APIService.swift` - Handles API requests to the Digimon API and Meshy API
  - `PersistenceController.swift` - Manages Core Data operations

## Installation
1. Clone the repository
2. Open the project in Xcode
3. Ensure you have the appropriate developer account set up for ARKit functionality
4. Build and run on a compatible iOS device (ARKit requires a physical device)

## Requirements
- iOS 16.0+
- Xcode 15.0+
- Swift 5.9+
- Physical iOS device with ARKit support

## Frameworks
- **SwiftUI** - For building the user interface
- **ARKit** - For augmented reality features
- **RealityKit** - For handling 3D models in AR
- **CoreData** - For local data persistence
- **Foundation** - For networking and data handling
- **Combine** (implicit) - Used with @Published properties in ViewModel

## Architecture
This application uses MVVM (Model-View-ViewModel) architecture:
- **Model:** Represents the data structures (`Digimon`, `DigimonModel`, `SavedDigimon`)
- **View:** SwiftUI views displaying the data and AR experience
- **ViewModel:** Connects the model and view, handling business logic and API calls
- **Services:** API service for network requests and Persistence Controller for Core Data operations

## APIs
The app uses two external APIs:

1. **Digimon API**
   - Endpoint: `https://digimon-api.vercel.app/api/digimon`
   - Provides a list of Digimon characters with their images

2. **Meshy API**
   - Base URL: `https://api.meshy.ai/v1`
   - Converts 2D images to 3D models using AI
   - The app handles the two-step process:
     1. Submit image URL to generate a task ID
     2. Poll for results using the task ID until the 3D model is ready

## Core Data
The app uses Core Data to persist saved 3D Digimon models. The data model includes:
- **SavedDigimon** entity with attributes:
  - `id` - Unique identifier
  - `usdz_url` - URL to the 3D model file

## AR Implementation
- Uses ARKit with horizontal plane detection
- Includes coaching overlay to help users find suitable surfaces
- Downloads and displays USDZ models in AR
- Scales and positions models for optimal viewing

## Future Improvements
- Add animation capabilities to 3D models
- Implement Digimon battle features
- Add sound effects and music
- Improve model management and caching
- Add more detailed information about each Digimon
- Implement social sharing features
- Add custom AR effects for different Digimon types
