import SwiftUI
import CoreLocation
import AVFoundation
import MapKit
import Combine
import UIKit

// Define SearchMode enum
enum SearchMode {
    case search
    case random
}

// NOTE: Using the existing Flight models from Models/Flight.swift
// NOTE: Using the existing FlightSearchViewModel from ViewModels/FlightSearchViewModel.swift
// NOTE: Using ThemeColors, ViewFlight, SimplifiedFlight, BlurView, FlightMapData from Models/SharedModels.swift
// NOTE: Using glass effect modifiers from Views/SharedGlassEffects.swift

extension Color {
    // Dark Theme Colors
    static let debotBrown = Color(UIColor(red: 0.2, green: 0.15, blue: 0.13, alpha: 1.0))
    static let debotNavy = Color(UIColor(red: 0.05, green: 0.1, blue: 0.2, alpha: 1.0))
    static let debotGray = Color(UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1.0))
    static let debotBackground = Color(UIColor(red: 0.1, green: 0.1, blue: 0.12, alpha: 1.0))
    static let debotLightBrown = Color(UIColor(red: 0.35, green: 0.25, blue: 0.2, alpha: 1.0))
    
    // Light Theme Colors
    static let debotCream = Color(UIColor(red: 0.95, green: 0.95, blue: 0.92, alpha: 1.0))
    static let debotLightBlue = Color(UIColor(red: 0.9, green: 0.95, blue: 1.0, alpha: 1.0))
    static let debotLightGray = Color(UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0))
    static let debotWarmWhite = Color(UIColor(red: 0.98, green: 0.96, blue: 0.94, alpha: 1.0))
    static let debotSoftBrown = Color(UIColor(red: 0.9, green: 0.85, blue: 0.8, alpha: 1.0))
    
    // Accent Colors
    static let debotTeal = Color(UIColor(red: 0.0, green: 0.5, blue: 0.5, alpha: 1.0))
    static let debotGold = Color(UIColor(red: 0.85, green: 0.65, blue: 0.3, alpha: 1.0))
    static let debotOrange = Color(UIColor(red: 0.9, green: 0.5, blue: 0.1, alpha: 1.0))
    
    // Text Colors
    static let debotDarkText = Color(UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0))
    
    // Alert Colors
    static let debotRed = Color(UIColor(red: 0.8, green: 0.0, blue: 0.0, alpha: 1.0))
    static let debotGreen = Color(UIColor(red: 0.0, green: 0.6, blue: 0.0, alpha: 1.0))
    
    // Other UI Elements
    static let searchBackground = Color(UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 0.8))
}

// Custom TextField Style
struct DebotTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(12)
            .background(Color.debotBrown)
            .cornerRadius(10)
            .foregroundColor(.white)
            .tint(.debotOrange)
    }
}

// Accessibility extensions
extension View {
    func withAccessibilityEnhancements(label: String, hint: String, isFlight: Bool = false) -> some View {
        self
            .accessibility(label: Text(label))
            .accessibility(hint: Text(hint))
    }
    
    func buttonPress() -> some View {
        self
    }
}

// Using AccessibilityManager from the Utilities folder
struct ThemeButton: View {
    let mode: ThemeMode
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            HapticFeedbackManager.shared.lightImpact()
            action()
        }) {
            Label(mode.rawValue.capitalized, systemImage: mode.icon)
                .foregroundColor(isSelected ? .debotOrange : nil)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonPress()
    }
}

struct ThemeSelector: View {
    @Binding var themeMode: ThemeMode
    let colors: ThemeColors
    @State private var isExpanded = false
    @State private var isRotating = false
    
    var body: some View {
        Menu {
            ForEach(ThemeMode.allCases, id: \.self) { mode in
                ThemeButton(mode: mode, isSelected: themeMode == mode) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        themeMode = mode
                        HapticFeedbackManager.shared.lightImpact()
                    }
                }
            }
        }
        label: {
            Image(systemName: themeMode.icon)
                .foregroundColor(colors.accent)
                .imageScale(.medium)
                .frame(width: 32, height: 32)
                .background(colors.cardBackground)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .strokeBorder(colors.accent.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
                .rotationEffect(.degrees(isRotating ? 360 : 0))
                .scaleEffect(isRotating ? 1.1 : 1.0)
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .onChange(of: themeMode) { _ in
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                isRotating = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                isRotating = false
            }
        }
    }
}

// Forward declaration for LoadingView to avoid circular dependencies
struct LoadingView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ProgressView()
            .progressViewStyle(CircularProgressViewStyle(tint: colorScheme == .dark ? .debotOrange : .debotGold))
            .scaleEffect(1.5)
    }
}

@MainActor
struct FlightSearchView: View {
    @ObservedObject private var viewModel: FlightSearchViewModel
    @Environment(\.themeColors) var colors
    
    // Add accessibility manager reference
    @ObservedObject private var accessibilityManager = AccessibilityManager.shared
    
    // State for animation controls
    @State private var isAnimating = false
    
    @State private var searchText = ""
    @State private var showMap = false
    @State private var mapFlights: [FlightMapData] = []
    @State private var searchMode: SearchMode = .search
    @State private var selectedFlight: ViewFlight? = nil
    
    // Airport coordinate dictionaries
    private let airportLatitudes: [String: Double] = [
        "JFK": 40.6413, "LAX": 33.9416, "SFO": 37.6213, "ORD": 41.9742,
        "LHR": 51.4700, "CDG": 49.0097, "HND": 35.5494, "SYD": -33.9499,
        "DXB": 25.2532, "SIN": 1.3644, "AMS": 52.3105, "FRA": 50.0379,
        "HKG": 22.3080, "ICN": 37.4602, "MAD": 40.4983, "FCO": 41.8003
    ]
    
    private let airportLongitudes: [String: Double] = [
        "JFK": -73.7781, "LAX": -118.4085, "SFO": -122.3790, "ORD": -87.9073,
        "LHR": -0.4543, "CDG": 2.5479, "HND": 139.7798, "SYD": 151.1819,
        "DXB": 55.3657, "SIN": 103.9915, "AMS": 4.7683, "FRA": 8.5622,
        "HKG": 113.9185, "ICN": 126.4406, "MAD": -3.5676, "FCO": 12.2388
    ]
    
    // Initialize with an optional viewModel
    init(viewModel: FlightSearchViewModel) {
        self._viewModel = ObservedObject(wrappedValue: viewModel)
    }
    
    // MARK: - Computed Properties
    
    var currentColorScheme: ColorScheme {
        switch viewModel.themeMode {
        case .dark: return .dark
        case .light: return .light
        case .system: return viewModel.systemColorScheme
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Background
                colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search bar and mode toggle
                    VStack(spacing: 12) {
                        // Mode toggle
                        Picker("Search Mode", selection: $searchMode) {
                            Text("Search").tag(SearchMode.search)
                            Text("Random").tag(SearchMode.random)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.horizontal, 12)
                        .padding(.top, 8)
                        
                        if searchMode == .search {
                            // Search bar - TIGHTENED PADDING
                            HStack {
                                TextField("Enter flight number, route, or airport", text: $searchText)
                                    .padding(8)
                                    .background(colors.cardBackground)
                                    .cornerRadius(8)
                                    .foregroundColor(colors.text)
                                    .accentColor(colors.accent)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(colors.divider, lineWidth: 1)
                                    )
                                    .submitLabel(.search)
                                    .onSubmit {
                                        // Also trigger search on return key
                                        print("Search submitted via keyboard with query: \(searchText)")
                                        viewModel.searchQuery = searchText
                                        viewModel.searchFlights()
                                        HapticFeedbackManager.shared.selection()
                                    }
                                
                                Button(action: {
                                    // Trigger search
                                    print("Search button pressed with query: \(searchText)")
                                    viewModel.searchQuery = searchText
                                    viewModel.searchFlights()
                                    HapticFeedbackManager.shared.selection()
                                }) {
                                    Image(systemName: "magnifyingglass")
                                        .foregroundColor(colors.accent)
                                        .padding(8)
                                        .background(colors.cardBackground)
                                        .cornerRadius(8)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.bottom, 8)
                        }
                    }
                    .background(colors.cardBackground.opacity(0.7))
                    .cornerRadius(10)
                    .padding(.horizontal, 8)
                    .padding(.top, 8)
                    .padding(.bottom, 4)
                    
                    // Content area
                    ZStack {
                        if viewModel.isLoading {
                            LoadingView()
                        } else if let error = viewModel.error {
                            errorView(error: error)
                        } else {
                            if searchMode == .search {
                                if !viewModel.searched {
                                    // Initial state - REPLACED CARD WITH SIMPLE TITLE
                                    VStack(spacing: 8) {
                                        Text("Find Your Flight")
                                            .font(.system(size: 34, weight: .black, design: .serif))
                                            .foregroundColor(colors.accent)
                                            .shadow(color: colors.text.opacity(0.2), radius: 1, x: 1, y: 1)
                                            .tracking(-0.5)
                                            .padding(.bottom, 6)
                                        
                                        Image(systemName: "airplane")
                                            .font(.system(size: 24))
                                            .foregroundColor(colors.accent)
                                            .rotationEffect(.degrees(45))
                                            .padding(.bottom, 8)
                                    }
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                } else if viewModel.viewFlights.isEmpty {
                                    // No results - FURTHER TIGHTENED PADDING
                                    VStack(spacing: 12) {
                                        Image(systemName: "magnifyingglass")
                                            .font(.system(size: 40))
                                            .foregroundColor(colors.secondaryText)
                                        
                                        Text("No flights found")
                                            .font(.title3)
                                            .foregroundColor(colors.text)
                                        
                                        Text("Try a different search term")
                                            .font(.callout)
                                            .foregroundColor(colors.secondaryText)
                                    }
                                    .padding(.vertical, 16)
                                    .padding(.horizontal, 12)
                                    .background(colors.cardBackground.opacity(0.6))
                                    .cornerRadius(10)
                                    .padding(8)
                                } else {
                                    // Search results - REMOVED EXTRA PADDING
                                    ZStack {
                                        if showMap, let selected = selectedFlight {
                                            // Map view 
                                            flightMapView(flight: selected)
                                                .edgesIgnoringSafeArea(.bottom)
                                            // Add tap gesture to the map to toggle back to list
                                            .onTapGesture(count: 2) {
                                                showMap = false
                                                HapticFeedbackManager.shared.selection()
                                            }
                                        } else {
                                            flightListView(flights: viewModel.viewFlights)
                                        }
                                    }
                                }
                            } else {
                                // Random flight - TIGHTENED PADDING
                                if let flight = viewModel.viewRandomFlight {
                                    randomFlightDetailView(flight: flight)
                                } else {
                                    Button("Find a Random Flight") {
                                        viewModel.getRandomFlight()
                                        HapticFeedbackManager.shared.mediumImpact()
                                    }
                                    .foregroundColor(colors.accent)
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 16)
                                    .background(colors.cardBackground)
                                    .cornerRadius(8)
                                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Flight Search")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    ThemeSelector(themeMode: $viewModel.themeMode, colors: colors)
                }
            }
            .preferredColorScheme(currentColorScheme)
            .onAppear {
                // Initialize viewModel if needed
                if searchMode == .random && viewModel.viewRandomFlight == nil && !viewModel.isLoading {
                    viewModel.getRandomFlight()
                }
            }
            // Add onChange handler for searchText
            .onChange(of: searchText) { newValue in
                // Handle empty search
                if newValue.isEmpty && viewModel.searched {
                    // Reset the search if text is cleared
                    viewModel.searchQuery = ""
                }
            }
            // Add onChange handler for searchMode
            .onChange(of: searchMode) { newMode in
                if newMode == .random && viewModel.viewRandomFlight == nil && !viewModel.isLoading {
                    viewModel.getRandomFlight()
                }
            }
        }
    }
    
    // Helper functions for getting latitude and longitude
    private func getLatitude(from flight: ViewFlight) -> Double {
        // Try to get coordinates from the departure airport code
        if let lat = airportLatitudes[flight.departure] {
            return lat + Double.random(in: -2.0...2.0) // Add some randomness
        }
        // Fallback to a default value with randomness
        return 37.0902 + Double.random(in: -20.0...20.0)
    }
    
    private func getLongitude(from flight: ViewFlight) -> Double {
        // Try to get coordinates from the departure airport code
        if let lon = airportLongitudes[flight.departure] {
            return lon + Double.random(in: -2.0...2.0) // Add some randomness
        }
        // Fallback to a default value with randomness
        return -95.7129 + Double.random(in: -20.0...20.0)
    }
    
    // Placeholder for searchBarView
    private var searchBarView: some View {
        EmptyView()
    }
    
    // Placeholder for loadingView
    private var loadingView: some View {
        LoadingView()
    }
    
    // Placeholder for errorView
    private func errorView(error: String) -> some View {
        Text("Error: \(error)")
    }
    
    // Placeholder for emptyStateView
    private var emptyStateView: some View {
        EmptyView()
    }
    
    // Placeholder for emptySearchView
    private var emptySearchView: some View {
        EmptyView()
    }
    
    // Placeholder for searchResultsList
    private var searchResultsList: some View {
        EmptyView()
    }
    
    // Placeholder for randomFlightView
    private var randomFlightView: some View {
        EmptyView()
    }
    
    // Flight list view - FURTHER TIGHTENED PADDING
    private func flightListView(flights: [ViewFlight]) -> some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(flights) { flight in
                    flightCard(for: flight)
                        .onTapGesture {
                            // Toggle map view if same flight is tapped again
                            if selectedFlight?.id == flight.id && showMap {
                                showMap = false
                            } else {
                                selectedFlight = flight
                                showMap = true
                                mapFlights = [FlightMapData.from(flight, latitude: getLatitude(from: flight), longitude: getLongitude(from: flight))]
                            }
                            HapticFeedbackManager.shared.selection()
                        }
                }
            }
            .padding(8)
        }
    }
    
    // Flight card - FURTHER TIGHTENED PADDING
    private func flightCard(for flight: ViewFlight) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Text(flight.airline)
                    .font(.headline)
                    .foregroundColor(colors.text)
                
                Spacer()
                
                Text(flight.flightNumber)
                    .font(.headline)
                    .foregroundColor(colors.accent)
            }
            
            Divider()
                .background(colors.divider)
            
            // Route
            HStack(spacing: 10) {
                VStack(alignment: .leading) {
                    Text(flight.departure)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(colors.text)
                    
                    Text(flight.departureCity)
                        .font(.subheadline)
                        .foregroundColor(colors.secondaryText)
                }
                
                Spacer()
                
                Image(systemName: "airplane")
                    .foregroundColor(colors.accent)
                    .rotationEffect(.degrees(90))
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text(flight.arrival)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(colors.text)
                    
                    Text(flight.arrivalCity)
                        .font(.subheadline)
                        .foregroundColor(colors.secondaryText)
                }
            }
            
            Divider()
                .background(colors.divider)
            
            // Status and details
            HStack {
                Label {
                    Text(flight.status)
                        .foregroundColor(statusColor(for: flight.status))
                } icon: {
                    Image(systemName: "circle.fill")
                        .foregroundColor(statusColor(for: flight.status))
                        .font(.system(size: 8))
                }
                
                Spacer()
                
                Text("Alt: \(flight.altitude)")
                    .font(.caption)
                    .foregroundColor(colors.secondaryText)
                
                Text("•")
                    .foregroundColor(colors.divider)
                
                Text("\(flight.speed)")
                    .font(.caption)
                    .foregroundColor(colors.secondaryText)
            }
        }
        .padding(10)
        .background(colors.cardBackground)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        .sharedFlightGlassEffect()
    }
    
    // Flight map view - TIGHTENED PADDING
    private func flightMapView(flight: ViewFlight) -> some View {
        VStack(spacing: 0) {
            // Flight info card
            VStack(spacing: 10) {
                HStack {
                    Text(flight.airline)
                        .font(.headline)
                        .foregroundColor(colors.text)
                    
                    Spacer()
                    
                    Text(flight.flightNumber)
                        .font(.headline)
                        .foregroundColor(colors.accent)
                }
                
                HStack(spacing: 16) {
                    VStack(alignment: .leading) {
                        Text(flight.departure)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(colors.text)
                        
                        Text(flight.departureCity)
                            .font(.subheadline)
                            .foregroundColor(colors.secondaryText)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "airplane")
                        .foregroundColor(colors.accent)
                        .imageScale(.large)
                        .rotationEffect(.degrees(90))
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text(flight.arrival)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(colors.text)
                        
                        Text(flight.arrivalCity)
                            .font(.subheadline)
                            .foregroundColor(colors.secondaryText)
                    }
                }
                
                Divider()
                    .background(colors.divider)
                
                // Flight details
                HStack {
                    Label {
                        Text(flight.status)
                            .foregroundColor(statusColor(for: flight.status))
                    } icon: {
                        Image(systemName: "circle.fill")
                            .foregroundColor(statusColor(for: flight.status))
                            .font(.system(size: 8))
                    }
                    
                    Spacer()
                    
                    // Add tap hint
                    Text("Tap to return to list")
                        .font(.caption)
                        .foregroundColor(colors.secondaryText)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(colors.cardBackground.opacity(0.5))
                        .cornerRadius(6)
                }
            }
            .padding(10)
            .background(colors.cardBackground)
            .cornerRadius(10)
            .padding(8)
            .onTapGesture {
                showMap = false
                HapticFeedbackManager.shared.selection()
            }
            
            // Map
            Map(coordinateRegion: .constant(getMKCoordinateRegion(from: flight)),
                annotationItems: [flight]) { flight in
                MapAnnotation(
                    coordinate: CLLocationCoordinate2D(
                        latitude: getLatitude(from: flight),
                        longitude: getLongitude(from: flight)
                    )
                ) {
                    Image(systemName: "airplane.circle.fill")
                        .font(.title)
                        .foregroundColor(colors.accent)
                        .background(Circle().fill(Color.white).frame(width: 30, height: 30))
                        .shadow(radius: 2)
                }
            }
            .edgesIgnoringSafeArea(.bottom)
        }
    }
    
    // Function to get MKCoordinateRegion from a flight
    private func getMKCoordinateRegion(from flight: ViewFlight) -> MKCoordinateRegion {
        let latitude = getLatitude(from: flight)
        let longitude = getLongitude(from: flight)
        
        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            span: MKCoordinateSpan(latitudeDelta: 10, longitudeDelta: 10)
        )
    }
    
    // Random flight detail view - TIGHTENED PADDING
    private func randomFlightDetailView(flight: ViewFlight) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header
                VStack {
                    Text(flight.airline)
                        .font(.title2)
                        .foregroundColor(colors.text)
                    
                    Text(flight.flightNumber)
                        .font(.title)
                        .bold()
                        .foregroundColor(colors.accent)
                    
                    HStack {
                        Text(statusColor(for: flight.status) == .green ? "On Time" : flight.status)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 3)
                            .background(statusColor(for: flight.status).opacity(0.2))
                            .foregroundColor(statusColor(for: flight.status))
                            .cornerRadius(10)
                    }
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 14)
                .frame(maxWidth: .infinity)
                .sharedFlightGlassEffect()
                
                // Route card
                VStack(spacing: 20) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("From")
                                .font(.caption)
                                .foregroundColor(colors.secondaryText)
                            
                            Text(flight.departure)
                                .font(.title)
                                .bold()
                                .foregroundColor(colors.text)
                            
                            Text(flight.departureCity)
                                .foregroundColor(colors.secondaryText)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "airplane")
                            .font(.title)
                            .foregroundColor(colors.accent)
                            .rotationEffect(.degrees(90))
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("To")
                                .font(.caption)
                                .foregroundColor(colors.secondaryText)
                            
                            Text(flight.arrival)
                                .font(.title)
                                .bold()
                                .foregroundColor(colors.text)
                            
                            Text(flight.arrivalCity)
                                .foregroundColor(colors.secondaryText)
                        }
                    }
                    
                    Divider()
                        .background(colors.divider)
                    
                    // Details
                    VStack(spacing: 10) {
                        flightDetailRow(title: "Aircraft", value: flight.aircraft)
                        flightDetailRow(title: "Altitude", value: flight.altitude)
                        flightDetailRow(title: "Speed", value: flight.speed)
                    }
                }
                .padding(12)
                .background(colors.cardBackground)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
                .sharedFlightGlassEffect()
                .padding(.horizontal, 10)
                
                // Find new random flight button
                Button(action: {
                    viewModel.getRandomFlight()
                    HapticFeedbackManager.shared.mediumImpact()
                }) {
                    Text("Find Another Flight")
                        .fontWeight(.medium)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .frame(maxWidth: .infinity)
                        .background(colors.accent)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal, 10)
                .padding(.top, 6)
            }
            .padding(.vertical, 10)
        }
    }
    
    // Flight detail row
    private func flightDetailRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundColor(colors.secondaryText)
            
            Spacer()
            
            Text(value)
                .foregroundColor(colors.text)
                .fontWeight(.medium)
        }
    }
    
    // Status color
    private func statusColor(for status: String) -> Color {
        let lowercaseStatus = status.lowercased()
        if lowercaseStatus.contains("on time") || lowercaseStatus == "active" {
            return .green
        } else if lowercaseStatus.contains("delay") || lowercaseStatus.contains("wait") {
            return .orange
        } else if lowercaseStatus.contains("cancel") {
            return .red
        } else {
            return .blue
        }
    }
    
    // Placeholder for search function
    private func search() {
        // Empty implementation
    }
}

// Non-MainActor wrapper for FlightSearchView
// This can be safely instantiated from any context
public struct FlightSearchViewContainer: View {
    @State private var viewModel: FlightSearchViewModel?
    @State private var isLoading = true
    
    public init() {}
    
    public var body: some View {
        Group {
            if let viewModel = viewModel {
                FlightSearchView(viewModel: viewModel)
            } else {
                LoadingView()
                    .onAppear {
                        Task {
                            // Create the view model on the MainActor
                            let newViewModel = await MainActor.run {
                                return FlightSearchViewModel()
                            }
                            
                            // Set the view model
                            await MainActor.run {
                                self.viewModel = newViewModel
                                self.isLoading = false
                            }
                        }
                    }
            }
        }
    }
}

// Preview wrapper
extension FlightSearchView {
    static func createForPreview() -> some View {
        let previewViewModel = PreviewFlightSearchViewModel()
        return FlightSearchViewPreview(viewModel: previewViewModel)
    }
    
    // Preview wrapper that doesn't depend on MainActor
    private struct FlightSearchViewPreview: View {
        @ObservedObject var viewModel: PreviewFlightSearchViewModel
        @State private var isViewReady = false
        
        var body: some View {
            Group {
                if isViewReady {
                    NavigationView {
                        TabView {
                            Text("Flight Search View")
                                .tabItem {
                                    Label("Search", systemImage: "magnifyingglass")
                                }
                        }
                        .environment(\.themeColors, ThemeColors.colors(for: .dark))
                    }
                } else {
                    ProgressView("Loading...")
                }
            }
            .onAppear {
                // Ensure we're on the main thread
                DispatchQueue.main.async {
                    self.isViewReady = true
                }
            }
        }
    }
}

// Preview view model that doesn't use MainActor
class PreviewFlightSearchViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var flights: [ViewFlight] = []
    @Published var randomFlight: ViewFlight?
    @Published var isLoading = false
    @Published var error: String?
    @Published var searchQuery: String = ""
    @Published var searchResults: [ViewFlight] = []
    @Published var searched: Bool = false
    @Published var themeMode: ThemeMode = .dark
    @Published var systemColorScheme: ColorScheme = .dark
    @Published var useMockData: Bool = true
    @Published var isSearchMode: Bool = true
    
    init() {
        // Add some sample flights for preview
        self.flights = Self.sampleFlights()
        self.randomFlight = Self.sampleFlights().randomElement()
    }
    
    static func sampleFlights() -> [ViewFlight] {
        return [
            ViewFlight(
                airline: "American Airlines",
                flightNumber: "AA123",
                departure: "JFK",
                arrival: "LAX",
                status: "On Time",
                altitude: "35,000 ft",
                speed: "550 mph",
                departureCity: "New York",
                arrivalCity: "Los Angeles",
                aircraft: "Boeing 737"
            ),
            ViewFlight(
                airline: "Delta",
                flightNumber: "DL456",
                departure: "SFO",
                arrival: "ORD",
                status: "Delayed",
                altitude: "31,000 ft",
                speed: "520 mph",
                departureCity: "San Francisco",
                arrivalCity: "Chicago",
                aircraft: "Airbus A320"
            ),
            ViewFlight(
                airline: "United",
                flightNumber: "UA789",
                departure: "LHR",
                arrival: "JFK",
                status: "On Time",
                altitude: "38,000 ft",
                speed: "580 mph",
                departureCity: "London",
                arrivalCity: "New York",
                aircraft: "Boeing 787"
            )
        ]
    }
    
    func searchFlights() {
        // Preview implementation
        isLoading = true
        
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isLoading = false
            self.searchResults = Self.sampleFlights()
            self.searched = true
        }
    }
    
    func getRandomFlight() {
        // Preview implementation
        isLoading = true
        
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isLoading = false
            self.randomFlight = Self.sampleFlights().randomElement()
        }
    }
}

// Preview
#Preview {
    FlightSearchView.createForPreview()
} 