import Foundation

/// Tool-group membership algebra over app-supplied group vocabulary (raw
/// values are the user-facing group names a CLI parses; `allCases` declaration
/// order is the canonical presentation order).
///
/// Mirrors the live semantics RepoPrompt's CLI group catalog pinned before
/// extraction:
/// - forward derivation unions the tool sets of the requested groups;
/// - `groups(forToolNamed:)` returns groups in `allCases` order and resolves
///   canonical wire names only (aliases and unknown names belong to no group);
/// - not every tool must be grouped — ungrouped tools are a deliberate,
///   pinnable state.
public struct MCPToolGroupMap<Group, Tool: MCPToolIdentifying>: Sendable
where Group: RawRepresentable, Group: CaseIterable, Group: Hashable, Group: Sendable, Group.RawValue == String {
	/// Group membership keyed by group.
	public let mapping: [Group: Set<Tool>]

	public init(mapping: [Group: Set<Tool>]) {
		self.mapping = mapping
	}

	public func tools(for groups: [Group]) -> Set<Tool> {
		groups.reduce(into: Set<Tool>()) { partialResult, group in
			partialResult.formUnion(mapping[group] ?? [])
		}
	}

	public func toolNames(for groups: [Group]) -> Set<String> {
		Set(tools(for: groups).map(\.rawValue))
	}

	/// Canonical wire names only — aliases do not resolve. Result order is
	/// `Group.allCases` declaration order.
	public func groups(forToolNamed name: String) -> [Group] {
		guard let tool = Tool(rawValue: name) else { return [] }
		return Group.allCases.filter { mapping[$0]?.contains(tool) ?? false }
	}

	public func isInGroups(_ toolName: String, groups: [Group]) -> Bool {
		!Set(self.groups(forToolNamed: toolName)).isDisjoint(with: groups)
	}
}
