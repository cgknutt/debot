import Foundation
import SwiftUI

/// Service for interacting with aviation data API
class AviationService {
    private let baseURL = "https://api.example.com/v1"
    private let apiKey = "demo_key" // Replace with your actual API key
    
    // Tracking API request count to manage free tier limits
    private(set) var requestCount = 0
    
    // Error types for aviation API
    enum AviationError: Error {
        case invalidURL
        case noData
        case decodingError(String)
        case apiError(String)
    }
    
    // MARK: - Flight Model
    
    // Using the Flight model defined in Models/Flight.swift
    // We don't need a typealias anymore as we can refer to Flight directly
    
    // MARK: - Search Parameters
    
    struct SearchParameters {
        var flightNumber: String?
        var departureAirport: String?
        var arrivalAirport: String?
        var status: String?
        var date: Date?
        
        // Build query parameters for the API request
        func buildQueryItems() -> [URLQueryItem] {
            var queryItems = [URLQueryItem]()
            
            if let flightNumber = flightNumber {
                queryItems.append(URLQueryItem(name: "flight_number", value: flightNumber))
            }
            
            if let departureAirport = departureAirport {
                queryItems.append(URLQueryItem(name: "dep_iata", value: departureAirport))
            }
            
            if let arrivalAirport = arrivalAirport {
                queryItems.append(URLQueryItem(name: "arr_iata", value: arrivalAirport))
            }
            
            if let status = status {
                queryItems.append(URLQueryItem(name: "status", value: status))
            }
            
            if let date = date {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                queryItems.append(URLQueryItem(name: "date", value: dateFormatter.string(from: date)))
            }
            
            return queryItems
        }
    }
    
    // MARK: - API Methods
    
    func searchFlights(parameters: SearchParameters) async throws -> [Flight] {
        // In a real implementation, this would make an API request
        // For demo purposes, we'll return mock data
        requestCount += 1
        return MockFlightDataService.shared.searchFlights(query: parameters.flightNumber ?? "")
    }
    
    func getRandomFlight() async throws -> Flight? {
        // In a real implementation, this would make an API request
        // For demo purposes, we'll return mock data
        requestCount += 1
        return MockFlightDataService.shared.getRandomFlight()
    }
    
    // MARK: - Helper Methods
    
    private func makeRequest<T: Decodable>(endpoint: String, queryItems: [URLQueryItem]) async throws -> T {
        guard var components = URLComponents(string: baseURL + endpoint) else {
            throw NSError(domain: "com.debot.aviation", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var allQueryItems = queryItems
        allQueryItems.append(URLQueryItem(name: "api_key", value: apiKey))
        components.queryItems = allQueryItems
        
        guard let url = components.url else {
            throw NSError(domain: "com.debot.aviation", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL components"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, 
              (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "com.debot.aviation", code: 2, 
                          userInfo: [NSLocalizedDescriptionKey: "Server error or invalid response"])
        }
        
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NSError(domain: "com.debot.aviation", code: 3, 
                          userInfo: [NSLocalizedDescriptionKey: "Failed to decode response: \(error.localizedDescription)"])
        }
    }
} 
