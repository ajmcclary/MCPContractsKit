import MCPContractsKit

/// A miniature app-side catalog vocabulary. The kit owns no concrete tool,
/// capability, or group inventory — these fixtures play the role RepoPrompt's
/// MCPToolID / MCPToolCapability / MCPToolGroup play in production, so the
/// suites below characterize the MECHANISMS against a neutral inventory.
enum FixtureTool: String, CaseIterable, MCPToolIdentifying {
	case readFile = "read_file"
	case applyEdits = "apply_edits"
	case askUser = "ask_user"
	case runAgent = "run_agent"
	/// Deliberately uncovered by the fixture capability and group maps.
	case orphan = "orphan_tool"
}

enum FixtureCapability: CaseIterable, MCPCapabilityIdentifying {
	case fileRead
	case fileEdit
	case userInteraction
	case agentControl

	var externalName: String {
		switch self {
		case .fileRead: return "file_read"
		case .fileEdit: return "file_edit"
		case .userInteraction: return "user_interaction"
		case .agentControl: return "agent_control"
		}
	}
}

enum FixtureGroup: String, CaseIterable, Sendable {
	case explore
	case edit
	case conversation
}
