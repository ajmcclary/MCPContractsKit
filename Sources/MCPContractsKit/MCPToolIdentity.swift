import Foundation

/// The closed tool-inventory shape: a string-raw-valued, case-iterable identity
/// type whose raw values are the stable wire names used in MCP discovery,
/// dispatch, policy, and integration allowlists.
///
/// An application declares one enum per served catalog (RepoPrompt's
/// `MCPToolID` is the founding conformer) and keeps full ownership of the case
/// inventory; this package owns only the shape and the deterministic
/// resolution/derivation mechanisms that operate on it.
public protocol MCPToolIdentifying: RawRepresentable, CaseIterable, Hashable, Sendable
where RawValue == String {}

/// Alias-aware canonical-name resolution over a closed tool inventory.
///
/// Mirrors the live semantics RepoPrompt's catalog pinned before extraction:
/// - `allRecognizedNames` is the canonical wire names plus every alias key
///   (the historical permission-allowlist set);
/// - `canonicalTool(named:)` resolves a canonical name first, then an alias,
///   and returns nil for unknown names.
public struct MCPToolAliasResolver<Tool: MCPToolIdentifying>: Sendable {
	/// Legacy/compat names recognized in permission matching but never served
	/// in MCP discovery, keyed by the alias wire name.
	public let aliases: [String: Tool]

	public init(aliases: [String: Tool]) {
		self.aliases = aliases
	}

	/// Every name recognized as one of the catalog's tools: canonical wire
	/// names plus alias keys.
	public var allRecognizedNames: Set<String> {
		Set(Tool.allCases.map(\.rawValue)).union(aliases.keys)
	}

	/// Resolve a name (canonical or alias) to its canonical tool.
	public func canonicalTool(named name: String) -> Tool? {
		Tool(rawValue: name) ?? aliases[name]
	}
}
