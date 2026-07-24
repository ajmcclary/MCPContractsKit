import XCTest
@testable import MCPContractsKit

/// Characterization of the moved call-time authorization vocabulary. The
/// values moved verbatim from the host application (labels and defaults
/// preserved); the authorizer RULES stay app-side.
final class MCPToolCallAuthorizationValueTests: XCTestCase {
	func testExternalUnknownSentinelIsUnboundDepthZero() {
		let sentinel = MCPConnectionOriginLineage.externalUnknown
		XCTAssertNil(sentinel.originProvider)
		XCTAssertNil(sentinel.parentRunID)
		XCTAssertEqual(sentinel.ancestorProviders, [])
		XCTAssertEqual(sentinel.delegationDepth, 0)
		XCTAssertNil(sentinel.expiresAtEpochSeconds)
		XCTAssertNil(sentinel.workspaceRootPath)
	}

	func testLineageEqualityIsFieldSensitive() {
		let runID = UUID()
		let lineage = MCPConnectionOriginLineage(
			originProvider: "opencode",
			parentRunID: runID,
			ancestorProviders: ["codex"],
			delegationDepth: 2,
			expiresAtEpochSeconds: 1_000,
			workspaceRootPath: "/workspace/project"
		)
		let same = MCPConnectionOriginLineage(
			originProvider: "opencode",
			parentRunID: runID,
			ancestorProviders: ["codex"],
			delegationDepth: 2,
			expiresAtEpochSeconds: 1_000,
			workspaceRootPath: "/workspace/project"
		)
		XCTAssertEqual(lineage, same)
		XCTAssertNotEqual(lineage, MCPConnectionOriginLineage.externalUnknown)
	}

	func testDecisionEqualityIsPayloadSensitive() {
		XCTAssertEqual(MCPToolCallAuthorizationDecision.allow, .allow)
		XCTAssertEqual(
			MCPToolCallAuthorizationDecision.deny(message: "no"),
			.deny(message: "no")
		)
		XCTAssertNotEqual(
			MCPToolCallAuthorizationDecision.deny(message: "no"),
			.deny(message: "different")
		)
		XCTAssertNotEqual(
			MCPToolCallAuthorizationDecision.requireApproval(reason: "why"),
			.allow
		)
	}

	func testInputPreservesEveryField() {
		let lineage = MCPConnectionOriginLineage.externalUnknown
		let input = MCPToolCallAuthorizationInput(
			toolName: "apply_edits",
			restrictedTools: ["apply_edits"],
			additionalTools: ["ask_user"],
			allowsAgentExternalControlTools: true,
			exploreRoleAllowed: false,
			lineage: lineage,
			requestedAgentTargetHint: "codex",
			nowEpochSeconds: 42
		)
		XCTAssertEqual(input.toolName, "apply_edits")
		XCTAssertEqual(input.restrictedTools, ["apply_edits"])
		XCTAssertEqual(input.additionalTools, ["ask_user"])
		XCTAssertTrue(input.allowsAgentExternalControlTools)
		XCTAssertEqual(input.exploreRoleAllowed, false)
		XCTAssertEqual(input.lineage, lineage)
		XCTAssertEqual(input.requestedAgentTargetHint, "codex")
		XCTAssertEqual(input.nowEpochSeconds, 42)
	}

	func testInputDefaultsMatchTheMovedDeclaration() {
		let before = Int(Date().timeIntervalSince1970)
		let input = MCPToolCallAuthorizationInput(
			toolName: "get_file_tree",
			restrictedTools: [],
			additionalTools: [],
			allowsAgentExternalControlTools: false,
			exploreRoleAllowed: nil,
			lineage: .externalUnknown
		)
		let after = Int(Date().timeIntervalSince1970)
		XCTAssertNil(input.requestedAgentTargetHint)
		XCTAssertGreaterThanOrEqual(input.nowEpochSeconds, before)
		XCTAssertLessThanOrEqual(input.nowEpochSeconds, after)
	}
}
