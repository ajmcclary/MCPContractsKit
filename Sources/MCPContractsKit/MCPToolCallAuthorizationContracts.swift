import Foundation

/// Host-issued origin lineage for one MCP connection.
///
/// Issued by the host application from verified state (run-scoped policy
/// install + PID-descendant admission) — never from client-supplied metadata.
/// Client/model/plugin names can only RESTRICT authority (an agent-origin
/// connection gets more denials); they never grant.
public struct MCPConnectionOriginLineage: Equatable, Sendable {
	/// Verified originating agent provider hint (opaque provider family
	/// strings, e.g. "opencode", "codex", "claude"), or nil for a connection
	/// not admitted through an agent run policy.
	public let originProvider: String?
	/// The host run this connection is bound to, when verified.
	public let parentRunID: UUID?
	/// Ancestor provider chain for delegated work (closest first).
	public let ancestorProviders: [String]
	/// Delegation depth: 0 = external/unbound, 1 = direct agent-launched
	/// connection, >1 = re-delegated.
	public let delegationDepth: Int
	/// Optional expiry for the issued capability (epoch seconds).
	public let expiresAtEpochSeconds: Int?
	/// Canonical workspace root bound to the run, when known.
	public let workspaceRootPath: String?

	public init(
		originProvider: String?,
		parentRunID: UUID?,
		ancestorProviders: [String],
		delegationDepth: Int,
		expiresAtEpochSeconds: Int?,
		workspaceRootPath: String?
	) {
		self.originProvider = originProvider
		self.parentRunID = parentRunID
		self.ancestorProviders = ancestorProviders
		self.delegationDepth = delegationDepth
		self.expiresAtEpochSeconds = expiresAtEpochSeconds
		self.workspaceRootPath = workspaceRootPath
	}

	public static let externalUnknown = MCPConnectionOriginLineage(
		originProvider: nil,
		parentRunID: nil,
		ancestorProviders: [],
		delegationDepth: 0,
		expiresAtEpochSeconds: nil,
		workspaceRootPath: nil
	)
}

/// The call-time authorization outcome vocabulary an application's authorizer
/// returns. The rules that produce it — and their user-facing messages — stay
/// application-owned.
public enum MCPToolCallAuthorizationDecision: Equatable, Sendable {
	case allow
	case requireApproval(reason: String)
	case deny(message: String)
}

/// Complete input for one call-time decision, assembled by the host
/// immediately before service invocation.
public struct MCPToolCallAuthorizationInput: Sendable {
	public let toolName: String
	public let restrictedTools: Set<String>
	public let additionalTools: Set<String>
	public let allowsAgentExternalControlTools: Bool
	/// Result of the host's role-advertisement policy for this connection,
	/// when the tool is role-gated; nil when not applicable.
	public let exploreRoleAllowed: Bool?
	public let lineage: MCPConnectionOriginLineage
	/// Raw target hint extracted from the call's arguments for agent-control
	/// tools (`model_id`/`agent`), used for same-provider recursion detection
	/// when the target provider is determinable from the request itself.
	public let requestedAgentTargetHint: String?
	public let nowEpochSeconds: Int

	public init(
		toolName: String,
		restrictedTools: Set<String>,
		additionalTools: Set<String>,
		allowsAgentExternalControlTools: Bool,
		exploreRoleAllowed: Bool?,
		lineage: MCPConnectionOriginLineage,
		requestedAgentTargetHint: String? = nil,
		nowEpochSeconds: Int = Int(Date().timeIntervalSince1970)
	) {
		self.toolName = toolName
		self.restrictedTools = restrictedTools
		self.additionalTools = additionalTools
		self.allowsAgentExternalControlTools = allowsAgentExternalControlTools
		self.exploreRoleAllowed = exploreRoleAllowed
		self.lineage = lineage
		self.requestedAgentTargetHint = requestedAgentTargetHint
		self.nowEpochSeconds = nowEpochSeconds
	}
}
