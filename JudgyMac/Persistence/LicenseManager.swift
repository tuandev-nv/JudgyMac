import Foundation
import CryptoKit

/// Validates license keys via LemonSqueezy License API.
@MainActor
enum LicenseManager {
    private static let validateURL = URL(string: "https://api.lemonsqueezy.com/v1/licenses/validate")!

    /// Hash a license key for secure local storage
    nonisolated static func hashKey(_ key: String) -> String {
        let salt = "JudgyMac202613040303"
        let data = Data((key + salt).utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }

    /// Verify a stored hash matches a key
    nonisolated static func verifyHash(_ key: String, storedHash: String) -> Bool {
        hashKey(key) == storedHash
    }

    enum Result {
        case valid
        case invalid
        case error(String)
    }

    /// Validate a license key against LemonSqueezy License API.
    static func validate(key: String) async -> Result {
        let trimmedKey = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty else {
            return .invalid
        }

        // Dev mode: accept "DEV" key
        #if DEBUG
        if trimmedKey.uppercased() == "DEV" {
            return .valid
        }
        #endif

        var request = URLRequest(url: validateURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let bodyString = "license_key=\(trimmedKey)"
        request.httpBody = bodyString.data(using: .utf8)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                return .error("Invalid response")
            }

            if httpResponse.statusCode == 200 {
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let valid = json["valid"] as? Bool,
                   valid {
                    return .valid
                }
                return .invalid
            } else {
                return .invalid
            }
        } catch {
            return .error(error.localizedDescription)
        }
    }
}
