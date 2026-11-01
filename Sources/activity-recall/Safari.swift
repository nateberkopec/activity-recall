import Foundation

enum Safari {
    static let sql = """
    SELECT i.url, max(v.visit_time) AS last_visit, count(*) AS visits,
      (SELECT t.title FROM history_visits t
        WHERE t.history_item = i.id AND t.visit_time >= ?1 AND t.visit_time < ?2 AND coalesce(t.title, '') != ''
        ORDER BY t.visit_time DESC LIMIT 1) AS title
    FROM history_visits v
    JOIN history_items i ON i.id = v.history_item
    WHERE v.visit_time >= ?1 AND v.visit_time < ?2 AND v.redirect_destination IS NULL
    GROUP BY i.id
    ORDER BY last_visit DESC, i.id DESC
    LIMIT ?3 OFFSET ?4
    """

    static func run(_ query: Query) throws -> [String: Any] {
        let database = try Database(path: Paths.safari)
        let bindings: [Any] = [query.appleStart, query.appleEnd] + query.pageBindings
        return query.page(try database.rows(sql, bindings)) { row in
            [
                "last_visit": Query.apple(row["last_visit"]),
                "visits": row["visits"] ?? 0,
                "title": row["title"] ?? NSNull(),
                "url": row["url"] ?? NSNull(),
            ]
        }
    }
}
