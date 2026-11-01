import Foundation

enum Calls {
    static let sql = """
    SELECT ZDATE, ZADDRESS, ZNAME, ZDURATION, ZORIGINATED, ZANSWERED, ZCALLTYPE, ZSERVICE_PROVIDER
    FROM ZCALLRECORD
    WHERE ZDATE >= ? AND ZDATE < ?
    ORDER BY ZDATE DESC, Z_PK DESC
    LIMIT ? OFFSET ?
    """

    static func run(_ query: Query) throws -> [String: Any] {
        let database = try Database(path: Paths.calls)
        let bindings: [Any] = [query.appleStart, query.appleEnd] + query.pageBindings
        return query.page(try database.rows(sql, bindings)) { row in
            [
                "date": Query.apple(row["ZDATE"]),
                "address": row["ZADDRESS"] ?? NSNull(),
                "name": row["ZNAME"] ?? NSNull(),
                "duration_seconds": row["ZDURATION"] ?? NSNull(),
                "direction": direction(row),
                "type": type(row["ZCALLTYPE"] as? Int64),
                "provider": row["ZSERVICE_PROVIDER"] ?? NSNull(),
            ]
        }
    }

    private static func direction(_ row: [String: Any]) -> String {
        if row["ZORIGINATED"] as? Int64 == 1 { return "outgoing" }
        return row["ZANSWERED"] as? Int64 == 1 ? "incoming" : "missed"
    }

    private static func type(_ value: Int64?) -> String {
        switch value {
        case 1: return "phone"
        case 8: return "facetime-video"
        case 16: return "facetime-audio"
        default: return value.map { "unknown-\($0)" } ?? "unknown"
        }
    }
}
