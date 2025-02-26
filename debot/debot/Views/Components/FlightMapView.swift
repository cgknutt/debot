import SwiftUI
import MapKit

// NOTE: Using FlightMapData from Models/SharedModels.swift

struct FlightMapView: View {
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.0902, longitude: -95.7129), // Center on US
        span: MKCoordinateSpan(latitudeDelta: 60, longitudeDelta: 60)
    )
    
    @State private var selectedFlight: FlightMapData? = nil
    let flights: [FlightMapData]
    
    init(flights: [FlightMapData] = []) {
        self.flights = flights
        
        // If we have a flight, center the map on its position
        if let firstFlight = flights.first {
            self._region = State(initialValue: MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: firstFlight.latitude, longitude: firstFlight.longitude),
                span: MKCoordinateSpan(latitudeDelta: 40, longitudeDelta: 40)
            ))
            self._selectedFlight = State(initialValue: firstFlight)
        }
    }
    
    var body: some View {
        ZStack {
            Map(coordinateRegion: $region, annotationItems: flights) { flight in
                MapAnnotation(coordinate: CLLocationCoordinate2D(
                    latitude: flight.latitude, 
                    longitude: flight.longitude
                )) {
                    FlightAnnotationView(flight: flight, isSelected: flight.id == selectedFlight?.id) {
                        selectedFlight = flight
                    }
                }
            }
            .edgesIgnoringSafeArea(.bottom)
            
            // Flight path lines (if we have multiple flights)
            if flights.count > 1 {
                let flightPath = createFlightPath()
                MapOverlay(flightPath: flightPath)
                    .allowsHitTesting(false)
            }
            
            // Flight info card when a flight is selected
            if let selected = selectedFlight {
                VStack {
                    Spacer()
                    
                    FlightInfoCard(flight: selected)
                        .padding(.horizontal)
                        .padding(.bottom)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .animation(.spring(), value: selectedFlight?.id)
            }
            
            // Map controls
            VStack {
                HStack {
                    Spacer()
                    
                    VStack(spacing: 12) {
                        Button(action: {
                            // Zoom in
                            withAnimation {
                                region.span.latitudeDelta *= 0.7
                                region.span.longitudeDelta *= 0.7
                            }
                        }) {
                            Image(systemName: "plus")
                                .padding(10)
                                .background(Color.white)
                                .clipShape(Circle())
                                .shadow(radius: 2)
                        }
                        
                        Button(action: {
                            // Zoom out
                            withAnimation {
                                region.span.latitudeDelta /= 0.7
                                region.span.longitudeDelta /= 0.7
                            }
                        }) {
                            Image(systemName: "minus")
                                .padding(10)
                                .background(Color.white)
                                .clipShape(Circle())
                                .shadow(radius: 2)
                        }
                        
                        // Reset view to fit all points
                        Button(action: {
                            withAnimation {
                                fitMapToShowAllPoints()
                            }
                        }) {
                            Image(systemName: "arrow.up.left.and.down.right.magnifyingglass")
                                .padding(10)
                                .background(Color.white)
                                .clipShape(Circle())
                                .shadow(radius: 2)
                        }
                        
                        // Reset view if we have a selected flight
                        if selectedFlight != nil {
                            Button(action: {
                                if let flight = selectedFlight {
                                    withAnimation {
                                        region.center = CLLocationCoordinate2D(
                                            latitude: flight.latitude,
                                            longitude: flight.longitude
                                        )
                                        region.span = MKCoordinateSpan(latitudeDelta: 20, longitudeDelta: 20)
                                    }
                                }
                            }) {
                                Image(systemName: "location")
                                    .padding(10)
                                    .background(Color.white)
                                    .clipShape(Circle())
                                    .shadow(radius: 2)
                            }
                        }
                    }
                    .padding()
                }
                
                Spacer()
            }
        }
        .onAppear {
            // When view appears, adjust the map to show all points
            if flights.count > 1 {
                fitMapToShowAllPoints()
            }
        }
    }
    
    // Helper to fit all flight points on the map
    private func fitMapToShowAllPoints() {
        guard !flights.isEmpty else { return }
        
        // Find min/max coordinates
        var minLat = flights[0].latitude
        var maxLat = flights[0].latitude
        var minLon = flights[0].longitude
        var maxLon = flights[0].longitude
        
        for flight in flights {
            minLat = min(minLat, flight.latitude)
            maxLat = max(maxLat, flight.latitude)
            minLon = min(minLon, flight.longitude)
            maxLon = max(maxLon, flight.longitude)
        }
        
        // Add some padding
        let latPadding = (maxLat - minLat) * 0.2
        let lonPadding = (maxLon - minLon) * 0.2
        
        // Calculate center
        let centerLat = (minLat + maxLat) / 2
        let centerLon = (minLon + maxLon) / 2
        
        // Calculate span (with minimum values to prevent too much zoom)
        let latDelta = max(maxLat - minLat + latPadding * 2, 10)
        let lonDelta = max(maxLon - minLon + lonPadding * 2, 10)
        
        // Update region
        region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon),
            span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
        )
    }
    
    // Create a path connecting all flights in order
    private func createFlightPath() -> [CGPoint] {
        let mapSize = UIScreen.main.bounds.size
        
        return flights.map { flight ->  CGPoint in
            let point = MKMapPoint(CLLocationCoordinate2D(
                latitude: flight.latitude,
                longitude: flight.longitude
            ))
            
            let mapPoint = point.x - region.center.longitude
            let mapPointY = point.y - region.center.latitude
            
            let x = mapSize.width / 2 + CGFloat(mapPoint)
            let y = mapSize.height / 2 + CGFloat(mapPointY)
            
            return CGPoint(x: x, y: y)
        }
    }
}

// Map overlay view to draw flight paths
struct MapOverlay: View {
    let flightPath: [CGPoint]
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                guard let firstPoint = flightPath.first else { return }
                
                path.move(to: firstPoint)
                for point in flightPath.dropFirst() {
                    path.addLine(to: point)
                }
            }
            .stroke(Color.blue, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round, dash: [5, 5]))
        }
    }
}

// Custom annotation view for flights
struct FlightAnnotationView: View {
    let flight: FlightMapData
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                Image(systemName: "airplane")
                    .rotationEffect(.degrees(Double(flight.heading)))
                    .frame(width: 30, height: 30)
                    .foregroundColor(.white)
                    .background(isSelected ? Color.blue : Color.gray)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                    )
                    .shadow(radius: 3)
                
                if isSelected {
                    Text(flight.flightNumber)
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(4)
                        .background(Color.white)
                        .cornerRadius(4)
                        .shadow(radius: 1)
                        .padding(.top, 4)
                }
            }
        }
    }
}

// Flight info card
struct FlightInfoCard: View {
    let flight: FlightMapData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(flight.flightNumber)
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                Text("\(flight.airline)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            HStack {
                VStack(alignment: .leading) {
                    Text("From")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(flight.departureAirport)
                        .font(.body)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                Image(systemName: "airplane")
                    .imageScale(.medium)
                    .foregroundColor(.accentColor)
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("To")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(flight.arrivalAirport)
                        .font(.body)
                        .fontWeight(.medium)
                }
            }
            
            Divider()
            
            HStack {
                FlightDataRow(title: "Altitude", value: "\(flight.altitude) ft")
                Spacer()
                FlightDataRow(title: "Speed", value: "\(flight.speed) kts")
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 5)
    }
}

// Helper for flight info display
struct FlightDataRow: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.subheadline)
        }
    }
}

// Preview
struct FlightMapView_Previews: PreviewProvider {
    static var previews: some View {
        FlightMapView(flights: [
            FlightMapData(
                id: UUID().uuidString,
                airline: "American Airlines",
                flightNumber: "AA123",
                departureAirport: "JFK",
                arrivalAirport: "LAX",
                latitude: 40.6413,
                longitude: -73.7781,
                altitude: 35000,
                speed: 550,
                heading: 270
            ),
            FlightMapData(
                id: UUID().uuidString,
                airline: "Delta",
                flightNumber: "DL456",
                departureAirport: "SFO",
                arrivalAirport: "ORD",
                latitude: 37.6213,
                longitude: -122.3790,
                altitude: 31000,
                speed: 520,
                heading: 45
            )
        ])
    }
} 