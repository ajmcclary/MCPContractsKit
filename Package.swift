// swift-tools-version: 6.0
import PackageDescription

// MCPContractsKit — app-neutral MCP contract vocabulary.
//
// Promoted out of RepoPrompt as the fourth extraction of the migrate.md
// package map. Unlike the first three extractions this is a boundary
// redraw, not a whole-target move: RepoPromptCore's MCPToolCatalog target
// keeps RepoPrompt's concrete tool inventory and policy data, and its
// MCPContracts target is now an @_exported re-export shim over this
// package (alongside its existing MCPToolCatalog re-export).
//
// Scope: the closed tool-inventory shape (MCPToolIdentifying) and
// alias-aware name resolution (MCPToolAliasResolver); the capability
// vocabulary contract (MCPCapabilityIdentifying with its stable
// snake_case externalName discovery-serialization convention) and the
// deterministic capability<->tool map algebra (MCPCapabilityToolMap);
// the tool-group membership algebra (MCPToolGroupMap); and the pure
// call-time authorization-input vocabulary (MCPConnectionOriginLineage,
// MCPToolCallAuthorizationInput, MCPToolCallAuthorizationDecision) an
// application's own authorizer evaluates.
//
// Deliberately OUT of scope (stays in RepoPrompt): the MCPToolID
// wire-name inventory, legacy aliases, tool groups, capability-to-tool
// membership, the policy-gated tool list, the MCPToolCallAuthorizer rule
// set and its deny messages, advertisement/visibility policy, run-purpose
// taxonomy, MCP SDK/server construction and transport, tool descriptors
// and JSON schemas (they carry MCP-SDK/JSONSchema types; this package
// must stay MCP-SDK-free), plugin manifests, persistence, and UI.
//
// Zero package dependencies (Foundation only). Swift 5 language mode
// keeps the moved code byte-behaviorally identical (AgentRuntimeKit /
// PromptAssemblyKit / RepoPromptCore promoted-target precedent).
let package = Package(
    name: "MCPContractsKit",
    platforms: [
        .macOS(.v14),
        .iOS(.v17)
    ],
    products: [
        .library(name: "MCPContractsKit", targets: ["MCPContractsKit"])
    ],
    targets: [
        .target(
            name: "MCPContractsKit",
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .testTarget(
            name: "MCPContractsKitTests",
            dependencies: ["MCPContractsKit"],
            swiftSettings: [.swiftLanguageMode(.v5)]
        )
    ]
)
