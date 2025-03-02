import Foundation
import SwiftUI
import CoreLocation

class WeatherViewModel: ObservableObject {
    // Published properties
    @Published var currentWeather: WeatherData?
    @Published var isLoading = false
    @Published var error: String?
    @Published var preferences = WeatherPreferences()
    @Published var searchQuery = ""
    @Published var searchResults: [String] = []
    @Published var isSearching = false
    @Published var useMockData = true // Default to mock data
    
    // Location manager
    private let locationManager = CLLocationManager()
    private var storage = UserDefaults.standard
    
    init() {
        // Load user preferences
        loadPreferences()
        
        // Check if we should use mock data
        self.useMockData = storage.bool(forKey: "weatherUseMockData")
        
        // Load weather for default location or current location
        loadWeather()
    }
    
    // MARK: - Public Methods
    
    func loadWeather() {
        Task {
            await loadWeatherData()
        }
    }
    
    func toggleMockData() {
        useMockData.toggle()
        storage.set(useMockData, forKey: "weatherUseMockData")
        loadWeather()
    }
    
    func updateLocation(_ location: String) {
        preferences.location = location
        savePreferences()
        loadWeather()
    }
    
    func search(query: String) {
        searchQuery = query
        
        if query.isEmpty {
            searchResults = []
            isSearching = false
            return
        }
        
        isSearching = true
        
        // In a real app, this would call a location search API
        // For now, we'll just filter from a predefined list
        let cities = [
            "New York", "Los Angeles", "Chicago", "Houston", "Phoenix",
            "Philadelphia", "San Antonio", "San Diego", "Dallas", "San Jose",
            "Austin", "Jacksonville", "Fort Worth", "Columbus", "San Francisco",
            "Charlotte", "Indianapolis", "Seattle", "Denver", "Washington",
            "Boston", "El Paso", "Nashville", "Detroit", "Oklahoma City",
            "Portland", "Las Vegas", "Memphis", "Louisville", "Baltimore",
            "Milwaukee", "Albuquerque", "Tucson", "Fresno", "Sacramento",
            "Mesa", "Kansas City", "Atlanta", "Long Beach", "Colorado Springs",
            "Raleigh", "Miami", "Omaha", "Minneapolis", "Tulsa",
            "Cleveland", "Wichita", "Arlington", "New Orleans", "Bakersfield",
            "Tampa", "Honolulu", "Aurora", "Anaheim", "Santa Ana",
            "St. Louis", "Riverside", "Corpus Christi", "Lexington", "Pittsburgh",
            "Anchorage", "Stockton", "Cincinnati", "St. Paul", "Toledo",
            "Greensboro", "Newark", "Plano", "Henderson", "Lincoln",
            "Buffalo", "Jersey City", "Chula Vista", "Fort Wayne", "Orlando",
            "St. Petersburg", "Chandler", "Laredo", "Norfolk", "Durham",
            "Madison", "Lubbock", "Irvine", "Winston-Salem", "Glendale",
            "Garland", "Hialeah", "Reno", "Chesapeake", "Gilbert",
            "Baton Rouge", "Irving", "Scottsdale", "North Las Vegas", "Fremont",
            "Boise", "Richmond", "San Bernardino", "Birmingham", "Spokane",
            "Rochester", "Des Moines", "Modesto", "Fayetteville", "Tacoma",
            "Oxnard", "Fontana", "Columbus", "Montgomery", "Moreno Valley",
            "Shreveport", "Aurora", "Yonkers", "Akron", "Huntington Beach",
            "Little Rock", "Augusta", "Amarillo", "Glendale", "Mobile",
            "Grand Rapids", "Salt Lake City", "Tallahassee", "Huntsville", "Grand Prairie",
            "Knoxville", "Worcester", "Newport News", "Brownsville", "Overland Park",
            "Santa Clarita", "Providence", "Garden Grove", "Chattanooga", "Oceanside",
            "Jackson", "Fort Lauderdale", "Santa Rosa", "Rancho Cucamonga", "Port St. Lucie",
            "Tempe", "Ontario", "Vancouver", "Cape Coral", "Sioux Falls",
            "Springfield", "Peoria", "Pembroke Pines", "Elk Grove", "Salem",
            "Lancaster", "Corona", "Eugene", "Palmdale", "Salinas",
            "Springfield", "Pasadena", "Fort Collins", "Hayward", "Pomona",
            "Cary", "Rockford", "Alexandria", "Escondido", "McKinney",
            "Kansas City", "Joliet", "Sunnyvale", "Torrance", "Bridgeport",
            "Lakewood", "Hollywood", "Paterson", "Naperville", "Syracuse",
            "Mesquite", "Dayton", "Savannah", "Clarksville", "Orange",
            "Pasadena", "Fullerton", "Killeen", "Frisco", "Hampton",
            "McAllen", "Warren", "Bellevue", "West Valley City", "Columbia",
            "Olathe", "Sterling Heights", "New Haven", "Miramar", "Waco",
            "Thousand Oaks", "Cedar Rapids", "Charleston", "Visalia", "Topeka",
            "Elizabeth", "Gainesville", "Thornton", "Roseville", "Carrollton",
            "Coral Springs", "Stamford", "Simi Valley", "Concord", "Hartford",
            "Kent", "Lafayette", "Midland", "Surprise", "Denton",
            "Victorville", "Evansville", "Santa Clara", "Abilene", "Athens",
            "Vallejo", "Allentown", "Norman", "Beaumont", "Independence",
            "Murfreesboro", "Ann Arbor", "Springfield", "Berkeley", "Peoria",
            "Provo", "El Monte", "Columbia", "Lansing", "Fargo",
            "Downey", "Costa Mesa", "Wilmington", "Arvada", "Inglewood",
            "Miami Gardens", "Carlsbad", "Westminster", "Rochester", "Odessa",
            "Manchester", "Elgin", "West Jordan", "Round Rock", "Clearwater",
            "Waterbury", "Gresham", "Fairfield", "Billings", "Lowell",
            "San Buenaventura (Ventura)", "Pueblo", "High Point", "West Covina", "Richmond",
            "Murrieta", "Cambridge", "Antioch", "Temecula", "Norwalk",
            "Centennial", "Everett", "Palm Bay", "Wichita Falls", "Green Bay",
            "Daly City", "Burbank", "Richardson", "Pompano Beach", "North Charleston",
            "Broken Arrow", "Boulder", "West Palm Beach", "Santa Maria", "El Cajon",
            "Davenport", "Rialto", "Las Cruces", "San Mateo", "Lewisville",
            "South Bend", "Lakeland", "Erie", "Tyler", "Pearland",
            "College Station", "Kenosha", "Sandy Springs", "Clovis", "Flint",
            "Roanoke", "Albany", "Jurupa Valley", "Compton", "San Angelo",
            "Hillsboro", "Lawton", "Renton", "Vista", "Davie",
            "Greeley", "Mission Viejo", "Portsmouth", "Dearborn", "South Gate",
            "Tuscaloosa", "Livonia", "New Bedford", "Vacaville", "Brockton",
            "Roswell", "Beaverton", "Quincy", "Sparks", "Yakima",
            "San Francisco", "London", "Paris", "Tokyo", "Sydney"
        ]
        
        searchResults = cities.filter { $0.lowercased().contains(query.lowercased()) }
        
        // Limit to 10 results
        if searchResults.count > 10 {
            searchResults = Array(searchResults.prefix(10))
        }
    }
    
    // MARK: - Private Methods
    
    private func loadWeatherData() async {
        isLoading = true
        error = nil
        
        // Determine which location to use
        let locationToUse = preferences.location
        
        if useMockData {
            // Use mock data
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.currentWeather = self.generateMockWeatherData(for: locationToUse ?? "San Francisco")
                self.isLoading = false
            }
        } else {
            // In a real app, this would call a weather API
            // For now, we'll just use mock data with a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.currentWeather = self.generateMockWeatherData(for: locationToUse ?? "San Francisco")
                self.isLoading = false
            }
        }
    }
    
    // Add this method to the WeatherViewModel class
    func refreshWeatherData() async {
        isLoading = true
        error = nil
        
        // In a real app, this would call an API
        let locationToUse = preferences.location
        
        if useMockData {
            // Simulate network delay
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            
            // Update on main thread
            await MainActor.run {
                self.currentWeather = self.generateMockWeatherData(for: locationToUse ?? "San Francisco")
                self.isLoading = false
            }
        } else {
            // In a real app, this would call a weather API
            // For now, we'll just use mock data with a delay
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            
            // Update on main thread
            await MainActor.run {
                self.currentWeather = self.generateMockWeatherData(for: locationToUse ?? "San Francisco")
                self.isLoading = false
            }
        }
    }
    
    private func loadPreferences() {
        if let location = storage.string(forKey: "weatherLocation") {
            preferences.location = location
        }
        
        if let unit = storage.string(forKey: "weatherUnit") {
            preferences.unit = WeatherUnit(rawValue: unit) ?? .celsius
        }
    }
    
    private func savePreferences() {
        storage.set(preferences.location, forKey: "weatherLocation")
        storage.set(preferences.unit.rawValue, forKey: "weatherUnit")
    }
    
    // MARK: - Mock Data Generation
    
    private func generateMockWeatherData(for location: String) -> WeatherData {
        let condition = WeatherCondition.allCases.randomElement() ?? .clear
        
        // Generate forecast for next 7 days
        var forecastDays: [ForecastDay] = []
        for i in 0..<7 {
            let date = Calendar.current.date(byAdding: .day, value: i, to: Date()) ?? Date()
            let forecastCondition = WeatherCondition.allCases.randomElement() ?? .clear
            
            forecastDays.append(ForecastDay(
                date: date,
                condition: forecastCondition,
                highTemp: Int.random(in: 15...35),
                lowTemp: Int.random(in: 5...15),
                precipitation: Int.random(in: 0...100)
            ))
        }
        
        return WeatherData(
            location: location,
            temperature: Int.random(in: 10...30),
            feelsLike: Int.random(in: 8...32),
            humidity: Int.random(in: 30...90),
            windSpeed: Double.random(in: 0.0...10.0),
            windDirection: Int.random(in: 0...359),
            pressure: Int.random(in: 980...1030),
            condition: condition,
            forecast: forecastDays,
            lastUpdated: Date()
        )
    }
} 