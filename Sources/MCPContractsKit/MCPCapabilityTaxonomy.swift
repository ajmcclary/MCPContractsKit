import Foundation

/// The capability vocabulary contract: a hashable capability identity that
/// serializes to a stable snake_case external name for MCP discovery.
///
/// Applications own their capability case inventory (RepoPrompt's
/// `MCPToolCapability` is the founding conformer); policies should express
/// intent in capabilities and derive tool names through `MCPCapabilityToolMap`.
public protocol MCPCapabilityIdentifying: Hashable, Sendable {
	/// Stable snake_case name for MCP discovery serialization.
	var externalName: String { get }
}

/// Deterministic capability↔tool map algebra over app-supplied vocabulary.
///
/// Mirrors the live semantics RepoPrompt's taxonomy pinned before extraction:
/// - forward derivation unions the tool sets of the requested capabilities;
/// - the typed and string-name APIs agree (same map, `rawValue` projection);
/// - reverse lookup by NAME resolves exactly as
///   `MCPToolAliasResolver.canonicalTool(named:)` does over the aliases
///   supplied at init (canonical name first, then alias); unknown names have
///   no capabilities (empty set, never nil/throw). A map built with
///   `init(mapping:)` has no aliases, so it resolves canonical names only.
public struct MCPCapabilityToolMap<Capability: MCPCapabilityIdentifying, Tool: MCPToolIdentifying>: Sendable {
	/// Capability membership keyed by capability. Not every tool must be
	/// covered; uncovered tools simply have no capabilities.
	public let mapping: [Capability: Set<Tool>]

	private let aliasResolver: MCPToolAliasResolver<Tool>

	public init(mapping: [Capability: Set<Tool>]) {
		self.init(mapping: mapping, aliases: [:])
	}

	/// - Parameter aliases: legacy/compat names keyed by alias wire name, as
	///   given to `MCPToolAliasResolver`; name lookups resolve them to their
	///   canonical tool.
	public init(mapping: [Capability: Set<Tool>], aliases: [String: Tool]) {
		self.mapping = mapping
		self.aliasResolver = MCPToolAliasResolver(aliases: aliases)
	}

	public func tools(for capabilities: Set<Capability>) -> Set<Tool> {
		capabilities.reduce(into: Set<Tool>()) { partialResult, capability in
			partialResult.formUnion(mapping[capability] ?? [])
		}
	}

	public func toolNames(for capabilities: Set<Capability>) -> Set<String> {
		Set(tools(for: capabilities).map(\.rawValue))
	}

	public func capabilities(for tool: Tool) -> Set<Capability> {
		Set(mapping.compactMap { capability, tools in
			tools.contains(tool) ? capability : nil
		})
	}

	/// Resolves `toolName` like `MCPToolAliasResolver.canonicalTool(named:)`
	/// over the supplied aliases, so an alias and its canonical name agree;
	/// unknown names have no capabilities.
	public func capabilities(for toolName: String) -> Set<Capability> {
		guard let tool = aliasResolver.canonicalTool(named: toolName) else { return [] }
		return capabilities(for: tool)
	}
}
