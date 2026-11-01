import Foundation

enum Messages {
    static let sql = """
    SELECT m.date, m.is_from_me, m.text, m.attributedBody, m.subject, m.service,
      h.id AS sender, coalesce(nullif(c.display_name, ''), c.chat_identifier) AS chat,
      (SELECT group_concat(coalesce(a.transfer_name, a.filename) || ' (' || coalesce(a.mime_type, a.uti, 'unknown') || ')', '; ')
         FROM message_attachment_join j JOIN attachment a ON a.ROWID = j.attachment_id
        WHERE j.message_id = m.ROWID) AS attachments
    FROM message m
    JOIN chat_message_join cm ON cm.message_id = m.ROWID
    JOIN chat c ON c.ROWID = cm.chat_id
    LEFT JOIN handle h ON h.ROWID = m.handle_id
    WHERE m.date >= ? AND m.date < ? AND m.associated_message_type = 0 AND m.item_type = 0
    ORDER BY m.date DESC, m.ROWID DESC
    LIMIT ? OFFSET ?
    """

    static func run(_ query: Query) throws -> [String: Any] {
        let database = try Database(path: Paths.messages)
        let newest = try database.scalar("SELECT max(date) FROM message") as? Int64 ?? 0
        let scale = newest > 1_000_000_000_000 ? 1_000_000_000.0 : 1.0
        let bindings: [Any] = [Int64(query.appleStart * scale), Int64(query.appleEnd * scale)] + query.pageBindings
        return query.page(try database.rows(sql, bindings)) { row in
            let fromMe = row["is_from_me"] as? Int64 == 1
            return [
                "date": Query.apple((row["date"] as? Int64).map { Double($0) / scale }),
                "chat": row["chat"] ?? NSNull(),
                "direction": fromMe ? "sent" : "received",
                "sender": fromMe ? "me" : row["sender"] ?? NSNull(),
                "service": row["service"] ?? NSNull(),
                "subject": row["subject"] ?? NSNull(),
                "text": text(row) ?? NSNull(),
                "attachments": row["attachments"] ?? NSNull(),
            ]
        }
    }

    private static func text(_ row: [String: Any]) -> String? {
        if let text = row["text"] as? String, !text.isEmpty { return clean(text) }
        guard let data = row["attributedBody"] as? Data,
              let body = NSUnarchiver.unarchiveObject(with: data) as? NSAttributedString else { return nil }
        return clean(body.string)
    }

    private static func clean(_ text: String) -> String? {
        let cleaned = text.replacingOccurrences(of: "\u{FFFC}", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? nil : cleaned
    }
}
