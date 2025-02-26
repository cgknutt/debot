import Foundation
import SwiftUI

/// A simple in-memory cache for flight data to reduce API calls
class FlightCache {
    static let shared = FlightCache()
    
    private var flightSearchCache: [String: [Flight]] = [:]
    private var recentRandomFlights: [Flight] = []
    private let maxRandomFlightsToCache = 5
    private let cacheExpirationTime: TimeInterval = 300 // 5 minutes
    
    // Timestamps for cache expiration
    private var cacheTimestamps: [String: Date] = [:]
    private var randomFlightsTimestamp: Date?
    
    private init() {}
    
    // MARK: - Search Results Caching
    
    func getCachedFlights(for searchTerm: String) -> [Flight]? {
        let key = searchTerm.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check if we have cached data for this search term
        guard let cachedFlights = flightSearchCache[key],
              let timestamp = cacheTimestamps[key],
              !cachedFlights.isEmpty else {
            return nil
        }
        
        // Check if cache is still valid
        let now = Date()
        if now.timeIntervalSince(timestamp) > cacheExpirationTime {
            // Cache expired, remove it
            flightSearchCache.removeValue(forKey: key)
            cacheTimestamps.removeValue(forKey: key)
            return nil
        }
        
        return cachedFlights
    }
    
    func cacheFlights(_ flights: [Flight], for searchTerm: String) {
        let key = searchTerm.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        flightSearchCache[key] = flights
        cacheTimestamps[key] = Date()
    }
    
    // MARK: - Random Flight Caching
    
    func getRecentRandomFlight() -> Flight? {
        // Check if random flights cache has expired
        if let timestamp = randomFlightsTimestamp,
           Date().timeIntervalSince(timestamp) > cacheExpirationTime {
            recentRandomFlights.removeAll()
            randomFlightsTimestamp = nil
            return nil
        }
        
        // Return a random flight from the cache if available
        return recentRandomFlights.randomElement()
    }
    
    func addRecentRandomFlight(_ flight: Flight) {
        // If this is the first flight, set the timestamp
        if recentRandomFlights.isEmpty {
            randomFlightsTimestamp = Date()
        }
        
        // Add flight to cache if it's not already there
        if !recentRandomFlights.contains(where: { $0.id == flight.id }) {
            recentRandomFlights.append(flight)
            
            // Limit the cache size
            if recentRandomFlights.count > maxRandomFlightsToCache {
                recentRandomFlights.removeFirst()
            }
        }
    }
    
    // MARK: - Cache Management
    
    func clearCache() {
        flightSearchCache.removeAll()
        recentRandomFlights.removeAll()
        cacheTimestamps.removeAll()
        randomFlightsTimestamp = nil
    }
} 