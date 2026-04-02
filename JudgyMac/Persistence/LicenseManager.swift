import Foundation
import CryptoKit

/// Validates license keys via Polar.sh API.
@MainActor
enum LicenseManager {
    private static let organizationId = "87153ee2-de7a-473a-bc5d-e150e027e4f0"
    private static let validateURL = URL(string: "https://api.polar.sh/v1/customer-portal/license-keys/validate")!
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

    /// Validate a license key against Polar.sh API.
    static func validate(key: String) async -> Result {
        guard !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .invalid
        }

        // Dev mode: accept "DEV" key
        #if DEBUG
        if key.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() == "DEV" {
            return .valid
        }
        #endif

        var request = URLRequest(url: validateURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: String] = [
            "key": key.trimmingCharacters(in: .whitespacesAndNewlines),
            "organization_id": organizationId,
        ]

        guard let httpBody = try? JSONSerialization.data(withJSONObject: body) else {
            return .error("Failed to encode request")
        }
        request.httpBody = httpBody

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                return .error("Invalid response")
            }

            if httpResponse.statusCode == 200 {
                // Polar returns the license key object if valid
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let status = json["status"] as? String,
                   status == "granted" {
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
