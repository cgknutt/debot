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
        // Check if we have a token in the configuration file
        if let token = readTokenFromConfig() {
            return token
        }
        
        // If not, create a template configuration file and return a placeholder
        createTemplateConfigFile()
        return "REPLACE_WITH_YOUR_SLACK_BOT_TOKEN"
    }
    
    /// Read the token from the configuration file
    private func readTokenFromConfig() -> String? {
        guard let configURL = getConfigFileURL(),
              FileManager.default.fileExists(atPath: configURL.path) else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: configURL)
            if let plist = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: String] {
                return plist["SLACK_BOT_TOKEN"]
            }
        } catch {
            print("Error reading Slack config file: \(error)")
        }
        
        return nil
    }
    
    /// Create a template configuration file with instructions
    private func createTemplateConfigFile() {
        guard let configURL = getConfigFileURL() else { return }
        
        // Only create if it doesn't exist
        guard !FileManager.default.fileExists(atPath: configURL.path) else { return }
        
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
    private func getConfigFileURL() -> URL? {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Could not access documents directory")
            return nil
        }
        
        return documentsDirectory.appendingPathComponent(configFileName)
    }
} 