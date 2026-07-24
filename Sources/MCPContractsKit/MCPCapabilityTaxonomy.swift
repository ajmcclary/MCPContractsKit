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
/// - reverse lookup by NAME resolves canonical raw values only — aliases and
///   unknown names have no capabilities (empty set, never nil/throw).
public struct MCPCapabilityToolMap<Capability: MCPCapabilityIdentifying, Tool: MCPToolIdentifying>: Sendable {
	/// Capability membership keyed by capability. Not every tool must be
	/// covered; uncovered tools simply have no capabilities.
	public let mapping: [Capability: Set<Tool>]

	public init(mapping: [Capability: Set<Tool>]) {
		self.mapping = mapping
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

	/// Canonical wire names only — aliases deliberately do NOT resolve here
	/// (unknown names have no capabilities).
	public func capabilities(for toolName: String) -> Set<Capability> {
		guard let tool = Tool(rawValue: toolName) else { return [] }
		return capabilities(for: tool)
	}
}
