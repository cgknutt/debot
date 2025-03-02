import SwiftUI

struct RandomFlightView: View {
    @StateObject private var viewModel = AviationViewModel()
    @State private var selectedFlightMapData: FlightMapData? = nil
    
    var body: some View {
        VStack(spacing: 20) {
            Button(action: {
                viewModel.fetchRandomFlight()
                // Reset selection when fetching new flight
                selectedFlightMapData = nil
                
                // Debug: Print when fetching a new flight
                print("🔍 Fetching new random flight")
            }) {
                Text("Get Random Flight")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
            } else if let error = viewModel.error {
                Text(error)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding()
            } else if let flight = viewModel.currentFlight {
                ScrollView {
                    VStack(alignment: .leading, spacing: 15) {
                        // Add flight map when coordinates are available
                        if let latitude = flight.live?.latitude, 
                           let longitude = flight.live?.longitude {
                            let flightMapData = FlightMapData(
                                id: UUID().uuidString,
                                airline: flight.airline.name ?? "Unknown",
                                flightNumber: flight.flight.number ?? "Unknown",
                                departureAirport: flight.departure.airport ?? "Unknown",
                                arrivalAirport: flight.arrival.airport ?? "Unknown",
                                latitude: latitude,
                                longitude: longitude,
                                altitude: Int(flight.live?.altitude ?? 0),
                                speed: Int(flight.live?.speed_horizontal ?? 0),
                                heading: Int(flight.live?.direction ?? 0)
                            )
                            
                            VStack {
                                // Add a title to make the map section more visible
                                Text("Flight Map")
                                    .font(.headline)
                                    .padding(.top, 8)
                                    .padding(.bottom, 4)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                
                                FlightMapView(flights: [flightMapData], selectedFlight: $selectedFlightMapData)
                                    .frame(height: 300)
                                    .cornerRadius(10)
                                    .border(Color.gray, width: 1) // Add a border to see if the view is rendering
                                    .onAppear {
                                        print("🔄 FlightMapView appeared")
                                        // Auto-select it on first load if none is selected
                                        if selectedFlightMapData == nil {
                                            print("🔄 Auto-selecting flight")
                                            Task {
                                                await selectFlight(flightMapData)
                                            }
                                        }
                                    }
                                
                                // Instruction label
                                Text("Tap the airplane icon to select")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.top, 4)
                                
                                // Show detailed info when flight is selected on map
                                if selectedFlightMapData != nil {
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text("Live Position:")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            Text("Latitude: \(String(format: "%.4f", latitude))°")
                                            Text("Longitude: \(String(format: "%.4f", longitude))°")
                                        }
                                        
                                        Spacer()
                                        
                                        VStack(alignment: .trailing) {
                                            Text("Flight Data:")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            Text("Speed: \(Int(flight.live?.speed_horizontal ?? 0)) km/h")
                                            Text("Altitude: \(Int(flight.live?.altitude ?? 0)) ft")
                                        }
                                    }
                                    .padding()
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(10)
                                    .padding(.top, 4)
                                }
                            }
                            .padding(.bottom)
                        } else {
                            VStack {
                                Text("Flight Map Data Not Available")
                                    .font(.headline)
                                    .foregroundColor(.orange)
                                    .padding(.vertical, 8)
                                
                                Text("This flight doesn't have live tracking data.\nThe API didn't return coordinates for this flight.")
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(.secondary)
                                    .padding()
                                    .background(Color.orange.opacity(0.1))
                                    .cornerRadius(10)
                                    .padding(.horizontal)
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                        }
                        
                        FlightInfoSection(title: "Airline", content: flight.airline.name ?? "N/A")
                        FlightInfoSection(title: "Flight Number", content: flight.flight.number ?? "N/A")
                        FlightInfoSection(title: "Status", content: flight.flight_status ?? "N/A")
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Departure")
                                .font(.headline)
                            Text("Airport: \(flight.departure.airport ?? "N/A")")
                            Text("Terminal: \(flight.departure.terminal ?? "N/A")")
                            Text("Gate: \(flight.departure.gate ?? "N/A")")
                            if let scheduled = flight.departure.scheduled {
                                Text("Scheduled: \(scheduled)")
                            }
                            if let estimated = flight.departure.estimated {
                                Text("Estimated: \(estimated)")
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Arrival")
                                .font(.headline)
                            Text("Airport: \(flight.arrival.airport ?? "N/A")")
                            Text("Terminal: \(flight.arrival.terminal ?? "N/A")")
                            Text("Gate: \(flight.arrival.gate ?? "N/A")")
                            if let scheduled = flight.arrival.scheduled {
                                Text("Scheduled: \(scheduled)")
                            }
                            if let estimated = flight.arrival.estimated {
                                Text("Estimated: \(estimated)")
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                        
                        if let aircraft = flight.aircraft {
                            FlightInfoSection(title: "Aircraft", content: aircraft.registration ?? "N/A")
                        }
                        
                        if let live = flight.live {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Live Data")
                                    .font(.headline)
                                if let altitude = live.altitude {
                                    Text("Altitude: \(String(format: "%.0f", altitude)) ft")
                                }
                                if let speed = live.speed_horizontal {
                                    Text("Speed: \(String(format: "%.0f", speed)) km/h")
                                }
                                if let direction = live.direction {
                                    Text("Direction: \(String(format: "%.0f", direction))°")
                                }
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                        }
                    }
                    .padding()
                }
                .onAppear {
                    if viewModel.currentFlight != nil {
                        print("✅ Flight data loaded: \(viewModel.currentFlight?.flight.number ?? "Unknown")")
                        
                        if let flight = viewModel.currentFlight,
                           let latitude = flight.live?.latitude,
                           let longitude = flight.live?.longitude {
                            print("📍 Flight coordinates: Lat \(latitude), Long \(longitude)")
                            
                            let flightMapData = FlightMapData(
                                id: UUID().uuidString,
                                airline: flight.airline.name ?? "Unknown",
                                flightNumber: flight.flight.number ?? "Unknown",
                                departureAirport: flight.departure.airport ?? "Unknown",
                                arrivalAirport: flight.arrival.airport ?? "Unknown",
                                latitude: latitude,
                                longitude: longitude,
                                altitude: Int(flight.live?.altitude ?? 0),
                                speed: Int(flight.live?.speed_horizontal ?? 0),
                                heading: Int(flight.live?.direction ?? 0)
                            )
                            
                            print("🗺️ Created FlightMapData: \(flightMapData.flightNumber) at \(flightMapData.latitude),\(flightMapData.longitude)")
                        } else {
                            print("❌ Flight has no live coordinates")
                        }
                    }
                }
            } else {
                Text("Tap the button to get a random flight")
                    .foregroundColor(.gray)
                    .padding()
            }
        }
        .navigationTitle("Random Flight")
    }
    
    private func selectFlight(_ flightMapData: FlightMapData) async {
        await MainActor.run {
            selectedFlightMapData = flightMapData
            print("✓ Flight selected: \(flightMapData.flightNumber)")
        }
    }
}

struct FlightInfoSection: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.headline)
            Text(content)
                .font(.body)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

struct FlightLocationSection: View {
    let title: String
    let location: FlightLocation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            Text("Airport: \(location.airport ?? "Unknown")")
            Text("Terminal: \(location.terminal ?? "N/A")")
            Text("Gate: \(location.gate ?? "N/A")")
            if let scheduled = location.scheduled {
                Text("Scheduled: \(scheduled)")
            }
            if let estimated = location.estimated {
                Text("Estimated: \(estimated)")
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(8)
    }
}

#Preview {
    NavigationView {
        RandomFlightView()
    }
} 