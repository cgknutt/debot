import Foundation

/// Manages secure access to the Slack API token
/// This approach keeps the token out of source control
class SlackTokenManager {
    static let shared = SlackTokenManager()
    
    private init() {}
    
    /// The name of the configuration file (will be added to .gitignore)
    private let configFileName = "SlackConfig.plist"
    
    /// Returns the API token from the configuration file
    /// If the file doesn't exist, it creates a template file
    func getToken() -> String {
        print("\n--- SLACK TOKEN MANAGER: Looking for token ---")
        
        // Try multiple locations for the token file
        let token = tryMultipleTokenLocations()
        if let token = token, isValidToken(token) {
            // Only show part of the token for security
            if token.count > 10 {
                let prefix = String(token.prefix(10))
                print("Found valid token (starting with \(prefix)...)")
            } else {
                print("Found token but it seems too short")
            }
            return token
        }
        
        // Check if we have a token in the configuration file
        if let token = readTokenFromConfig(), isValidToken(token) {
            print("Found token in primary location")
            return token
        }
        
        // If not, create a template configuration file and return a placeholder
        print("⚠️ No token found, creating template file")
        createTemplateConfigFile()
        return "REPLACE_WITH_YOUR_SLACK_BOT_TOKEN"
    }
    
    /// Validate that the token looks like a Slack bot token
    private func isValidToken(_ token: String) -> Bool {
        // Basic validation - should start with xoxb- and be a reasonable length
        let isValid = token.hasPrefix("xoxb-") && token.count > 20
        
        if !isValid && token != "REPLACE_WITH_YOUR_SLACK_BOT_TOKEN" {
            print("⚠️ WARNING: Token doesn't appear to be a valid Slack bot token")
            print("⚠️ Slack bot tokens should start with 'xoxb-' and be longer than 20 characters")
        }
        
        return isValid || token == "REPLACE_WITH_YOUR_SLACK_BOT_TOKEN"
    }
    
    /// Try to find the token in multiple common locations
    private func tryMultipleTokenLocations() -> String? {
        // List of possible locations to check
        let locations = [
            // App's documents directory (most reliable location)
            FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?
                .appendingPathComponent(configFileName).path,
            
            // App bundle directory
            ResourceFinder.findResourcePath(name: "SlackConfig", ext: "plist"),
            
            // App's container directory
            FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
                .appendingPathComponent("debot")
                .appendingPathComponent(configFileName).path,
            
            // Current directory
            FileManager.default.currentDirectoryPath + "/\(configFileName)",
            
            // Project directory
            FileManager.default.currentDirectoryPath + "/debot/\(configFileName)",
        ]
        
        // Try each location
        for (index, locationPath) in locations.enumerated() {
            if let path = locationPath, FileManager.default.fileExists(atPath: path) {
                print("Checking location \(index+1): \(path) - EXISTS")
                
                // Check if file is readable
                if FileManager.default.isReadableFile(atPath: path) {
                    if let token = readTokenFromFile(path: path) {
                        print("Found token at location \(index+1)")
                        return token
                    } else {
                        print("Location \(index+1) exists but token couldn't be read")
                    }
                } else {
                    print("⚠️ File at location \(index+1) exists but is not readable!")
                }
            } else if let path = locationPath {
                print("Checking location \(index+1): \(path) - NOT FOUND")
            } else {
                print("Checking location \(index+1): path is nil")
            }
        }
        
        return nil
    }
    
    /// Read token from a specific path
    private func readTokenFromFile(path: String) -> String? {
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            if let plist = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: String],
               let token = plist["SLACK_BOT_TOKEN"] {
                if token != "REPLACE_WITH_YOUR_SLACK_BOT_TOKEN" {
                    return token
                } else {
                    print("Found placeholder token in \(path)")
                }
            }
        } catch {
            print("Error reading token from \(path): \(error)")
        }
        return nil
    }
    
    /// Read the token from the configuration file
    private func readTokenFromConfig() -> String? {
        guard let configURL = getConfigFileURL() else {
            print("Could not get config file URL")
            return nil
        }
        
        let path = configURL.path
        print("Reading from primary config location: \(path)")
        
        if !FileManager.default.fileExists(atPath: path) {
            print("File does not exist at \(path)")
            return nil
        }
        
        do {
            let data = try Data(contentsOf: configURL)
            if let plist = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: String],
               let token = plist["SLACK_BOT_TOKEN"] {
                if token != "REPLACE_WITH_YOUR_SLACK_BOT_TOKEN" {
                    return token
                } else {
                    print("Found placeholder token in primary location")
                }
            } else {
                print("Could not parse plist data or find token key")
            }
        } catch {
            print("Error reading Slack config file: \(error)")
        }
        
        return nil
    }
    
    /// Create a template configuration file with instructions
    private func createTemplateConfigFile() {
        guard let configURL = getConfigFileURL() else {
            print("Could not get config file URL to create template")
            return
        }
        
        // Only create if it doesn't exist
        let path = configURL.path
        if FileManager.default.fileExists(atPath: path) {
            print("Template file already exists at \(path)")
            return
        }
        
        let plist: [String: String] = [
            "SLACK_BOT_TOKEN": "REPLACE_WITH_YOUR_SLACK_BOT_TOKEN",
            "INSTRUCTIONS": "Replace the token value and DO NOT commit this file to git"
        ]
        
        do {
            let data = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
            try data.write(to: configURL)
            
            print("⚠️ IMPORTANT: A template SlackConfig.plist file has been created at: \(configURL.path)")
            print("⚠️ Please add your Slack bot token to this file and ensure it's not committed to git")
            print("⚠️ Add 'SlackConfig.plist' to your .gitignore file")
        } catch {
            print("Error creating Slack config template file: \(error)")
        }
    }
    
    /// Get the URL for the configuration file
    func getConfigFileURL() -> URL? {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Could not access documents directory")
            return nil
        }
        
        let url = documentsDirectory.appendingPathComponent(configFileName)
        print("Config file URL: \(url.path)")
        return url
    }
    
    /// Saves a new token to the configuration file
    func saveToken(_ token: String) -> Bool {
        print("\n--- SLACK TOKEN MANAGER: Saving new token ---")
        
        guard let configURL = getConfigFileURL() else {
            print("Could not get config file URL to save token")
            return false
        }
        
        let plist: [String: String] = [
            "SLACK_BOT_TOKEN": token,
            "INSTRUCTIONS": "This file contains your Slack Bot token. DO NOT commit it to git."
        ]
        
        do {
            let data = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
            try data.write(to: configURL)
            
            print("✅ Successfully saved new token to \(configURL.path)")
            return true
        } catch {
            print("Error saving token: \(error)")
            return false
        }
    }
} 