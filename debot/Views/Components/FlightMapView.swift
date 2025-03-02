import SwiftUI
import MapKit

// NOTE: Using FlightMapData from Models/SharedModels.swift

struct FlightMapView: View {
    @Binding var selectedFlight: FlightMapData?
    var flights: [FlightMapData]
    @State private var region: MKCoordinateRegion
    
    // Default initializer for backward compatibility
    init(flights: [FlightMapData]) {
        self._selectedFlight = .constant(nil)
        self.flights = flights
        
        // Debug print to see number of flights
        print("FlightMapView initialized with \(flights.count) flights")
        
        // Calculate initial region based on first flight or default to center of US
        if let firstFlight = flights.first {
            print("First flight: \(firstFlight.flightNumber) at (\(firstFlight.latitude), \(firstFlight.longitude))")
            let initialLocation = CLLocationCoordinate2D(
                latitude: firstFlight.latitude,
                longitude: firstFlight.longitude
            )
            self._region = State(initialValue: MKCoordinateRegion(
                center: initialLocation,
                span: MKCoordinateSpan(latitudeDelta: 10, longitudeDelta: 10)
            ))
        } else {
            // Default to center of US if no flights with coordinates
            print("No flights with coordinates, defaulting to center of US")
            self._region = State(initialValue: MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 39.8283, longitude: -98.5795),
                span: MKCoordinateSpan(latitudeDelta: 30, longitudeDelta: 30)
            ))
        }
    }
    
    // Initializer that accepts a binding for selectedFlight
    init(flights: [FlightMapData], selectedFlight: Binding<FlightMapData?>) {
        self._selectedFlight = selectedFlight
        self.flights = flights
        
        // Debug print to see number of flights
        print("FlightMapView initialized with \(flights.count) flights and selected flight binding")
        
        // Calculate initial region based on first flight or default to center of US
        if let firstFlight = flights.first {
            print("First flight: \(firstFlight.flightNumber) at (\(firstFlight.latitude), \(firstFlight.longitude))")
            let initialLocation = CLLocationCoordinate2D(
                latitude: firstFlight.latitude,
                longitude: firstFlight.longitude
            )
            self._region = State(initialValue: MKCoordinateRegion(
                center: initialLocation,
                span: MKCoordinateSpan(latitudeDelta: 10, longitudeDelta: 10)
            ))
        } else {
            // Default to center of US if no flights with coordinates
            print("No flights with coordinates, defaulting to center of US")
            self._region = State(initialValue: MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 39.8283, longitude: -98.5795),
                span: MKCoordinateSpan(latitudeDelta: 30, longitudeDelta: 30)
            ))
        }
    }
    
    // Helper view for flight annotations
    @MapContentBuilder
    private func flightAnnotations() -> some MapContent {
        ForEach(flights) { flight in
            Marker(
                coordinate: CLLocationCoordinate2D(
                    latitude: flight.latitude,
                    longitude: flight.longitude
                )
            ) {
                FlightAnnotationView(
                    flight: flight,
                    isSelected: selectedFlight?.id == flight.id
                )
                .onTapGesture {
                    print("Flight tapped: \(flight.flightNumber)")
                    selectedFlight = flight
                }
            }
        }
    }
    
    // Helper view for map controls
    private func mapControlsView() -> some View {
        VStack {
            MapCompass()
            MapScaleView()
        }
    }
    
    var body: some View {
        ZStack {
            // Background for debugging
            Color.gray.opacity(0.1)
            
            // Map with flight annotations
            mapView
            
            // Controls for zooming
            mapControlButtons
            
            // Selected flight info overlay
            selectedFlightOverlay
        }
        .onAppear {
            print("FlightMapView appeared")
            // Fit map to show all points when view appears
            fitMapToShowAllPoints()
        }
    }
    
    // Break down the body into smaller components
    private var mapView: some View {
        Map(initialPosition: .region(region)) {
            flightAnnotations()
        }
        .mapStyle(.standard)
        .mapControls {
            MapCompass()
            MapScaleView()
        }
    }
    
    private var mapControlButtons: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                VStack(spacing: 20) {
                    // Add search button
                    Button(action: {
                        print("Search pressed")
                        // Add search functionality here
                    }) {
                        Image(systemName: "magnifyingglass.circle.fill")
                            .font(.title)
                            .foregroundColor(.blue)
                            .background(Color.white.opacity(0.8))
                            .clipShape(Circle())
                    }
                    
                    // Add refresh button
                    Button(action: {
                        print("Refresh pressed")
                        // Add refresh functionality here
                    }) {
                        Image(systemName: "arrow.clockwise.circle.fill")
                            .font(.title)
                            .foregroundColor(.blue)
                            .background(Color.white.opacity(0.8))
                            .clipShape(Circle())
                    }
                    
                    // Existing zoom in button
                    Button(action: {
                        print("Zoom in pressed")
                        let span = region.span
                        region.span = MKCoordinateSpan(
                            latitudeDelta: span.latitudeDelta * 0.5,
                            longitudeDelta: span.longitudeDelta * 0.5
                        )
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title)
                            .foregroundColor(.blue)
                            .background(Color.white.opacity(0.8))
                            .clipShape(Circle())
                    }
                    
                    // Existing zoom out button
                    Button(action: {
                        print("Zoom out pressed")
                        let span = region.span
                        region.span = MKCoordinateSpan(
                            latitudeDelta: span.latitudeDelta * 2.0,
                            longitudeDelta: span.longitudeDelta * 2.0
                        )
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .font(.title)
                            .foregroundColor(.blue)
                            .background(Color.white.opacity(0.8))
                            .clipShape(Circle())
                    }
                    
                    // Existing fit map button
                    Button(action: {
                        print("Fitting map to show all points")
                        fitMapToShowAllPoints()
                    }) {
                        Image(systemName: "arrow.up.left.and.arrow.down.right.circle.fill")
                            .font(.title)
                            .foregroundColor(.blue)
                            .background(Color.white.opacity(0.8))
                            .clipShape(Circle())
                    }
                    
                    // Add settings button
                    Button(action: {
                        print("Settings pressed")
                        // Add settings functionality here
                    }) {
                        Image(systemName: "gearshape.circle.fill")
                            .font(.title)
                            .foregroundColor(.blue)
                            .background(Color.white.opacity(0.8))
                            .clipShape(Circle())
                    }
                }
                .padding()
            }
        }
    }
    
    @ViewBuilder
    private var selectedFlightOverlay: some View {
        if let selectedFlight = selectedFlight {
            VStack {
                FlightInfoCard(flight: selectedFlight)
                Spacer()
            }
            .padding(.top)
        }
    }
    
    // Helper function to fit the map to show all flight points
    private func fitMapToShowAllPoints() {
        guard !flights.isEmpty else {
            print("No flights to fit map")
            return
        }
        
        // Calculate the bounding box for all coordinates
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
        
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        
        let span = MKCoordinateSpan(
            latitudeDelta: (maxLat - minLat) + latPadding,
            longitudeDelta: (maxLon - minLon) + lonPadding
        )
        
        print("Adjusting region to center: \(center.latitude), \(center.longitude) with span: \(span.latitudeDelta), \(span.longitudeDelta)")
        region = MKCoordinateRegion(center: center, span: span)
    }
}

// Flight Annotation View
struct FlightAnnotationView: View {
    var flight: FlightMapData
    var isSelected: Bool
    
    var body: some View {
        ZStack {
            Circle()
                .fill(isSelected ? Color.blue : Color.gray.opacity(0.8))
                .frame(width: 40, height: 40)
            
            Image(systemName: "airplane")
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
                .foregroundColor(.white)
                // Flip the airplane horizontally (around vertical axis)
                // This preserves the original orientation but makes it face the opposite direction
                .scaleEffect(x: -1, y: 1)
                // Then apply the heading rotation (0 = North, 90 = East, 180 = South, 270 = West)
                .rotationEffect(.degrees(Double(flight.heading)))
        }
    }
}

// Flight Info Card
struct FlightInfoCard: View {
    var flight: FlightMapData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(flight.airline) \(flight.flightNumber)")
                .font(.headline)
            
            Text("From: \(flight.departureAirport) To: \(flight.arrivalAirport)")
                .font(.subheadline)
            
            Text("Position: \(String(format: "%.4f", flight.latitude)), \(String(format: "%.4f", flight.longitude))")
                .font(.caption)
            
            HStack {
                Text("Altitude: \(flight.altitude) ft")
                    .font(.caption)
                Spacer()
                Text("Speed: \(flight.speed) kts")
                    .font(.caption)
            }
        }
        .padding()
        .background(Color.white.opacity(0.9))
        .cornerRadius(10)
        .shadow(radius: 3)
        .padding(.horizontal)
    }
}

// Preview provider for testing in Xcode
struct FlightMapView_Previews: PreviewProvider {
    static var previews: some View {
        FlightMapView(flights: [
            FlightMapData(
                id: "1",
                airline: "AA",
                flightNumber: "123",
                departureAirport: "JFK",
                arrivalAirport: "LAX",
                latitude: 37.7749,
                longitude: -122.4194,
                altitude: 35000,
                speed: 550,
                heading: 270
            ),
            FlightMapData(
                id: "2",
                airline: "UA",
                flightNumber: "456",
                departureAirport: "SFO",
                arrivalAirport: "ORD",
                latitude: 40.7128,
                longitude: -74.0060,
                altitude: 31000,
                speed: 520,
                heading: 45
            )
        ])
    }
} 