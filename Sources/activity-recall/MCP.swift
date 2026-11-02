import Foundation

struct MCP {
    func run() {
        while let line = readLine() {
            guard let message = try? JSONSerialization.jsonObject(with: Data(line.utf8)) as? [String: Any],
                  let method = message["method"] as? String, let id = message["id"] else { continue }
            var reply: [String: Any] = ["jsonrpc": "2.0", "id": id]
            if let result = respond(method, message["params"] as? [String: Any] ?? [:]) {
                reply["result"] = result
            } else {
                reply["error"] = ["code": -32601, "message": "method not found: \(method)"]
            }
            guard let data = try? JSONSerialization.data(withJSONObject: reply) else { continue }
            FileHandle.standardOutput.write(data + Data("\n".utf8))
        }
    }

    private func respond(_ method: String, _ params: [String: Any]) -> [String: Any]? {
        switch method {
        case "initialize":
            return [
                "protocolVersion": params["protocolVersion"] as? String ?? "2025-06-18",
                "capabilities": ["tools": [:]],
                "serverInfo": ["name": "activity-recall", "version": "0.1.1"],
            ]
        case "ping":
            return [:]
        case "tools/list":
            return ["tools": Tool.all.map { ["name": $0.name, "description": $0.description, "inputSchema": Query.schema] }]
        case "tools/call":
            return call(params["name"] as? String ?? "", params["arguments"] as? [String: Any] ?? [:])
        default:
            return nil
        }
    }

    private func call(_ name: String, _ arguments: [String: Any]) -> [String: Any] {
        let response = (try? Socket.request(["tool": name, "arguments": arguments]))
            ?? ["error": "activity-recall serve is not running at \(Paths.socket)"]
        let text = response["result"].flatMap { result in
            (try? JSONSerialization.data(withJSONObject: result, options: [.sortedKeys, .withoutEscapingSlashes]))
                .flatMap { String(data: $0, encoding: .utf8) }
        } ?? response["error"] as? String ?? "empty response"
        return ["content": [["type": "text", "text": text]], "isError": response["result"] == nil]
    }
}
