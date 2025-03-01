import Foundation

/// Provides mock flight data for testing and dev purposes
class MockFlightDataService {
    static let shared = MockFlightDataService()
    
    private init() {
        // Private initialization to enforce singleton pattern
    }
    
    // Sample airlines
    private let airlines = [
        Airline(name: "Delta Air Lines", iata: "DL", icao: "DAL"),
        Airline(name: "United Airlines", iata: "UA", icao: "UAL"),
        Airline(name: "American Airlines", iata: "AA", icao: "AAL"),
        Airline(name: "Southwest Airlines", iata: "WN", icao: "SWA"),
        Airline(name: "JetBlue Airways", iata: "B6", icao: "JBU"),
        Airline(name: "Alaska Airlines", iata: "AS", icao: "ASA"),
        Airline(name: "British Airways", iata: "BA", icao: "BAW"),
        Airline(name: "Lufthansa", iata: "LH", icao: "DLH"),
        Airline(name: "Air France", iata: "AF", icao: "AFR"),
        Airline(name: "Emirates", iata: "EK", icao: "UAE")
    ]
    
    // Sample airports
    private let airports = [
        "JFK": "New York JFK",
        "LAX": "Los Angeles Intl",
        "SFO": "San Francisco Intl",
        "ORD": "Chicago O'Hare",
        "ATL": "Atlanta Hartsfield",
        "DFW": "Dallas/Fort Worth",
        "MIA": "Miami Intl",
        "SEA": "Seattle-Tacoma",
        "LHR": "London Heathrow",
        "CDG": "Paris Charles de Gaulle",
        "FRA": "Frankfurt Intl",
        "AMS": "Amsterdam Schiphol",
        "DXB": "Dubai Intl",
        "HKG": "Hong Kong Intl",
        "NRT": "Tokyo Narita"
    ]
    
    // Generate a flight number for an airline
    private func generateFlightNumber(airline: Airline) -> FlightNumber {
        let number = String(Int.random(in: 100...9999))
        return FlightNumber(
            iata: "\(airline.iata ?? "")\(number)",
            icao: "\(airline.icao ?? "")\(number)",
            number: number
        )
    }
    
    // Generate a random airport pair (departure and arrival)
    private func generateAirportPair() -> (departure: String, arrival: String) {
        let allCodes = Array(airports.keys)
        let depIndex = Int.random(in: 0..<allCodes.count)
        var arrIndex = Int.random(in: 0..<allCodes.count)
        
        // Make sure departure and arrival are different
        while depIndex == arrIndex {
            arrIndex = Int.random(in: 0..<allCodes.count)
        }
        
        return (departure: allCodes[depIndex], arrival: allCodes[arrIndex])
    }
    
    // Generate a random timestamp within the next 24 hours
    private func generateTimestamp() -> String {
        let randomHours = Double.random(in: 0...24)
        let date = Date().addingTimeInterval(randomHours * 3600)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.string(from: date)
    }
    
    // Generate locations for departure and arrival
    private func generateLocations() -> (departure: FlightLocation, arrival: FlightLocation) {
        let airportPair = generateAirportPair()
        
        let departureTime = generateTimestamp()
        
        // Fix: Properly create and format dates to avoid the crash
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        
        // Generate arrival time 1-12 hours after departure
        let departureDate = formatter.date(from: departureTime) ?? Date()
        let arrivalDate = departureDate.addingTimeInterval(Double.random(in: 3600...43200))
        let arrivalTime = formatter.string(from: arrivalDate)
        
        let departure = FlightLocation(
            airport: airports[airportPair.departure],
            timezone: "UTC",
            iata: airportPair.departure,
            icao: "K\(airportPair.departure)",
            terminal: ["A", "B", "C", "D", "E", "F"].randomElement(),
            gate: "\(["A", "B", "C", "D"].randomElement() ?? "")\(Int.random(in: 1...50))",
            scheduled: departureTime,
            estimated: departureTime,
            actual: nil,
            latitude: "\(Double.random(in: -90...90))",
            longitude: "\(Double.random(in: -180...180))"
        )
        
        let arrival = FlightLocation(
            airport: airports[airportPair.arrival],
            timezone: "UTC",
            iata: airportPair.arrival,
            icao: "K\(airportPair.arrival)",
            terminal: ["1", "2", "3", "4", "5", "International"].randomElement(),
            gate: "\(Int.random(in: 1...99))\(["A", "B", "C", "D"].randomElement() ?? "")",
            scheduled: arrivalTime,
            estimated: arrivalTime,
            actual: nil,
            latitude: "\(Double.random(in: -90...90))",
            longitude: "\(Double.random(in: -180...180))"
        )
        
        return (departure: departure, arrival: arrival)
    }
    
    // Generate random live flight data
    private func generateLiveData() -> LiveData {
        return LiveData(
            updated: Date().ISO8601Format(),
            latitude: Double.random(in: -90...90),
            longitude: Double.random(in: -180...180),
            altitude: Double.random(in: 25000...40000),
            direction: Double.random(in: 0...359),
            speed_horizontal: Double.random(in: 400...550),
            speed_vertical: Double.random(in: -10...10),
            is_ground: false
        )
    }
    
    // Generate a single random flight
    func getRandomFlight() -> Flight? {
        let airline = airlines.randomElement()!
        let locations = generateLocations()
        let flightNumber = generateFlightNumber(airline: airline)
        
        return Flight(
            flight_date: Date().ISO8601Format(),
            flight_status: ["scheduled", "active", "landed", "delayed"].randomElement(),
            departure: locations.departure,
            arrival: locations.arrival,
            airline: airline,
            flight: flightNumber,
            aircraft: Aircraft(
                registration: "N\(Int.random(in: 100...999))\(["WN", "UA", "AA", "DL"].randomElement() ?? "")",
                iata: ["B738", "A320", "B77W", "A388"].randomElement(),
                icao: ["B738", "A320", "B77W", "A388"].randomElement(),
                icao24: nil
            ),
            live: Bool.random() ? generateLiveData() : nil
        )
    }
    
    // Search flights based on a query (simplified)
    func searchFlights(query: String) -> [Flight] {
        var results: [Flight] = []
        
        // Generate a random number of flights (1-10)
        let flightCount = Int.random(in: 1...10)
        
        for _ in 0..<flightCount {
            if let flight = getRandomFlight() {
                results.append(flight)
            }
        }
        
        return results
    }
} 