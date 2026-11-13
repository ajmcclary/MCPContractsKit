import Foundation

/// Tool-group membership algebra over app-supplied group vocabulary (raw
/// values are the user-facing group names a CLI parses; `allCases` declaration
/// order is the canonical presentation order).
///
/// Mirrors the live semantics RepoPrompt's CLI group catalog pinned before
/// extraction:
/// - forward derivation unions the tool sets of the requested groups;
/// - `groups(forToolNamed:)` returns groups in `allCases` order and resolves
///   names exactly as `MCPToolAliasResolver.canonicalTool(named:)` does over
///   the aliases supplied at init (unknown names belong to no group; a map
///   built with `init(mapping:)` has no aliases, so canonical names only);
/// - not every tool must be grouped — ungrouped tools are a deliberate,
///   pinnable state.
public struct MCPToolGroupMap<Group, Tool: MCPToolIdentifying>: Sendable
where Group: RawRepresentable, Group: CaseIterable, Group: Hashable, Group: Sendable, Group.RawValue == String {
	/// Group membership keyed by group.
	public let mapping: [Group: Set<Tool>]

	private let aliasResolver: MCPToolAliasResolver<Tool>

	public init(mapping: [Group: Set<Tool>]) {
		self.init(mapping: mapping, aliases: [:])
	}

	/// - Parameter aliases: legacy/compat names keyed by alias wire name, as
	///   given to `MCPToolAliasResolver`; name lookups resolve them to their
	///   canonical tool.
	public init(mapping: [Group: Set<Tool>], aliases: [String: Tool]) {
		self.mapping = mapping
		self.aliasResolver = MCPToolAliasResolver(aliases: aliases)
	}

	public func tools(for groups: [Group]) -> Set<Tool> {
		groups.reduce(into: Set<Tool>()) { partialResult, group in
			partialResult.formUnion(mapping[group] ?? [])
		}
	}

	public func toolNames(for groups: [Group]) -> Set<String> {
		Set(tools(for: groups).map(\.rawValue))
	}

	/// Resolves `name` like `MCPToolAliasResolver.canonicalTool(named:)` over
	/// the supplied aliases, so an alias and its canonical name agree. Result
	/// order is `Group.allCases` declaration order.
	public func groups(forToolNamed name: String) -> [Group] {
		guard let tool = aliasResolver.canonicalTool(named: name) else { return [] }
		return Group.allCases.filter { mapping[$0]?.contains(tool) ?? false }
	}

	public func isInGroups(_ toolName: String, groups: [Group]) -> Bool {
		!Set(self.groups(forToolNamed: toolName)).isDisjoint(with: groups)
	}
}
