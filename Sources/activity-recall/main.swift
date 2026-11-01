import Foundation

switch CommandLine.arguments.dropFirst().first {
case "serve":
    try Server().run()
case "mcp":
    MCP().run()
default:
    FileHandle.standardError.write(Data("usage: activity-recall serve|mcp\n".utf8))
    exit(64)
}
