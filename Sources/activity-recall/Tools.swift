import Foundation

struct Tool {
    let name: String
    let description: String
    let run: (Query) throws -> [String: Any]

    static let all = [
        Tool(name: "messages", description: "Messages and SMS in a time window, newest first, excluding tapbacks. Read-only.", run: Messages.run),
        Tool(name: "calls", description: "Phone and FaceTime call records in a time window, newest first. Read-only.", run: Calls.run),
        Tool(name: "safari_history", description: "Safari pages visited in a time window, one row per URL, newest first. Read-only.", run: Safari.run),
        Tool(name: "photos", description: "Metadata for Photos library items added in a time window, newest first, excluding hidden and trashed items. Image contents are not available. Read-only.", run: Photos.run),
    ]

    static func call(_ name: String, _ arguments: [String: Any]) throws -> [String: Any] {
        guard let tool = all.first(where: { $0.name == name }) else { throw Failure(description: "unknown tool \(name)") }
        return try tool.run(Query(arguments))
    }
}
