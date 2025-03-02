import SwiftUI

struct WeatherView: View {
    @ObservedObject var viewModel: WeatherViewModel
    @Environment(\.themeColors) private var themeColors
    
    @State private var showingSearch = false
    @State private var showingSettings = false
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Weather")
                        .font(.headline)
                    
                    Spacer()
                    
                    Button {
                        showingSearch = true
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(themeColors.text)
                            .padding(8)
                            .background(themeColors.cardBackground)
                            .clipShape(Circle())
                    }
                    .sheet(isPresented: $showingSearch) {
                        WeatherSearchView(viewModel: viewModel)
                    }
                    
                    Button {
                        // Refresh weather
                        viewModel.loadWeather()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(themeColors.text)
                            .padding(8)
                            .background(themeColors.cardBackground)
                            .clipShape(Circle())
                    }
                    
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gear")
                            .foregroundColor(themeColors.text)
                            .padding(8)
                            .background(themeColors.cardBackground)
                            .clipShape(Circle())
                    }
                    .sheet(isPresented: $showingSettings) {
                        WeatherSettingsView(viewModel: viewModel)
                    }
                }
                .padding()
                .background(themeColors.cardBackground)
                
                if viewModel.isLoading {
                    // Loading indicator
                    Spacer()
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Loading weather data...")
                        .font(.subheadline)
                        .foregroundColor(themeColors.secondaryText)
                        .padding()
                    Spacer()
                } else if let error = viewModel.error {
                    // Error view
                    Spacer()
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50))
                        .foregroundColor(.orange)
                        .padding()
                    Text("Error loading weather")
                        .font(.headline)
                    Text(error)
                        .font(.subheadline)
                        .foregroundColor(themeColors.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button("Try Again") {
                        viewModel.loadWeather()
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .padding()
                    
                    Spacer()
                } else if let weather = viewModel.currentWeather {
                    // Weather content
                    ScrollView {
                        VStack(spacing: 16) {
                            // Current weather card
                            ZStack {
                                // Background
                                Rectangle()
                                    .fill(weather.condition.backgroundColor)
                                    .cornerRadius(16)
                                
                                // Content
                                VStack {
                                    // Location
                                    Text(weather.location)
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(weather.condition.textColor)
                                    
                                    // Date
                                    Text(formatDate(weather.lastUpdated))
                                        .font(.subheadline)
                                        .foregroundColor(weather.condition.textColor.opacity(0.8))
                                        .padding(.bottom, 8)
                                    
                                    // Temperature and condition
                                    HStack(alignment: .center, spacing: 20) {
                                        // Weather icon
                                        Image(systemName: weather.condition.icon)
                                            .font(.system(size: 80))
                                            .foregroundColor(weather.condition.textColor)
                                            .frame(width: 80, height: 80)
                                        
                                        VStack(alignment: .leading) {
                                            // Temperature
                                            Text(weather.formatTemperature(unit: viewModel.preferences.temperatureUnit))
                                                .font(.system(size: 42, weight: .semibold))
                                                .foregroundColor(weather.condition.textColor)
                                            
                                            // Condition description
                                            Text(weather.condition.description)
                                                .font(.title3)
                                                .foregroundColor(weather.condition.textColor)
                                            
                                            // Feels like
                                            Text("Feels like \(formatTemperature(weather.feelsLike, unit: viewModel.preferences.temperatureUnit))")
                                                .font(.callout)
                                                .foregroundColor(weather.condition.textColor.opacity(0.8))
                                        }
                                    }
                                    .padding(.bottom, 16)
                                    
                                    // Weather details
                                    HStack(spacing: 32) {
                                        // Humidity
                                        WeatherDetailItem(
                                            icon: "humidity",
                                            value: "\(weather.humidity)%",
                                            label: "Humidity",
                                            foregroundColor: weather.condition.textColor
                                        )
                                        
                                        // Wind
                                        WeatherDetailItem(
                                            icon: "wind",
                                            value: weather.formatWindSpeed(unit: viewModel.preferences.speedUnit),
                                            label: weather.windCompassDirection,
                                            foregroundColor: weather.condition.textColor
                                        )
                                        
                                        // Pressure
                                        WeatherDetailItem(
                                            icon: "gauge",
                                            value: "\(weather.pressure) hPa",
                                            label: "Pressure",
                                            foregroundColor: weather.condition.textColor
                                        )
                                    }
                                }
                                .padding()
                            }
                            .frame(height: 280)
                            .padding(.horizontal)
                            
                            // Forecast section
                            VStack(alignment: .leading) {
                                Text("7-Day Forecast")
                                    .font(.headline)
                                    .padding(.horizontal)
                                    .padding(.top, 8)
                                
                                Divider()
                                    .padding(.horizontal)
                                
                                ForEach(weather.forecast) { day in
                                    ForecastDayRow(
                                        day: day,
                                        temperatureUnit: viewModel.preferences.temperatureUnit
                                    )
                                    
                                    if day.id != weather.forecast.last?.id {
                                        Divider()
                                            .padding(.horizontal)
                                    }
                                }
                            }
                            .background(themeColors.cardBackground)
                            .cornerRadius(16)
                            .padding(.horizontal)
                            
                            // Saved locations
                            if !viewModel.preferences.savedLocations.isEmpty {
                                VStack(alignment: .leading) {
                                    Text("Saved Locations")
                                        .font(.headline)
                                        .padding(.horizontal)
                                        .padding(.top, 8)
                                    
                                    Divider()
                                        .padding(.horizontal)
                                    
                                    ForEach(viewModel.preferences.savedLocations, id: \.self) { location in
                                        Button {
                                            // Load weather for this location
                                            viewModel.loadWeather(location: location)
                                        } label: {
                                            HStack {
                                                Text(location)
                                                    .foregroundColor(themeColors.text)
                                                
                                                Spacer()
                                                
                                                if viewModel.preferences.defaultLocation == location {
                                                    Text("Default")
                                                        .font(.caption)
                                                        .foregroundColor(.blue)
                                                        .padding(.horizontal, 8)
                                                        .padding(.vertical, 4)
                                                        .background(Color.blue.opacity(0.2))
                                                        .cornerRadius(8)
                                                }
                                                
                                                Image(systemName: "chevron.right")
                                                    .font(.caption)
                                                    .foregroundColor(themeColors.secondaryText)
                                            }
                                            .padding(.horizontal)
                                            .padding(.vertical, 12)
                                        }
                                        
                                        if location != viewModel.preferences.savedLocations.last {
                                            Divider()
                                                .padding(.horizontal)
                                        }
                                    }
                                }
                                .background(themeColors.cardBackground)
                                .cornerRadius(16)
                                .padding(.horizontal)
                            }
                            
                            // Last updated
                            Text("Last updated: \(formatTime(weather.lastUpdated))")
                                .font(.caption)
                                .foregroundColor(themeColors.secondaryText)
                                .padding(.top, 16)
                            
                            // Padding at bottom
                            Spacer(minLength: 32)
                        }
                        .padding(.vertical)
                    }
                } else {
                    // No weather loaded yet
                    Spacer()
                    Image(systemName: "cloud.sun")
                        .font(.system(size: 70))
                        .foregroundColor(themeColors.secondaryText)
                        .padding()
                    Text("No weather data")
                        .font(.headline)
                    
                    Button("Load Weather") {
                        viewModel.loadWeather()
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .padding()
                    
                    Spacer()
                }
            }
        }
    }
    
    // Format date
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: date)
    }
    
    // Format time
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
    
    // Format temperature based on unit preference
    private func formatTemperature(_ temperature: Double, unit: TemperatureUnit) -> String {
        switch unit {
        case .celsius:
            return String(format: "%.1f°C", temperature)
        case .fahrenheit:
            return String(format: "%.1f°F", temperature * 9/5 + 32)
        }
    }
}

// Weather detail item
struct WeatherDetailItem: View {
    let icon: String
    let value: String
    let label: String
    let foregroundColor: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(foregroundColor)
            
            Text(value)
                .font(.callout)
                .fontWeight(.semibold)
                .foregroundColor(foregroundColor)
            
            Text(label)
                .font(.caption)
                .foregroundColor(foregroundColor.opacity(0.8))
        }
    }
}

// Forecast day row
struct ForecastDayRow: View {
    let day: ForecastDay
    let temperatureUnit: TemperatureUnit
    @Environment(\.themeColors) private var themeColors
    
    var body: some View {
        HStack {
            // Day
            Text(day.dateFormatted)
                .frame(width: 100, alignment: .leading)
            
            // Condition icon
            Image(systemName: day.condition.icon)
                .foregroundColor(iconColor)
                .frame(width: 30)
            
            // Condition
            Text(day.condition.description)
                .foregroundColor(themeColors.text)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Precipitation
            if day.precipitationProbability > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "drop.fill")
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    Text("\(day.precipitationProbability)%")
                        .font(.caption)
                        .foregroundColor(themeColors.secondaryText)
                }
                .frame(width: 60)
            } else {
                Spacer()
                    .frame(width: 60)
            }
            
            // Temperature range
            Text(day.formatTemperatureRange(unit: temperatureUnit))
                .frame(width: 80, alignment: .trailing)
        }
        .padding(.vertical, 12)
        .padding(.horizontal)
    }
    
    var iconColor: Color {
        switch day.condition {
        case .clear: return .yellow
        case .partlyCloudy: return .yellow
        case .cloudy, .overcast: return .gray
        case .rain: return .blue
        case .snow: return .cyan
        case .thunderstorm: return .purple
        case .fog: return .gray
        case .unknown: return .gray
        }
    }
}

// Weather Search View
struct WeatherSearchView: View {
    @ObservedObject var viewModel: WeatherViewModel
    @Environment(\.themeColors) private var themeColors
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                // Search field
                TextField("Search for a city", text: $viewModel.searchQuery)
                    .padding(12)
                    .background(themeColors.cardBackground)
                    .cornerRadius(8)
                    .padding()
                    .onSubmit {
                        viewModel.searchLocations(query: viewModel.searchQuery)
                    }
                
                if viewModel.isSearching {
                    Spacer()
                    ProgressView()
                    Text("Searching...")
                        .foregroundColor(themeColors.secondaryText)
                        .padding()
                    Spacer()
                } else if viewModel.searchResults.isEmpty && !viewModel.searchQuery.isEmpty {
                    Spacer()
                    Text("No results found")
                        .foregroundColor(themeColors.secondaryText)
                    Spacer()
                } else {
                    List {
                        ForEach(viewModel.searchResults, id: \.self) { location in
                            Button {
                                // Load weather for selected location
                                viewModel.loadWeather(location: location)
                                dismiss()
                            } label: {
                                HStack {
                                    Text(location)
                                        .foregroundColor(themeColors.text)
                                    
                                    Spacer()
                                    
                                    if viewModel.preferences.savedLocations.contains(location) {
                                        Image(systemName: "bookmark.fill")
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Search Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                // Pre-populate with popular cities if query is empty
                if viewModel.searchQuery.isEmpty {
                    viewModel.searchQuery = ""
                    viewModel.searchLocations(query: "")
                }
            }
        }
    }
}

// Weather Settings View
struct WeatherSettingsView: View {
    @ObservedObject var viewModel: WeatherViewModel
    @Environment(\.themeColors) private var themeColors
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Units")) {
                    Picker("Temperature", selection: $viewModel.preferences.temperatureUnit) {
                        Text("Celsius (°C)").tag(TemperatureUnit.celsius)
                        Text("Fahrenheit (°F)").tag(TemperatureUnit.fahrenheit)
                    }
                    
                    Picker("Wind Speed", selection: $viewModel.preferences.speedUnit) {
                        Text("m/s").tag(SpeedUnit.metersPerSecond)
                        Text("km/h").tag(SpeedUnit.kilometersPerHour)
                        Text("mph").tag(SpeedUnit.milesPerHour)
                    }
                }
                
                Section(header: Text("Saved Locations")) {
                    ForEach(viewModel.preferences.savedLocations, id: \.self) { location in
                        HStack {
                            Text(location)
                            
                            Spacer()
                            
                            if viewModel.preferences.defaultLocation == location {
                                Text("Default")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                            
                            Button {
                                // Set as default
                                viewModel.setDefaultLocation(location)
                            } label: {
                                Image(systemName: "star\(viewModel.preferences.defaultLocation == location ? ".fill" : "")")
                                    .foregroundColor(.blue)
                            }
                            
                            Button {
                                // Remove location
                                viewModel.removeLocation(location)
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    
                    if viewModel.preferences.savedLocations.isEmpty {
                        Text("No saved locations")
                            .foregroundColor(themeColors.secondaryText)
                    }
                }
                
                Section(header: Text("Data Source")) {
                    Toggle("Use Mock Data", isOn: $viewModel.useMockData)
                        .onChange(of: viewModel.useMockData) { newValue in
                            // Save the setting
                            UserDefaults.standard.set(newValue, forKey: "weatherUseMockData")
                            
                            // Reload data
                            viewModel.loadWeather()
                        }
                }
            }
            .navigationTitle("Weather Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        // Save preferences
                        viewModel.savePreferences()
                        dismiss()
                    }
                }
            }
        }
    }
}

struct WeatherView_Previews: PreviewProvider {
    static var previews: some View {
        WeatherView(viewModel: WeatherViewModel())
    }
} 