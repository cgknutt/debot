import Foundation
import SwiftUI
import MapKit

// MARK: - Flight Map Data
/// Flight data for display on the map
public struct FlightMapData: Identifiable {
    public let id: String
    public let airline: String
    public let flightNumber: String
    public let departureAirport: String
    public let arrivalAirport: String
    public let latitude: Double
    public let longitude: Double
    public let altitude: Int
    public let speed: Int
    public let heading: Int
    
    public init(
        id: String,
        airline: String,
        flightNumber: String,
        departureAirport: String,
        arrivalAirport: String,
        latitude: Double,
        longitude: Double,
        altitude: Int,
        speed: Int,
        heading: Int
    ) {
        self.id = id
        self.airline = airline
        self.flightNumber = flightNumber
        self.departureAirport = departureAirport
        self.arrivalAirport = arrivalAirport
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.speed = speed
        self.heading = heading
    }
    
    // Helper to convert from Flight model
    public static func from(_ flight: Flight, latitude: Double, longitude: Double) -> FlightMapData {
        return FlightMapData(
            id: flight.id.uuidString,
            airline: flight.airline.name ?? "Unknown",
            flightNumber: flight.flightNumber,
            departureAirport: flight.departure.iata ?? "Unknown",
            arrivalAirport: flight.arrival.iata ?? "Unknown",
            latitude: latitude,
            longitude: longitude,
            altitude: Int(flight.altitude),
            speed: Int(flight.live?.speed_horizontal ?? 0),
            heading: Int(flight.live?.direction ?? 0)
        )
    }
    
    // Helper to convert from ViewFlight
    public static func from(_ flight: ViewFlight, latitude: Double, longitude: Double) -> FlightMapData {
        return FlightMapData(
            id: flight.id.uuidString,
            airline: flight.airline,
            flightNumber: flight.flightNumber,
            departureAirport: flight.departure,
            arrivalAirport: flight.arrival,
            latitude: latitude,
            longitude: longitude,
            altitude: Int(flight.altitude.replacingOccurrences(of: ",", with: "")) ?? 35000,
            speed: Int(flight.speed.replacingOccurrences(of: ",", with: "")) ?? 500,
            heading: 270 // Default heading since ViewFlight doesn't have this property
        )
    }
}

// MARK: - ViewFlight - For Display
/// ViewFlight model for display
public struct ViewFlight: Identifiable, Equatable {
    public let id = UUID()
    public let flightNumber: String
    public let departure: String
    public let departureCity: String
    public let arrival: String
    public let arrivalCity: String
    public let status: String
    public let altitude: String
    public let speed: String
    public let aircraft: String
    public let airline: String
    
    public init(
        airline: String,
        flightNumber: String,
        departure: String,
        arrival: String,
        status: String,
        altitude: String,
        speed: String,
        departureCity: String = "",
        arrivalCity: String = "",
        aircraft: String = "Unknown"
    ) {
        self.flightNumber = flightNumber
        self.departure = departure
        self.departureCity = departureCity
        self.arrival = arrival
        self.arrivalCity = arrivalCity
        self.status = status
        self.altitude = altitude
        self.speed = speed
        self.aircraft = aircraft
        self.airline = airline
    }
    
    public init(from aviationFlight: Flight) {
        self.flightNumber = aviationFlight.flight.number ?? "Unknown"
        self.departure = aviationFlight.departure.iata ?? "Unknown"
        self.departureCity = aviationFlight.departure.airport ?? "Unknown City"
        self.arrival = aviationFlight.arrival.iata ?? "Unknown"
        self.arrivalCity = aviationFlight.arrival.airport ?? "Unknown City"
        self.status = aviationFlight.flight_status ?? "Unknown"
        self.altitude = String(format: "%.0f", aviationFlight.live?.altitude ?? 0)
        self.speed = String(format: "%.0f", aviationFlight.live?.speed_horizontal ?? 0)
        self.aircraft = aviationFlight.aircraft?.registration ?? "Unknown"
        self.airline = aviationFlight.airline.name ?? "Unknown"
    }
    
    public static func == (lhs: ViewFlight, rhs: ViewFlight) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - SimplifiedFlight - For Accessibility
/// Simplified flight struct for accessibility
public struct AccessibleFlightInfo: Identifiable {
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

// MARK: - Theme Colors
/// ThemeColors for consistent appearance across the app
public struct ThemeColors {
    public let background: Color
    public let cardBackground: Color
    public let secondaryBackground: Color
    public let accent: Color
    public let text: Color
    public let secondaryText: Color
    public let divider: Color
    public let error: Color
    
    public init(
        background: Color,
        cardBackground: Color,
        secondaryBackground: Color,
        accent: Color,
        text: Color,
        secondaryText: Color,
        divider: Color,
        error: Color
    ) {
        self.background = background
        self.cardBackground = cardBackground
        self.secondaryBackground = secondaryBackground
        self.accent = accent
        self.text = text
        self.secondaryText = secondaryText
        self.divider = divider
        self.error = error
    }
    
    public static func colors(for colorScheme: ColorScheme) -> ThemeColors {
        switch colorScheme {
        case .dark:
            return ThemeColors(
                background: Color(UIColor.systemBackground),
                cardBackground: Color(UIColor.secondarySystemBackground),
                secondaryBackground: Color(UIColor.tertiarySystemBackground),
                accent: .debotOrange,
                text: Color(UIColor.label),
                secondaryText: Color(UIColor.secondaryLabel),
                divider: Color(UIColor.separator),
                error: Color(UIColor.systemRed)
            )
        case .light:
            return ThemeColors(
                background: Color(UIColor.systemBackground),
                cardBackground: Color(UIColor.secondarySystemBackground),
                secondaryBackground: Color(UIColor.tertiarySystemBackground),
                accent: .debotOrange,
                text: Color(UIColor.label),
                secondaryText: Color(UIColor.secondaryLabel),
                divider: Color(UIColor.separator),
                error: Color(UIColor.systemRed)
            )
        @unknown default:
            return .init(
                background: Color(UIColor.systemBackground),
                cardBackground: Color(UIColor.secondarySystemBackground),
                secondaryBackground: Color(UIColor.tertiarySystemBackground),
                accent: .debotOrange,
                text: Color(UIColor.label),
                secondaryText: Color(UIColor.secondaryLabel),
                divider: Color(UIColor.separator),
                error: Color(UIColor.systemRed)
            )
        }
    }
}

// MARK: - ThemeColors Environment Key
/// Environment key for theme colors
public struct ThemeColorsKey: EnvironmentKey {
    public static let defaultValue = ThemeColors.colors(for: .dark)
}

public extension EnvironmentValues {
    var themeColors: ThemeColors {
        get { self[ThemeColorsKey.self] }
        set { self[ThemeColorsKey.self] = newValue }
    }
}

// MARK: - BlurView for Glass Effects
/// UIKit blur view for SwiftUI integration
public struct BlurView: UIViewRepresentable {
    public let style: UIBlurEffect.Style
    
    public init(style: UIBlurEffect.Style) {
        self.style = style
    }
    
    public func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    
    public func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
} 