import Foundation

struct Query {
    static let maximumSpan: TimeInterval = 8 * 86_400
    static let schema: [String: Any] = [
        "type": "object",
        "properties": [
            "start": ["type": "string", "description": "Inclusive ISO 8601 timestamp with offset, e.g. 2026-10-26T00:00:00-07:00"],
            "end": ["type": "string", "description": "Exclusive ISO 8601 timestamp with offset; at most 8 days after start"],
            "limit": ["type": "integer", "description": "Page size, default 200, maximum 500"],
            "offset": ["type": "integer", "description": "Rows to skip; pass next_offset from the previous page"],
        ],
        "required": ["start", "end"],
    ]

    let start: Date
    let end: Date
    let limit: Int
    let offset: Int

    init(_ arguments: [String: Any]) throws {
        let parser = ISO8601DateFormatter()
        guard let start = (arguments["start"] as? String).flatMap(parser.date(from:)),
              let end = (arguments["end"] as? String).flatMap(parser.date(from:)) else {
            throw Failure(description: "start and end must be ISO 8601 timestamps with offsets")
        }
        guard start < end, end.timeIntervalSince(start) <= Query.maximumSpan else {
            throw Failure(description: "end must be after start and at most 8 days later")
        }
        self.start = start
        self.end = end
        limit = min(max((arguments["limit"] as? Int) ?? 200, 1), 500)
        offset = max((arguments["offset"] as? Int) ?? 0, 0)
    }

    var appleStart: Double { start.timeIntervalSinceReferenceDate }
    var appleEnd: Double { end.timeIntervalSinceReferenceDate }

    func page(_ rows: [[String: Any]], _ transform: ([String: Any]) -> [String: Any]) -> [String: Any] {
        let more = rows.count > limit
        return [
            "start": Query.format(start),
            "end": Query.format(end),
            "items": rows.prefix(limit).map(transform),
            "next_offset": more ? offset + limit : NSNull(),
        ]
    }

    var pageBindings: [Any] { [limit + 1, offset] }

    static func format(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = .current
        return formatter.string(from: date)
    }

    static func apple(_ value: Any?) -> Any {
        guard let seconds = (value as? Double) ?? (value as? Int64).map(Double.init) else { return NSNull() }
        return format(Date(timeIntervalSinceReferenceDate: seconds))
    }
}
