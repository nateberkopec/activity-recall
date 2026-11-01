import Foundation

struct Server {
    func run() throws {
        try FileManager.default.createDirectory(atPath: Paths.socketDirectory, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
        unlink(Paths.socket)
        let listener = socket(AF_UNIX, SOCK_STREAM, 0)
        umask(0o077)
        guard Socket.withAddress({ bind(listener, $0, $1) }) == 0, listen(listener, 16) == 0 else {
            throw Failure(description: "cannot listen on \(Paths.socket): \(String(cString: strerror(errno)))")
        }
        signal(SIGPIPE, SIG_IGN)
        while true {
            let connection = accept(listener, nil, nil)
            guard connection >= 0 else { continue }
            DispatchQueue.global().async { handle(connection) }
        }
    }

    private func handle(_ connection: Int32) {
        defer { close(connection) }
        var response: [String: Any]
        do {
            guard let request = try JSONSerialization.jsonObject(with: Socket.readLine(connection)) as? [String: Any],
                  let tool = request["tool"] as? String else { throw Failure(description: "invalid request") }
            response = ["result": try Tool.call(tool, request["arguments"] as? [String: Any] ?? [:])]
        } catch {
            response = ["error": "\(error)"]
        }
        if let data = try? JSONSerialization.data(withJSONObject: response, options: [.sortedKeys]) {
            Socket.writeLine(connection, data)
        }
    }
}
