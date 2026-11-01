# activity-recall

Read-only MCP server for recent macOS activity: Messages, call history, Safari history, and Photos metadata.

Only the `serve` process needs Full Disk Access. Agents run the `mcp` shim, which has no privacy access of its own and forwards tool calls over a user-only Unix socket.

```
activity-recall serve   # run under launchd; grant this binary Full Disk Access
activity-recall mcp     # stdio MCP server for agents
```

Every tool takes `start` and `end` ISO 8601 timestamps at most 8 days apart, plus `limit` and `offset` for paging. Databases are opened read-only. Arbitrary SQL is not exposed.

The binary is ad-hoc signed, so macOS ties its Full Disk Access grant to this exact build. Re-grant after every rebuild or upgrade.
