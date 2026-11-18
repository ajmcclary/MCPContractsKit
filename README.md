# MCPContractsKit

Typed, app-neutral building blocks for describing the tool catalog an MCP server exposes and the
inputs to a per-call authorization decision.

An application that serves tools over the Model Context Protocol (MCP) ends up maintaining the
same bookkeeping: a closed list of tool wire names, legacy names that must still resolve,
capabilities that map onto sets of tools, named tool groups, and a check before each call. This
package supplies the *mechanisms* for that bookkeeping as small generic value types. Your
application supplies the *data*: its own tool enum, aliases, capability and group tables, and its
own authorization rules.

**This is not an MCP server.** It has no transport, no JSON-RPC, no tool descriptors or JSON
schemas, and no MCP SDK dependency. Pair it with an MCP implementation such as the official
[Swift SDK](https://github.com/modelcontextprotocol/swift-sdk), which handles the protocol itself.

## What's inside

- `MCPToolIdentifying` — the shape of a closed tool inventory: a `String`-raw-valued,
  `CaseIterable` enum whose raw values are the wire names used in discovery, dispatch and
  allowlists.
- `MCPToolAliasResolver` — resolves a name to its canonical tool (canonical name first, then
  alias); `allRecognizedNames` is every canonical name plus every alias.
- `MCPCapabilityIdentifying` — a capability identity with a stable snake_case `externalName` for
  discovery serialization.
- `MCPCapabilityToolMap` — capability-to-tool algebra: union the tools of a set of capabilities,
  or look up the capabilities of a tool by value or by name (aliases included).
- `MCPToolGroupMap` — group membership algebra over any `String`-raw-valued `CaseIterable` group
  enum; results come back in `allCases` order, and ungrouped tools are allowed.
- `MCPToolCallAuthorizationInput` — everything a call-time check needs: tool name, restricted and
  additional tool sets, role flags, connection lineage, and the clock.
- `MCPConnectionOriginLineage` — host-issued provenance of a connection (originating provider,
  parent run, ancestor chain, delegation depth, expiry, workspace root); `.externalUnknown` is the
  unbound default.
- `MCPToolCallAuthorizationDecision` — `.allow`, `.requireApproval(reason:)` or
  `.deny(message:)`.

## When to use it

- You serve MCP tools from a Swift app and want tool names, aliases, capabilities and groups to
  be checked by the compiler rather than kept as loose strings.
- You want a legacy tool name and its canonical name to behave identically in every lookup.
- You want your authorization function to take one well-defined value and return one of three
  outcomes, so it can be unit-tested without a running server.

## When not to

- You need an MCP server, client or transport: use an MCP SDK. This package can sit beside it.
- You are looking for a ready-made tool list: there is none. The package defines no concrete
  tools, aliases, capabilities or groups.
- You want authorization *rules*: none are included. `MCPToolCallAuthorizationInput` and
  `MCPToolCallAuthorizationDecision` are the values your own rules consume and return.
- Out of scope as well: tool descriptors and argument schemas, advertisement or visibility
  policy, plugin manifests, persistence and UI. For provider-neutral agent session vocabulary,
  see [AgentRuntimeKit](https://github.com/ajmcclary/AgentRuntimeKit).

## Installation

```swift
dependencies: [
    // 0.1.0-beta.4 is a prerelease identifier; SwiftPM only resolves prerelease tags when the
    // lower bound itself names one.
    .package(url: "https://github.com/ajmcclary/MCPContractsKit.git", .upToNextMinor(from: "0.1.0-beta.4"))
],
targets: [
    .target(name: "MyServer", dependencies: [
        .product(name: "MCPContractsKit", package: "MCPContractsKit")
    ])
]
```

## Usage

```swift
import MCPContractsKit

// Your app owns the inventory. Raw values are the wire names clients see.
enum Tool: String, CaseIterable, MCPToolIdentifying {
    case readFile = "read_file", applyEdits = "apply_edits"
}
enum Capability: String, MCPCapabilityIdentifying {
    case fileRead = "file_read", fileEdit = "file_edit"
    var externalName: String { rawValue }
}
enum Group: String, CaseIterable, Sendable { case explore, edit }

let aliases: [String: Tool] = ["edit_file": .applyEdits]   // legacy name, never advertised
MCPToolAliasResolver(aliases: aliases).canonicalTool(named: "edit_file")  // .applyEdits

let capabilities = MCPCapabilityToolMap<Capability, Tool>(
    mapping: [.fileRead: [.readFile], .fileEdit: [.applyEdits]], aliases: aliases)
capabilities.toolNames(for: [.fileRead, .fileEdit])   // ["read_file", "apply_edits"]
capabilities.capabilities(for: "edit_file")           // [.fileEdit]

let groups = MCPToolGroupMap<Group, Tool>(
    mapping: [.explore: [.readFile], .edit: [.readFile, .applyEdits]], aliases: aliases)
groups.groups(forToolNamed: "read_file")              // [.explore, .edit]

// The rules are yours; the package defines only what goes in and what comes out.
func authorize(_ input: MCPToolCallAuthorizationInput) -> MCPToolCallAuthorizationDecision {
    if input.restrictedTools.contains(input.toolName) { return .deny(message: "Tool disabled") }
    if input.lineage.delegationDepth > 1 { return .requireApproval(reason: "Re-delegated call") }
    return .allow
}
let decision = authorize(MCPToolCallAuthorizationInput(
    toolName: "apply_edits", restrictedTools: [], additionalTools: [],
    allowsAgentExternalControlTools: false, exploreRoleAllowed: nil,
    lineage: .externalUnknown))                       // .allow
```

## Requirements

- Swift tools version 6.0, Swift 6 language mode with strict concurrency. Every public type is
  `Sendable`.
- macOS 27.0 or iOS 27.0.
- Dependencies: none (Foundation only).

## Stability

Pre-1.0 (`0.x` beta): the public API may change between minor versions, so pin with
`.upToNextMinor`.

## Development

```sh
swift build
swift test
```

The tests run against a small fixture catalog and finish in seconds.

## Origin

Extracted from the RepoPrompt app (Apache-2.0).

## License

Apache License 2.0 — see [LICENSE](LICENSE).
