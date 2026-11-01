import Foundation
import SQLite3

struct Failure: Error, CustomStringConvertible {
    let description: String
}

final class Database {
    private var handle: OpaquePointer?

    init(path: String) throws {
        let status = sqlite3_open_v2(path, &handle, SQLITE_OPEN_READONLY, nil)
        sqlite3_busy_timeout(handle, 5000)
        guard status == SQLITE_OK, (try? scalar("SELECT count(*) FROM sqlite_master")) != nil else {
            let message = handle.map { String(cString: sqlite3_errmsg($0)) } ?? "cannot open"
            sqlite3_close(handle)
            handle = nil
            let executable = Bundle.main.executablePath ?? CommandLine.arguments[0]
            throw Failure(description: "\(path): \(message). Grant Full Disk Access to \(executable).")
        }
    }

    deinit { sqlite3_close(handle) }

    func scalar(_ sql: String) throws -> Any {
        try rows(sql, []).first?.values.first ?? NSNull()
    }

    func rows(_ sql: String, _ bindings: [Any]) throws -> [[String: Any]] {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(handle, sql, -1, &statement, nil) == SQLITE_OK else { throw error() }
        defer { sqlite3_finalize(statement) }
        for (index, value) in bindings.enumerated() {
            let position = Int32(index + 1)
            switch value {
            case let number as Int64: sqlite3_bind_int64(statement, position, number)
            case let number as Int: sqlite3_bind_int64(statement, position, Int64(number))
            case let number as Double: sqlite3_bind_double(statement, position, number)
            default: throw Failure(description: "unsupported binding \(value)")
            }
        }
        var result: [[String: Any]] = []
        while true {
            let status = sqlite3_step(statement)
            if status == SQLITE_DONE { return result }
            guard status == SQLITE_ROW else { throw error() }
            var row: [String: Any] = [:]
            for column in 0..<sqlite3_column_count(statement) {
                row[String(cString: sqlite3_column_name(statement, column))] = value(statement, column)
            }
            result.append(row)
        }
    }

    private func value(_ statement: OpaquePointer?, _ column: Int32) -> Any {
        switch sqlite3_column_type(statement, column) {
        case SQLITE_INTEGER: return sqlite3_column_int64(statement, column)
        case SQLITE_FLOAT: return sqlite3_column_double(statement, column)
        case SQLITE_TEXT: return String(cString: sqlite3_column_text(statement, column))
        case SQLITE_BLOB:
            let count = Int(sqlite3_column_bytes(statement, column))
            guard let bytes = sqlite3_column_blob(statement, column) else { return Data() }
            return Data(bytes: bytes, count: count)
        default: return NSNull()
        }
    }

    private func error() -> Failure {
        Failure(description: String(cString: sqlite3_errmsg(handle)))
    }
}
