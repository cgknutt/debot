import Foundation
import SwiftUI

/// Flight model used throughout the application
public struct Flight: Codable, Identifiable {
    // UUID is not naturally Codable, so we need to handle it specially
    public var id: UUID = UUID()
    public var flight_date: String?
    public var flight_status: String?
    public var departure: FlightLocation
    public var arrival: FlightLocation
    public var airline: Airline
    public var flight: FlightNumber
    public var aircraft: Aircraft?
    public var live: LiveData?
    
    // Custom coding keys to exclude id from JSON
    private enum CodingKeys: String, CodingKey {
        case flight_date, flight_status, departure, arrival, airline, flight, aircraft, live
    }
    
    public init(
        flight_date: String?,
        flight_status: String?,
        departure: FlightLocation,
        arrival: FlightLocation,
        airline: Airline,
        flight: FlightNumber,
        aircraft: Aircraft? = nil,
        live: LiveData? = nil
    ) {
        self.flight_date = flight_date
        self.flight_status = flight_status
        self.departure = departure
        self.arrival = arrival
        self.airline = airline
        self.flight = flight
        self.aircraft = aircraft
        self.live = live
    }
    
    // Computed properties for convenience
    public var flightNumber: String {
        return flight.iata ?? flight.icao ?? flight.number ?? "Unknown"
    }
    
    public var status: String {
        return flight_status?.capitalized ?? "Unknown"
    }
    
    public var altitude: Double {
        return live?.altitude ?? 0
    }
    
    // Helper method for accessibility
    public func toSimplifiedFlight() -> SimplifiedFlight {
        return SimplifiedFlight(
            flightNumber: flightNumber,
            departure: departure.iata ?? "Unknown",
            arrival: arrival.iata ?? "Unknown",
            status: status,
            altitude: String(format: "%.0f", altitude)
        )
    }
    
    // Helper method to convert to ViewFlight
    public func toViewFlight() -> ViewFlight {
        return ViewFlight(
            airline: airline.name ?? "Unknown",
            flightNumber: flightNumber,
            departure: departure.iata ?? "Unknown",
            arrival: arrival.iata ?? "Unknown",
            status: flight_status ?? "Unknown",
            altitude: String(format: "%.0f", altitude) + " ft",
            speed: String(format: "%.0f", live?.speed_horizontal ?? 0) + " mph",
            departureCity: departure.airport ?? "",
            arrivalCity: arrival.airport ?? "",
            aircraft: aircraft?.registration ?? "Unknown"
        )
    }
}

// Accessible SimplifiedFlight struct
public struct SimplifiedFlight: Identifiable {
    public let id = UUID()
    public let flightNumber: String
    public let departure: String
    public let arrival: String
    public let status: String
    public let altitude: String
    
    public init(flightNumber: String, departure: String, arrival: String, status: String, altitude: String) {
        self.flightNumber = flightNumber
        self.departure = departure
        self.arrival = arrival
        self.status = status
        self.altitude = altitude
    }
}

// Renamed from Airport to FlightLocation for compatibility
public struct FlightLocation: Codable {
    public var airport: String?
    public var timezone: String?
    public var iata: String?
    public var icao: String?
    public var terminal: String?
    public var gate: String?
    public var scheduled: String?
    public var estimated: String?
    public var actual: String?
    public var latitude: String?
    public var longitude: String?
    
    public init(
        airport: String?,
        timezone: String?,
        iata: String?,
        icao: String?,
        terminal: String?,
        gate: String?,
        scheduled: String?,
        estimated: String?,
        actual: String?,
        latitude: String?,
        longitude: String?
    ) {
        self.airport = airport
        self.timezone = timezone
        self.iata = iata
        self.icao = icao
        self.terminal = terminal
        self.gate = gate
        self.scheduled = scheduled
        self.estimated = estimated
        self.actual = actual
        self.latitude = latitude
        self.longitude = longitude
    }
}

public struct Airline: Codable {
    public var name: String?
    public var iata: String?
    public var icao: String?
    
    public init(name: String?, iata: String?, icao: String?) {
        self.name = name
        self.iata = iata
        self.icao = icao
    }
}

public struct FlightNumber: Codable {
    public var iata: String?
    public var icao: String?
    public var number: String?
    
    public init(iata: String?, icao: String?, number: String?) {
        self.iata = iata
        self.icao = icao
        self.number = number
    }
}

public struct Aircraft: Codable {
    public var registration: String?
    public var iata: String?
    public var icao: String?
    public var icao24: String?
    
    public init(registration: String?, iata: String?, icao: String?, icao24: String?) {
        self.registration = registration
        self.iata = iata
        self.icao = icao
        self.icao24 = icao24
    }
}

public struct LiveData: Codable {
    public var updated: String?
    public var latitude: Double?
    public var longitude: Double?
    public var altitude: Double?
    public var direction: Double?
    public var speed_horizontal: Double?
    public var speed_vertical: Double?
    public var is_ground: Bool?
    
    public init(
        updated: String?,
        latitude: Double?,
        longitude: Double?,
        altitude: Double?,
        direction: Double?,
        speed_horizontal: Double?,
        speed_vertical: Double?,
        is_ground: Bool?
    ) {
        self.updated = updated
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.direction = direction
        self.speed_horizontal = speed_horizontal
        self.speed_vertical = speed_vertical
        self.is_ground = is_ground
    }
} 