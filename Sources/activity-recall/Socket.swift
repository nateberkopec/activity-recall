import Foundation

enum Socket {
    static func address() -> sockaddr_un {
        var address = sockaddr_un()
        address.sun_family = sa_family_t(AF_UNIX)
        withUnsafeMutableBytes(of: &address.sun_path) { buffer in
            buffer.copyBytes(from: Paths.socket.utf8.prefix(buffer.count - 1))
        }
        return address
    }

    static func withAddress<T>(_ body: (UnsafePointer<sockaddr>, socklen_t) -> T) -> T {
        var address = address()
        return withUnsafePointer(to: &address) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { body($0, socklen_t(MemoryLayout<sockaddr_un>.size)) }
        }
    }

    static func readLine(_ descriptor: Int32) -> Data {
        var data = Data()
        var byte: UInt8 = 0
        while read(descriptor, &byte, 1) == 1, byte != UInt8(ascii: "\n") { data.append(byte) }
        return data
    }

    static func writeLine(_ descriptor: Int32, _ data: Data) {
        let line = data + Data("\n".utf8)
        line.withUnsafeBytes { buffer in
            var sent = 0
            while sent < buffer.count {
                let count = write(descriptor, buffer.baseAddress! + sent, buffer.count - sent)
                if count <= 0 { return }
                sent += count
            }
        }
    }

    static func request(_ payload: [String: Any]) throws -> [String: Any] {
        let descriptor = socket(AF_UNIX, SOCK_STREAM, 0)
        defer { close(descriptor) }
        guard withAddress({ connect(descriptor, $0, $1) }) == 0 else {
            throw Failure(description: "activity-recall serve is not running at \(Paths.socket)")
        }
        writeLine(descriptor, try JSONSerialization.data(withJSONObject: payload))
        guard let response = try JSONSerialization.jsonObject(with: readLine(descriptor)) as? [String: Any] else {
            throw Failure(description: "invalid response from activity-recall serve")
        }
        return response
    }
}
