//
//  APIService.swift
//  DigimonGo
//
//  Created by Rashad Milton on 3/10/25.
//

//
//  APIService.swift
//  DigimonGo
//
//  Created by Rashad Milton on 3/10/25.
//

import Foundation

struct DigimonEndpoint {
    static let url = "https://digimon-api.vercel.app/api/digimon"
}

// For the first API call (image-to-3d endpoint)
struct MeshyCreateResponse: Codable {
    let result: String  // task ID as a string
}

// For the second API call (results endpoint)
struct MeshyResultResponse: Codable {
    let id: String
    let status: String
    let progress: Int
    let model_urls: ModelUrls?
    let task_error: String?
    
    struct ModelUrls: Codable {
        let glb: String?
        let usdz: String?
    }
}

struct ResultData: Codable {
    let usdz_url: String
    // Add any other fields that might be in the result
}
struct MeshyEndpoint {
    static let baseUrl = "https://api.meshy.ai/v1"
    static let imageTo3DUrl = "\(baseUrl)/image-to-3d"
    static let resultUrl = "\(baseUrl)/results" // This might not be needed anymore
    static let apiKey = "msy_J3OMMVa1bO1kvAn9Q0cmxLQgjkMCzsMjCyyu"
}

protocol APIServicing {
    func fetchData<T: Decodable>(modelType: T.Type) async throws -> T
    func generate3DModel(from imageUrl: String) async throws -> URL
}

class APIService: APIServicing {
    
    //  Fetch Digimon data
    func fetchData<T: Decodable>(modelType: T.Type) async throws -> T {
        let urlString = DigimonEndpoint.url
        guard let url = URL(string: urlString) else {
            fatalError("Invalid URL")
        }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return try JSONDecoder().decode(modelType, from: data)
        } catch {
            print(error.localizedDescription)
            throw error
        }
    }
    
    func generate3DModel(from imageUrl: String) async throws -> URL {
        guard let url = URL(string: MeshyEndpoint.imageTo3DUrl) else {
            fatalError("Invalid URL")
        }
        
        // Request body
        let body: [String: Any] = [
            "image_url": imageUrl
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            fatalError("Failed to encode JSON")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(MeshyEndpoint.apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = jsonData
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        if let jsonString = String(data: data, encoding: .utf8) {
            print("🔥 Full Response from MeshyAPI: \(jsonString)")
        }
        
        let response = try JSONDecoder().decode(MeshyCreateResponse.self, from: data)
        print("✅ Result ID: \(response.result)")
        
        // Implement retry logic with backoff
        let resultId = response.result
        var delay = 5.0 // Start with 5 seconds
        let maxRetries = 12
        
        for retry in 0..<maxRetries {
            do {
                return try await fetchModelUrl(for: resultId)
            } catch let error as NSError where error.code == 202 {
                // Still processing, wait and retry
                print("⏳ Model still processing, retrying in \(Int(delay)) seconds (attempt \(retry + 1)/\(maxRetries))...")
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                delay = min(delay * 1.5, 30.0) // Exponential backoff, capped at 30 seconds
            } catch {
                // Pass through any other errors
                throw error
            }
        }
        
        throw NSError(domain: "API", code: 408, userInfo: [NSLocalizedDescriptionKey: "Request timed out after \(maxRetries) retries"])
    }
    
    
    private func fetchModelUrl(for resultId: String) async throws -> URL {
        // Meshy API docs, this should be the correct endpoint
        let urlString = "\(MeshyEndpoint.baseUrl)/image-to-3d/\(resultId)"
        
        guard let url = URL(string: urlString) else {
            fatalError("Invalid URL")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(MeshyEndpoint.apiKey)", forHTTPHeaderField: "Authorization")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        if let jsonString = String(data: data, encoding: .utf8) {
            print("🔥 Full Response from Result API: \(jsonString)")
        }
        
        // Parse the response manually to handle various response formats
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            // Check status
            if let status = json["status"] as? String {
                print("📊 Task status: \(status)")
                
                if status == "COMPLETED" || status == "SUCCESS" || status == "SUCCEEDED" {
                    // Look for output object which contains the URLs
                    if let output = json["output"] as? [String: Any],
                       let usdzUrlString = output["usdz_url"] as? String,
                       let usdzUrl = URL(string: usdzUrlString) {
                        return usdzUrl
                    }
                    // Alternative format: direct model_urls object
                    else if let modelUrls = json["model_urls"] as? [String: Any],
                            let usdzUrlString = modelUrls["usdz"] as? String,
                            let usdzUrl = URL(string: usdzUrlString) {
                        return usdzUrl
                    }
                    // Check for direct model_url field
                    else if let usdzUrlString = json["model_url"] as? String,
                            let usdzUrl = URL(string: usdzUrlString) {
                        return usdzUrl
                    }
                    else {
                        throw NSError(domain: "API", code: 500, userInfo: [NSLocalizedDescriptionKey: "Model URL not found in response"])
                    }
                }
                
                if status == "PENDING" || status == "IN_PROGRESS" {
                    throw NSError(domain: "API", code: 202, userInfo: [NSLocalizedDescriptionKey: "Model still processing"])
                }
                
                if status == "FAILED" || status == "ERROR" {
                    let errorMsg = (json["task_error"] as? String) ?? "3D model generation failed"
                    throw NSError(domain: "API", code: 500, userInfo: [NSLocalizedDescriptionKey: errorMsg])
                }
            }
        }
        
        throw NSError(domain: "API", code: 400, userInfo: [NSLocalizedDescriptionKey: "Unexpected response format"])
    }
}

