import Foundation

class AviationService {
    private let baseURL = "https://api.aviationstack.com/v1"
    private let apiKey = "21cb578c508633a97e677a749d2f38e3"
    
    enum AviationError: Error {
        case invalidURL
        case noData
        case decodingError
        case apiError(String)
    }
    
    struct FlightResponse: Codable {
        let pagination: Pagination
        let data: [Flight]
    }
    
    struct Pagination: Codable {
        let limit: Int
        let offset: Int
        let count: Int
        let total: Int
    }
    
    struct Flight: Codable, Identifiable {
        let id = UUID()
        let flight_date: String?
        let flight_status: String?
        let departure: FlightLocation
        let arrival: FlightLocation
        let airline: Airline
        let flight: FlightDetails
        let aircraft: Aircraft?
        let live: LiveFlightData?
    }
    
    struct FlightLocation: Codable {
        let airport: String?
        let timezone: String?
        let iata: String?
        let icao: String?
        let terminal: String?
        let gate: String?
        let scheduled: String?
        let estimated: String?
        let actual: String?
        let runway: String?
    }
    
    struct Airline: Codable {
        let name: String?
        let iata: String?
        let icao: String?
    }
    
    struct FlightDetails: Codable {
        let number: String?
        let iata: String?
        let icao: String?
    }
    
    struct Aircraft: Codable {
        let registration: String?
        let iata: String?
        let icao: String?
        let icao24: String?
    }
    
    struct LiveFlightData: Codable {
        let latitude: Double?
        let longitude: Double?
        let altitude: Double?
        let direction: Double?
        let speed_horizontal: Double?
        let speed_vertical: Double?
    }
    
    func getRandomFlight() async throws -> Flight {
        var components = URLComponents(string: "\(baseURL)/flights")
        components?.queryItems = [
            URLQueryItem(name: "access_key", value: apiKey),
            URLQueryItem(name: "limit", value: "100")
        ]
        
        guard let url = components?.url else {
            throw AviationError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AviationError.apiError("Invalid response type")
        }
        
        // Print response for debugging
        print("API Response Status Code: \(httpResponse.statusCode)")
        print("API Response Headers: \(httpResponse.allHeaderFields)")
        
        // Print response data for debugging
        if let responseString = String(data: data, encoding: .utf8) {
            print("API Response Data: \(responseString)")
        }
        
        guard httpResponse.statusCode == 200 else {
            // Try to parse error message if available
            if let errorResponse = try? JSONDecoder().decode([String: String].self, from: data),
               let errorMessage = errorResponse["error"] {
                throw AviationError.apiError(errorMessage)
            }
            throw AviationError.apiError("HTTP Error: \(httpResponse.statusCode)")
        }
        
        let decoder = JSONDecoder()
        do {
            let flightResponse = try decoder.decode(FlightResponse.self, from: data)
            guard !flightResponse.data.isEmpty else {
                throw AviationError.noData
            }
            
            // Get a random flight from the response
            let randomIndex = Int.random(in: 0..<flightResponse.data.count)
            return flightResponse.data[randomIndex]
        } catch {
            print("Decoding Error: \(error)")
            throw AviationError.decodingError
        }
    }
} 