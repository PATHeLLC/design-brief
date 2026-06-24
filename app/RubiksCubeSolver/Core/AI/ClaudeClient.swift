import Foundation

/// Minimal async client for the Anthropic Messages API with vision + tool-use
/// support, prompt caching, and exponential-backoff retry on 429/5xx.
///
/// Intentionally narrow: this app only needs one endpoint. Reaches for
/// `URLSession` directly rather than pulling in the Anthropic Swift SDK to
/// keep the binary small and the dependency graph trivial.
public struct ClaudeClient {
    public struct Configuration {
        public var apiKeyProvider: () -> String?
        public var baseURL: URL
        public var session: URLSession
        public var anthropicVersion: String

        public init(
            apiKeyProvider: @escaping () -> String?,
            baseURL: URL = URL(string: "https://api.anthropic.com/v1/messages")!,
            session: URLSession = .shared,
            anthropicVersion: String = "2023-06-01"
        ) {
            self.apiKeyProvider = apiKeyProvider
            self.baseURL = baseURL
            self.session = session
            self.anthropicVersion = anthropicVersion
        }
    }

    public let config: Configuration

    public init(config: Configuration) { self.config = config }

    // MARK: - Request model

    public struct Request: Encodable {
        public var model: String
        public var maxTokens: Int
        public var system: [SystemBlock]?
        public var messages: [Message]
        public var tools: [Tool]?
        public var toolChoice: ToolChoice?
        public var temperature: Double?

        enum CodingKeys: String, CodingKey {
            case model
            case maxTokens = "max_tokens"
            case system
            case messages
            case tools
            case toolChoice = "tool_choice"
            case temperature
        }
    }

    public struct SystemBlock: Encodable {
        public var type: String = "text"
        public var text: String
        public var cacheControl: CacheControl?

        enum CodingKeys: String, CodingKey {
            case type, text
            case cacheControl = "cache_control"
        }
    }

    public struct CacheControl: Encodable {
        public var type: String = "ephemeral"
    }

    public struct Message: Encodable {
        public var role: String  // "user" or "assistant"
        public var content: [ContentBlock]
    }

    public enum ContentBlock: Encodable {
        case text(String)
        case image(mediaType: String, base64: String)

        public func encode(to encoder: Encoder) throws {
            var c = encoder.container(keyedBy: K.self)
            switch self {
            case .text(let s):
                try c.encode("text", forKey: .type)
                try c.encode(s, forKey: .text)
            case .image(let media, let data):
                try c.encode("image", forKey: .type)
                var src = c.nestedContainer(keyedBy: K.self, forKey: .source)
                try src.encode("base64", forKey: .type)
                try src.encode(media, forKey: .media_type)
                try src.encode(data, forKey: .data)
            }
        }
        private enum K: String, CodingKey {
            case type, text, source, media_type, data
        }
    }

    public struct Tool: Encodable {
        public var name: String
        public var description: String
        public var inputSchema: JSONValue

        enum CodingKeys: String, CodingKey {
            case name, description
            case inputSchema = "input_schema"
        }
    }

    public struct ToolChoice: Encodable {
        public var type: String  // "tool" to force a specific tool
        public var name: String?
    }

    // MARK: - Response model

    public struct Response: Decodable {
        public var content: [ResponseBlock]
        public var stopReason: String?

        enum CodingKeys: String, CodingKey {
            case content
            case stopReason = "stop_reason"
        }
    }

    public struct ResponseBlock: Decodable {
        public var type: String
        public var text: String?
        public var name: String?         // tool_use name
        public var input: JSONValue?     // tool_use input
    }

    // MARK: - Send

    public enum ClientError: Error, LocalizedError {
        case missingAPIKey
        case http(status: Int, body: String)
        case decoding(Error)
        case transport(Error)

        public var errorDescription: String? {
            switch self {
            case .missingAPIKey: return "No Anthropic API key configured. Add one in Settings."
            case .http(let s, let b): return "Claude API returned \(s): \(b.prefix(200))"
            case .decoding(let e): return "Failed to decode Claude response: \(e.localizedDescription)"
            case .transport(let e): return "Network error: \(e.localizedDescription)"
            }
        }
    }

    public func send(_ request: Request, maxAttempts: Int = 3) async throws -> Response {
        guard let key = config.apiKeyProvider(), !key.isEmpty else {
            throw ClientError.missingAPIKey
        }

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .useDefaultKeys
        let body = try encoder.encode(request)

        var attempt = 0
        var delay: TimeInterval = 1.0
        while true {
            attempt += 1
            var req = URLRequest(url: config.baseURL)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.setValue(key, forHTTPHeaderField: "x-api-key")
            req.setValue(config.anthropicVersion, forHTTPHeaderField: "anthropic-version")
            req.httpBody = body

            do {
                let (data, resp) = try await config.session.data(for: req)
                guard let http = resp as? HTTPURLResponse else {
                    throw ClientError.http(status: -1, body: "Non-HTTP response")
                }
                if (200..<300).contains(http.statusCode) {
                    do {
                        return try JSONDecoder().decode(Response.self, from: data)
                    } catch {
                        throw ClientError.decoding(error)
                    }
                }
                if (http.statusCode == 429 || http.statusCode >= 500) && attempt < maxAttempts {
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    delay *= 2
                    continue
                }
                let bodyString = String(data: data, encoding: .utf8) ?? ""
                throw ClientError.http(status: http.statusCode, body: bodyString)
            } catch let e as ClientError {
                throw e
            } catch {
                if attempt < maxAttempts {
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    delay *= 2
                    continue
                }
                throw ClientError.transport(error)
            }
        }
    }
}

/// Tiny JSON value type so tool input schemas and tool_use payloads can
/// flow through `Codable` without a third-party dependency.
public enum JSONValue: Codable, Equatable {
    case null
    case bool(Bool)
    case number(Double)
    case string(String)
    case array([JSONValue])
    case object([String: JSONValue])

    public init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if c.decodeNil() { self = .null; return }
        if let v = try? c.decode(Bool.self)   { self = .bool(v); return }
        if let v = try? c.decode(Double.self) { self = .number(v); return }
        if let v = try? c.decode(String.self) { self = .string(v); return }
        if let v = try? c.decode([JSONValue].self) { self = .array(v); return }
        if let v = try? c.decode([String: JSONValue].self) { self = .object(v); return }
        throw DecodingError.dataCorruptedError(in: c, debugDescription: "Unknown JSON")
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch self {
        case .null: try c.encodeNil()
        case .bool(let v): try c.encode(v)
        case .number(let v): try c.encode(v)
        case .string(let v): try c.encode(v)
        case .array(let v): try c.encode(v)
        case .object(let v): try c.encode(v)
        }
    }

    public var stringValue: String? { if case .string(let s) = self { return s }; return nil }
    public var arrayValue: [JSONValue]? { if case .array(let a) = self { return a }; return nil }
    public subscript(key: String) -> JSONValue? {
        if case .object(let o) = self { return o[key] }; return nil
    }
}
