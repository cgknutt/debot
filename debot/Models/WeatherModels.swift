import Foundation
import SwiftUI

// Weather condition
enum WeatherCondition: String, Codable {
    case clear = "clear"
    case partlyCloudy = "partly-cloudy"
    case cloudy = "cloudy"
    case overcast = "overcast"
    case rain = "rain"
    case snow = "snow"
    case thunderstorm = "thunderstorm"
    case fog = "fog"
    case unknown = "unknown"
    
    var icon: String {
        switch self {
        case .clear: return "sun.max.fill"
        case .partlyCloudy: return "cloud.sun.fill"
        case .cloudy: return "cloud.fill"
        case .overcast: return "smoke.fill"
        case .rain: return "cloud.rain.fill"
        case .snow: return "cloud.snow.fill"
        case .thunderstorm: return "cloud.bolt.fill"
        case .fog: return "cloud.fog.fill"
        case .unknown: return "questionmark"
        }
    }
    
    var description: String {
        switch self {
        case .clear: return "Clear skies"
        case .partlyCloudy: return "Partly cloudy"
        case .cloudy: return "Cloudy"
        case .overcast: return "Overcast"
        case .rain: return "Rain"
        case .snow: return "Snow"
        case .thunderstorm: return "Thunderstorm"
        case .fog: return "Foggy"
        case .unknown: return "Unknown weather"
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .clear: return Color.blue
        case .partlyCloudy: return Color.blue.opacity(0.8)
        case .cloudy, .overcast: return Color.gray
        case .rain: return Color.blue.opacity(0.6)
        case .snow: return Color(white: 0.9)
        case .thunderstorm: return Color.purple.opacity(0.7)
        case .fog: return Color.gray.opacity(0.7)
        case .unknown: return Color.gray
        }
    }
    
    var textColor: Color {
        switch self {
        case .snow: return .black
        default: return .white
        }
    }
}

// Weather Data Model
struct WeatherData: Identifiable, Codable {
    let id = UUID()
    var location: String
    var temperature: Double // in Celsius
    var feelsLike: Double
    var humidity: Int // percentage
    var windSpeed: Double // in m/s
    var windDirection: Int // in degrees
    var pressure: Int // in hPa
    var condition: WeatherCondition
    var forecast: [ForecastDay]
    var lastUpdated: Date
    
    // Temperature formatting functions
    func formatTemperature(unit: TemperatureUnit = .celsius) -> String {
        switch unit {
        case .celsius:
            return String(format: "%.1f°C", temperature)
        case .fahrenheit:
            return String(format: "%.1f°F", temperature * 9/5 + 32)
        }
    }
    
    // Wind speed formatting functions
    func formatWindSpeed(unit: SpeedUnit = .metersPerSecond) -> String {
        switch unit {
        case .metersPerSecond:
            return String(format: "%.1f m/s", windSpeed)
        case .kilometersPerHour:
            return String(format: "%.1f km/h", windSpeed * 3.6)
        case .milesPerHour:
            return String(format: "%.1f mph", windSpeed * 2.237)
        }
    }
    
    // Wind direction as compass direction
    var windCompassDirection: String {
        let directions = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE", "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"]
        let index = Int((Double(windDirection) / 22.5) + 0.5) % 16
        return directions[index]
    }
}

// Forecast day model
struct ForecastDay: Identifiable, Codable {
    let id = UUID()
    var date: Date
    var minTemp: Double
    var maxTemp: Double
    var condition: WeatherCondition
    var precipitation: Double // in mm
    var precipitationProbability: Int // percentage
    
    // Formatted date
    var dateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E, MMM d"
        return formatter.string(from: date)
    }
    
    // Temperature range
    func formatTemperatureRange(unit: TemperatureUnit = .celsius) -> String {
        switch unit {
        case .celsius:
            return String(format: "%.0f° / %.0f°", minTemp, maxTemp)
        case .fahrenheit:
            return String(format: "%.0f° / %.0f°", minTemp * 9/5 + 32, maxTemp * 9/5 + 32)
        }
    }
}

// User preference enums
enum TemperatureUnit: String, Codable {
    case celsius = "celsius"
    case fahrenheit = "fahrenheit"
}

enum SpeedUnit: String, Codable {
    case metersPerSecond = "m/s"
    case kilometersPerHour = "km/h"
    case milesPerHour = "mph"
}

// User preferences for weather
struct WeatherPreferences: Codable {
    var temperatureUnit: TemperatureUnit = .celsius
    var speedUnit: SpeedUnit = .metersPerSecond
    var savedLocations: [String] = []
    var defaultLocation: String? = nil
} 