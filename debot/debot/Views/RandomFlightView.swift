import SwiftUI

struct RandomFlightView: View {
    @StateObject private var viewModel = AviationViewModel()
    
    var body: some View {
        VStack(spacing: 20) {
            Button(action: {
                viewModel.fetchRandomFlight()
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
            } else {
                Text("Tap the button to get a random flight")
                    .foregroundColor(.gray)
                    .padding()
            }
        }
        .navigationTitle("Random Flight")
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