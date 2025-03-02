import SwiftUI
import SceneKit
import CoreLocation

/// A stunning 3D globe visualization for flight tracking
/// This component renders a beautiful, interactive 3D Earth with live flight paths
struct FlightGlobeView: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var viewModel: FlightGlobeViewModel
    @State private var rotation: Double = 0
    @State private var lastDragPosition: CGPoint?
    @State private var globeRotation: SCNVector3 = SCNVector3(0, 0, 0)
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // Premium background gradient
            backgroundGradient
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Controls bar with visualization options
                controlsBar
                
                // 3D SceneKit globe view
                CustomSceneView(scene: viewModel.scene, pointOfView: viewModel.cameraNode, options: [.allowsCameraControl, .autoenablesDefaultLighting], onTap: { location, hitResults in
                    viewModel.handleTapResults(hitResults)
                })
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                handleDrag(value)
                            }
                            .onEnded { _ in
                                lastDragPosition = nil
                            }
                    )
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                handleZoom(value)
                            }
                    )
                
                // Flight information panel
                if viewModel.selectedFlight != nil {
                    flightInfoPanel
                }
            }
            
            // Visual indicators for loading states
            if viewModel.isLoading {
                loadingOverlay
            }
            
            // Quick zoom controls
            zoomControls
        }
        .onAppear {
            viewModel.setupScene()
        }
    }
    
    // MARK: - UI Components
    
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                colorScheme == .dark 
                    ? Color(red: 0.05, green: 0.05, blue: 0.1) 
                    : Color(red: 0.9, green: 0.95, blue: 1.0),
                colorScheme == .dark 
                    ? Color(red: 0.1, green: 0.1, blue: 0.2) 
                    : Color(red: 0.7, green: 0.85, blue: 0.95)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    private var controlsBar: some View {
        HStack {
            Button(action: { viewModel.toggleEarthTexture() }) {
                VStack(spacing: 4) {
                    Image(systemName: viewModel.showingSatellite ? "map" : "map.fill")
                        .font(.system(size: 16, weight: .medium))
                    Text(viewModel.showingSatellite ? "Map" : "Satellite")
                        .font(.system(size: 10, weight: .medium))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.4))
                .cornerRadius(8)
            }
            
            Spacer()
            
            Button(action: { viewModel.toggleFlightPaths() }) {
                VStack(spacing: 4) {
                    Image(systemName: viewModel.showingFlightPaths ? "arrow.triangle.turn.up.right.diamond" : "arrow.triangle.turn.up.right.diamond.fill")
                        .font(.system(size: 16, weight: .medium))
                    Text("Flight Paths")
                        .font(.system(size: 10, weight: .medium))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.4))
                .cornerRadius(8)
            }
            
            Spacer()
            
            Button(action: { viewModel.toggleWeatherLayer() }) {
                VStack(spacing: 4) {
                    Image(systemName: viewModel.showingWeather ? "cloud.sun" : "cloud.sun.fill")
                        .font(.system(size: 16, weight: .medium))
                    Text("Weather")
                        .font(.system(size: 10, weight: .medium))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.4))
                .cornerRadius(8)
            }
            
            Spacer()
            
            Button(action: { viewModel.resetCamera() }) {
                VStack(spacing: 4) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 16, weight: .medium))
                    Text("Reset")
                        .font(.system(size: 10, weight: .medium))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.4))
                .cornerRadius(8)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(BlurView(style: .systemThinMaterial))
    }
    
    private var flightInfoPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let flight = viewModel.selectedFlight {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(flight.airline) \(flight.flightNumber)")
                            .font(.system(.headline, design: .rounded))
                            .bold()
                        
                        Text("\(flight.departureAirport) → \(flight.arrivalAirport)")
                            .font(.system(.subheadline, design: .rounded))
                    }
                    
                    Spacer()
                    
                    Button(action: { viewModel.selectedFlight = nil }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.secondary)
                    }
                }
                
                Divider()
                
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Altitude")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                        Text("\(flight.altitude) ft")
                            .font(.system(.body, design: .rounded))
                            .bold()
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Speed")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                        Text("\(flight.speed) kts")
                            .font(.system(.body, design: .rounded))
                            .bold()
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Heading")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                        Text("\(flight.heading)°")
                            .font(.system(.body, design: .rounded))
                            .bold()
                    }
                }
                
                Button(action: { viewModel.focusOnFlight(flight) }) {
                    HStack {
                        Image(systemName: "location.fill")
                        Text("Focus on Flight")
                    }
                    .font(.system(.subheadline, design: .rounded))
                    .bold()
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.accentColor)
                    .cornerRadius(8)
                }
            }
        }
        .padding(16)
        .background(BlurView(style: .systemThinMaterial))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.2), radius: 15, x: 0, y: 5)
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
    
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                LottieView(name: "globe_loading", loopMode: .loop)
                    .frame(width: 120, height: 120)
                
                Text("Loading flight data...")
                    .font(.system(.headline, design: .rounded))
                    .foregroundColor(.white)
            }
            .padding(30)
            .background(BlurView(style: .systemMaterial))
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
        }
    }
    
    private var zoomControls: some View {
        VStack {
            Button(action: { viewModel.zoomIn() }) {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.black.opacity(0.4))
                    .clipShape(Circle())
            }
            .padding(.bottom, 10)
            
            Button(action: { viewModel.zoomOut() }) {
                Image(systemName: "minus")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.black.opacity(0.4))
                    .clipShape(Circle())
            }
        }
        .padding(20)
        .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
    }
    
    // MARK: - Interaction Handlers
    
    private func handleDrag(_ value: DragGesture.Value) {
        if let lastPosition = lastDragPosition {
            let deltaX = Float(value.location.x - lastPosition.x) * 0.01
            let deltaY = Float(value.location.y - lastPosition.y) * 0.01
            
            viewModel.rotateGlobe(x: deltaY, y: deltaX)
        }
        
        lastDragPosition = value.location
    }
    
    private func handleZoom(_ value: MagnificationGesture.Value) {
        viewModel.zoom(factor: Float(value / scale))
        scale = value
    }
}

// MARK: - Support Views

/// UIKit blur view for SwiftUI integration
// NOTE: Using BlurView from Models/SharedModels.swift 

/// Simple animation loop mode enum to replace Lottie's loop mode
enum AnimationLoopMode {
    case playOnce
    case loop
    case autoReverse
}

/// Custom animation view for loading animations
struct LottieView: UIViewRepresentable {
    var name: String
    var loopMode: AnimationLoopMode = .playOnce
    
    func makeUIView(context: UIViewRepresentableContext<LottieView>) -> UIView {
        let view = UIView()
        // In a real implementation, this would use Lottie
        // For now, we'll show a simple activity indicator
        let activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.startAnimating()
        activityIndicator.center = view.center
        view.addSubview(activityIndicator)
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<LottieView>) {
        // Update animation if needed
        // In a real implementation, this would update Lottie animation properties
        // For our simplified version, we'll just ensure the activity indicator is running
        if let activityIndicator = uiView.subviews.first as? UIActivityIndicatorView {
            if !activityIndicator.isAnimating {
                activityIndicator.startAnimating()
            }
        }
    }
}

/// Custom SceneView wrapper with built-in tap gesture handling
struct CustomSceneView: UIViewRepresentable {
    var scene: SCNScene
    var pointOfView: SCNNode?
    var options: SceneView.Options
    var onTap: (CGPoint, [SCNHitTestResult]) -> Void
    
    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.scene = scene
        scnView.pointOfView = pointOfView
        scnView.allowsCameraControl = options.contains(.allowsCameraControl)
        scnView.autoenablesDefaultLighting = options.contains(.autoenablesDefaultLighting)
        
        // Add tap gesture recognizer
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        scnView.addGestureRecognizer(tapGesture)
        
        return scnView
    }
    
    func updateUIView(_ scnView: SCNView, context: Context) {
        scnView.scene = scene
        scnView.pointOfView = pointOfView
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        var parent: CustomSceneView
        
        init(_ parent: CustomSceneView) {
            self.parent = parent
        }
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let scnView = gesture.view as? SCNView else { return }
            let location = gesture.location(in: scnView)
            let hitResults = scnView.hitTest(location, options: [:])
            parent.onTap(location, hitResults)
        }
    }
}

// MARK: - View Model

/// View model for the 3D globe visualization
class FlightGlobeViewModel: ObservableObject {
    @Published var scene: SCNScene
    @Published var cameraNode: SCNNode
    @Published var isLoading: Bool = false
    @Published var selectedFlight: FlightGlobeData?
    @Published var showingSatellite: Bool = true
    @Published var showingFlightPaths: Bool = true
    @Published var showingWeather: Bool = false
    
    private var flights: [FlightGlobeData] = []
    private var flightNodes: [String: SCNNode] = [:]
    private var earthNode: SCNNode?
    private var weatherNode: SCNNode?
    
    init() {
        scene = SCNScene()
        
        // Setup camera
        cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.zFar = 1000
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 15)
        
        // Add ambient light
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light?.type = .ambient
        ambientLightNode.light?.intensity = 30
        ambientLightNode.light?.temperature = 5500
        scene.rootNode.addChildNode(ambientLightNode)
        
        // Add directional light (sun)
        let sunLightNode = SCNNode()
        sunLightNode.light = SCNLight()
        sunLightNode.light?.type = .directional
        sunLightNode.light?.intensity = 800
        sunLightNode.light?.temperature = 6500
        sunLightNode.light?.castsShadow = true
        sunLightNode.position = SCNVector3(x: 15, y: 15, z: 15)
        sunLightNode.eulerAngles = SCNVector3(x: -Float.pi/4, y: Float.pi/4, z: 0)
        scene.rootNode.addChildNode(sunLightNode)
    }
    
    func setupScene() {
        isLoading = true
        
        // Create earth
        createEarth()
        
        // Add stars background
        createStars()
        
        // Load sample flights for now
        loadFlights()
        
        isLoading = false
    }
    
    private func createEarth() {
        let earthGeometry = SCNSphere(radius: 5)
        let earthMaterial = SCNMaterial()
        
        // Set texture based on mode
        if showingSatellite {
            earthMaterial.diffuse.contents = UIImage(named: "earth_satellite")
        } else {
            earthMaterial.diffuse.contents = UIImage(named: "earth_map")
        }
        
        earthMaterial.specular.contents = UIColor.white
        earthMaterial.shininess = 0.1
        earthGeometry.materials = [earthMaterial]
        
        earthNode = SCNNode(geometry: earthGeometry)
        scene.rootNode.addChildNode(earthNode!)
        
        // Add subtle rotation animation
        let rotationAction = SCNAction.rotateBy(x: 0, y: 2 * CGFloat.pi, z: 0, duration: 240)
        let repeatAction = SCNAction.repeatForever(rotationAction)
        earthNode?.runAction(repeatAction)
    }
    
    private func createStars() {
        let starsGeometry = SCNSphere(radius: 100)
        let starsMaterial = SCNMaterial()
        starsMaterial.diffuse.contents = UIImage(named: "stars_background")
        starsMaterial.isDoubleSided = true
        starsGeometry.materials = [starsMaterial]
        
        let starsNode = SCNNode(geometry: starsGeometry)
        scene.rootNode.addChildNode(starsNode)
    }
    
    private func loadFlights() {
        // For demo purposes, we'll use sample data
        // In a real implementation, this would fetch from the API
        flights = [
            FlightGlobeData(id: "BA123", airline: "British Airways", flightNumber: "123", 
                           departureAirport: "LHR", arrivalAirport: "JFK",
                           latitude: 51.5074, longitude: -20.1278, altitude: 35000,
                           speed: 520, heading: 270),
            
            FlightGlobeData(id: "UA456", airline: "United Airlines", flightNumber: "456", 
                           departureAirport: "SFO", arrivalAirport: "NRT",
                           latitude: 37.7749, longitude: -142.4194, altitude: 38000,
                           speed: 540, heading: 305),
            
            FlightGlobeData(id: "SQ21", airline: "Singapore Airlines", flightNumber: "21", 
                           departureAirport: "SIN", arrivalAirport: "EWR",
                           latitude: 28.6139, longitude: 77.2090, altitude: 41000,
                           speed: 560, heading: 330),
            
            FlightGlobeData(id: "QF8", airline: "Qantas", flightNumber: "8", 
                          departureAirport: "SYD", arrivalAirport: "DFW",
                          latitude: -10.7810, longitude: -150.5129, altitude: 36000,
                          speed: 530, heading: 35)
        ]
        
        // Create 3D nodes for each flight
        for flight in flights {
            addFlightToScene(flight)
        }
        
        // Add flight paths if enabled
        if showingFlightPaths {
            addFlightPaths()
        }
        
        // Add weather if enabled
        if showingWeather {
            addWeatherLayer()
        }
    }
    
    private func addFlightToScene(_ flight: FlightGlobeData) {
        // Convert lat/long to 3D coordinates
        let flightPosition = coordinateToVector(latitude: flight.latitude, longitude: flight.longitude)
        
        // Create airplane node
        let airplaneGeometry = SCNCone(topRadius: 0, bottomRadius: 0.04, height: 0.1)
        let airplaneMaterial = SCNMaterial()
        airplaneMaterial.diffuse.contents = UIColor.white
        airplaneGeometry.materials = [airplaneMaterial]
        
        let airplaneNode = SCNNode(geometry: airplaneGeometry)
        airplaneNode.position = SCNVector3(flightPosition.x * 5.1, flightPosition.y * 5.1, flightPosition.z * 5.1)
        
        // Set proper orientation based on heading
        let orientationNode = SCNNode()
        orientationNode.addChildNode(airplaneNode)
        
        // Rotate to point in direction of flight
        orientationNode.eulerAngles = SCNVector3(0, Float(flight.heading) * .pi / 180, 0)
        
        // Add to scene
        earthNode?.addChildNode(orientationNode)
        flightNodes[flight.id] = orientationNode
    }
    
    private func addFlightPaths() {
        // For demo purposes, we'll add simple paths
        // A real implementation would use actual flight paths
        
        for flight in flights {
            // Create departure and arrival points
            let departureCoordinates = getAirportCoordinates(code: flight.departureAirport)
            let arrivalCoordinates = getAirportCoordinates(code: flight.arrivalAirport)
            
            let departureVector = coordinateToVector(latitude: departureCoordinates.latitude, longitude: departureCoordinates.longitude)
            let arrivalVector = coordinateToVector(latitude: arrivalCoordinates.latitude, longitude: arrivalCoordinates.longitude)
            
            // Create path
            let path = SCNGeometry.lineFrom(
                vector: SCNVector3(departureVector.x * 5.05, departureVector.y * 5.05, departureVector.z * 5.05),
                toVector: SCNVector3(arrivalVector.x * 5.05, arrivalVector.y * 5.05, arrivalVector.z * 5.05),
                width: 1
            )
            
            let pathNode = SCNNode(geometry: path)
            earthNode?.addChildNode(pathNode)
        }
    }
    
    private func addWeatherLayer() {
        // In a real implementation, this would add actual weather data
        // For now, we'll add a simple cloud layer
        
        let cloudsGeometry = SCNSphere(radius: 5.2)
        let cloudsMaterial = SCNMaterial()
        cloudsMaterial.diffuse.contents = UIImage(named: "clouds_layer")
        cloudsMaterial.transparency = 0.6
        cloudsMaterial.transparencyMode = .rgbZero
        cloudsGeometry.materials = [cloudsMaterial]
        
        weatherNode = SCNNode(geometry: cloudsGeometry)
        scene.rootNode.addChildNode(weatherNode!)
        
        // Add subtle rotation animation, slightly faster than Earth
        let rotationAction = SCNAction.rotateBy(x: 0, y: 2 * CGFloat.pi, z: 0, duration: 220)
        let repeatAction = SCNAction.repeatForever(rotationAction)
        weatherNode?.runAction(repeatAction)
    }
    
    // MARK: - Control Functions
    
    func rotateGlobe(x: Float, y: Float) {
        earthNode?.eulerAngles.x += x
        earthNode?.eulerAngles.y += y
        
        // Keep weather in sync if present
        if let weatherNode = weatherNode {
            weatherNode.eulerAngles.x += x
            weatherNode.eulerAngles.y += y
        }
    }
    
    func zoom(factor: Float) {
        let currentZ = cameraNode.position.z
        let newZ = currentZ / factor
        
        // Limit zoom range
        if newZ > 6 && newZ < 30 {
            cameraNode.position.z = newZ
        }
    }
    
    func zoomIn() {
        let currentZ = cameraNode.position.z
        if currentZ > 6 {
            cameraNode.position.z = currentZ * 0.8
        }
    }
    
    func zoomOut() {
        let currentZ = cameraNode.position.z
        if currentZ < 30 {
            cameraNode.position.z = currentZ * 1.2
        }
    }
    
    func resetCamera() {
        // Animate camera back to starting position
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 1.0
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 15)
        
        SCNTransaction.commit()
    }
    
    func toggleEarthTexture() {
        showingSatellite.toggle()
        
        // Update earth texture
        if let material = earthNode?.geometry?.materials.first {
            material.diffuse.contents = showingSatellite ? UIImage(named: "earth_satellite") : UIImage(named: "earth_map")
        }
    }
    
    func toggleFlightPaths() {
        showingFlightPaths.toggle()
        
        // Remove existing paths and re-add if enabled
        // In a real implementation, this would be more sophisticated
        // For simplicity, we'll just reload the flights
        
        // Clear existing flights
        for (_, node) in flightNodes {
            node.removeFromParentNode()
        }
        flightNodes.removeAll()
        
        // Reload flights
        loadFlights()
    }
    
    func toggleWeatherLayer() {
        showingWeather.toggle()
        
        if showingWeather {
            if weatherNode == nil {
                addWeatherLayer()
            } else {
                weatherNode?.isHidden = false
            }
        } else {
            weatherNode?.isHidden = true
        }
    }
    
    func focusOnFlight(_ flight: FlightGlobeData) {
        selectedFlight = flight
        
        // Convert lat/long to 3D coordinates
        let flightPosition = coordinateToVector(latitude: flight.latitude, longitude: flight.longitude)
        
        // Calculate camera position to view flight
        let cameraPosition = SCNVector3(
            flightPosition.x * 8,
            flightPosition.y * 8,
            flightPosition.z * 8
        )
        
        // Animate camera to new position
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 1.0
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        cameraNode.position = cameraPosition
        cameraNode.look(at: SCNVector3(flightPosition.x * 5.1, flightPosition.y * 5.1, flightPosition.z * 5.1))
        
        SCNTransaction.commit()
    }
    
    // Method to add and focus on a custom flight from outside the globe view
    func focusOnCustomFlight(_ flight: FlightGlobeData) {
        // First remove any existing flight with this ID to avoid duplicates
        if let existingIndex = flights.firstIndex(where: { $0.id == flight.id }) {
            if let node = flightNodes[flight.id] {
                node.removeFromParentNode()
                flightNodes.removeValue(forKey: flight.id)
            }
            flights.remove(at: existingIndex)
        }
        
        // Print debug info
        print("Adding flight to globe: \(flight.flightNumber) at lat: \(flight.latitude), long: \(flight.longitude)")
        
        // Add the flight to our list
        flights.append(flight)
        
        // Create a more visible airplane node for selected flights
        let flightPosition = coordinateToVector(latitude: flight.latitude, longitude: flight.longitude)
        
        // Create a larger, more visible airplane node
        let airplaneGeometry = SCNCone(topRadius: 0, bottomRadius: 0.08, height: 0.2)
        let airplaneMaterial = SCNMaterial()
        airplaneMaterial.diffuse.contents = UIColor.orange // Using a bright color for visibility
        airplaneGeometry.materials = [airplaneMaterial]
        
        let airplaneNode = SCNNode(geometry: airplaneGeometry)
        airplaneNode.position = SCNVector3(flightPosition.x * 5.1, flightPosition.y * 5.1, flightPosition.z * 5.1)
        
        // Add a pulsing highlight effect
        let highlightGeometry = SCNSphere(radius: 0.1)
        let highlightMaterial = SCNMaterial()
        highlightMaterial.diffuse.contents = UIColor.red
        highlightMaterial.emission.contents = UIColor.red
        highlightMaterial.transparency = 0.7
        highlightGeometry.materials = [highlightMaterial]
        
        let highlightNode = SCNNode(geometry: highlightGeometry)
        highlightNode.position = SCNVector3Zero
        
        // Add pulse animation to highlight
        let pulseAction = SCNAction.sequence([
            SCNAction.scale(to: 1.5, duration: 0.5),
            SCNAction.scale(to: 1.0, duration: 0.5)
        ])
        let repeatPulse = SCNAction.repeatForever(pulseAction)
        highlightNode.runAction(repeatPulse)
        
        airplaneNode.addChildNode(highlightNode)
        
        // Set proper orientation based on heading
        let orientationNode = SCNNode()
        orientationNode.addChildNode(airplaneNode)
        
        // Rotate to point in direction of flight
        orientationNode.eulerAngles = SCNVector3(0, Float(flight.heading) * .pi / 180, 0)
        
        // Add to scene
        earthNode?.addChildNode(orientationNode)
        flightNodes[flight.id] = orientationNode
        
        // Set as selected flight
        selectedFlight = flight
        
        // Focus camera on this flight
        focusOnFlight(flight)
        
        // Add a flight path for this flight
        addCustomFlightPath(flight)
    }
    
    // Add a visible path for the custom flight
    private func addCustomFlightPath(_ flight: FlightGlobeData) {
        // Create departure and arrival points
        let departureCoordinates = getAirportCoordinates(code: flight.departureAirport)
        let arrivalCoordinates = getAirportCoordinates(code: flight.arrivalAirport)
        
        let departureVector = coordinateToVector(latitude: departureCoordinates.latitude, longitude: departureCoordinates.longitude)
        let arrivalVector = coordinateToVector(latitude: arrivalCoordinates.latitude, longitude: arrivalCoordinates.longitude)
        
        // Create a more visible path
        let path = SCNGeometry.lineFrom(
            vector: SCNVector3(departureVector.x * 5.05, departureVector.y * 5.05, departureVector.z * 5.05),
            toVector: SCNVector3(arrivalVector.x * 5.05, arrivalVector.y * 5.05, arrivalVector.z * 5.05),
            width: 2 // Wider line for better visibility
        )
        
        // Create material with bright color
        let pathMaterial = SCNMaterial()
        pathMaterial.diffuse.contents = UIColor.red
        pathMaterial.emission.contents = UIColor.red // Makes it glow
        path.materials = [pathMaterial]
        
        let pathNode = SCNNode(geometry: path)
        
        // Add to scene
        earthNode?.addChildNode(pathNode)
    }
    
    // MARK: - Helper Functions
    
    private func coordinateToVector(latitude: Double, longitude: Double) -> SCNVector3 {
        // Convert latitude and longitude to 3D coordinates on a unit sphere
        let latRad = latitude * .pi / 180
        let lonRad = longitude * .pi / 180
        
        let x = cos(latRad) * cos(lonRad)
        let y = sin(latRad)
        let z = cos(latRad) * sin(lonRad)
        
        return SCNVector3(x, y, z)
    }
    
    private func getAirportCoordinates(code: String) -> (latitude: Double, longitude: Double) {
        // This would be a lookup from a real airport database
        // For demo purposes, we'll use placeholder coordinates
        
        switch code {
        case "LHR": return (51.4700, -0.4543)
        case "JFK": return (40.6413, -73.7781)
        case "SFO": return (37.6213, -122.3790)
        case "NRT": return (35.7647, 140.3863)
        case "SIN": return (1.3644, 103.9915)
        case "EWR": return (40.6895, -74.1745)
        case "SYD": return (-33.9399, 151.1753)
        case "DFW": return (32.8998, -97.0403)
        default: return (0, 0)
        }
    }
    
    // Process tap gesture hit results
    func handleTapResults(_ hitResults: [SCNHitTestResult]) {
        if let firstHit = hitResults.first {
            // Find which flight was tapped
            for flight in flights {
                if flightNodes[flight.id] == firstHit.node || 
                   firstHit.node.parent == flightNodes[flight.id] ||
                   isNode(firstHit.node, descendantOf: flightNodes[flight.id]) {
                    selectedFlight = flight
                    return
                }
            }
        }
    }
    
    // Helper method to check if a node is a descendant of another node
    private func isNode(_ node: SCNNode?, descendantOf possibleAncestor: SCNNode?) -> Bool {
        guard let node = node, let ancestor = possibleAncestor else { return false }
        
        var current = node.parent
        while let parent = current {
            if parent === ancestor {
                return true
            }
            current = parent.parent
        }
        return false
    }
}

// MARK: - Data Models

struct FlightGlobeData: Identifiable {
    let id: String
    let airline: String
    let flightNumber: String
    let departureAirport: String
    let arrivalAirport: String
    let latitude: Double
    let longitude: Double
    let altitude: Int
    let speed: Int
    let heading: Int
}

// MARK: - Extensions

extension SCNVector3 {
    func normalized() -> SCNVector3 {
        let length = sqrt(x*x + y*y + z*z)
        return SCNVector3(x/length, y/length, z/length)
    }
}

extension SCNGeometry {
    class func lineFrom(vector vector1: SCNVector3, toVector vector2: SCNVector3, width: CGFloat) -> SCNGeometry {
        let indices: [Int32] = [0, 1]
        
        let source = SCNGeometrySource(vertices: [vector1, vector2])
        let element = SCNGeometryElement(indices: indices, primitiveType: .line)
        
        let line = SCNGeometry(sources: [source], elements: [element])
        
        let material = SCNMaterial()
        material.diffuse.contents = UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 0.7)
        material.emission.contents = UIColor(red: 0.0, green: 0.6, blue: 1.0, alpha: 0.7)
        line.materials = [material]
        
        return line
    }
} 