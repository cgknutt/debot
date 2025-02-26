import Foundation

@MainActor
class AviationViewModel: ObservableObject {
    private let aviationService = AviationService()
    
    @Published var currentFlight: Flight?
    @Published var isLoading = false
    @Published var error: String?
    
    func fetchRandomFlight() {
        print("Starting to fetch random flight...")
        self.isLoading = true
        self.error = nil
        
        Task { [self] in
            do {
                print("Making API request...")
                self.currentFlight = try await aviationService.getRandomFlight()
                print("Successfully fetched flight data")
            } catch AviationService.AviationError.noData {
                print("Error: No flights found")
                self.error = "No flights found"
            } catch AviationService.AviationError.apiError(let message) {
                print("API Error: \(message)")
                self.error = "API Error: \(message)"
            } catch AviationService.AviationError.invalidURL {
                print("Error: Invalid URL configuration")
                self.error = "Invalid API URL configuration"
            } catch AviationService.AviationError.decodingError {
                print("Error: Failed to decode flight data")
                self.error = "Failed to process the flight data"
            } catch {
                print("Unexpected error: \(error)")
                self.error = "An unexpected error occurred: \(error.localizedDescription)"
            }
            self.isLoading = false
            print("Finished fetch attempt")
        }
    }

    func fetchRandomFlight() async {
        do {
            let flight = try await aviationService.getRandomFlight()
            await MainActor.run {
                self.currentFlight = flight
            }
        } catch {
            print("Error fetching flight: \(error)")
        }
    }
} 