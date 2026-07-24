import XCTest
@testable import MCPContractsKit

/// Characterization of the tool-group membership algebra, mirroring the
/// semantics RepoPrompt's `MCPToolGroupCatalog` pinned before extraction.
final class MCPToolGroupMapTests: XCTestCase {
	/// `readFile` is deliberately in two NON-ADJACENT groups (`explore` and
	/// `conversation`) so the allCases-ordered result is provably order-pinned;
	/// `orphan` is deliberately ungrouped.
	private let map = MCPToolGroupMap<FixtureGroup, FixtureTool>(mapping: [
		.explore: [.readFile],
		.edit: [.applyEdits],
		.conversation: [.askUser, .runAgent, .readFile]
	])

	func testToolsForGroupsUnionsMemberSets() {
		XCTAssertEqual(map.tools(for: [.explore]), [.readFile])
		XCTAssertEqual(map.tools(for: [.explore, .edit]), [.readFile, .applyEdits])
		XCTAssertEqual(map.tools(for: []), [])
	}

	func testToolNamesForGroupsProjectsRawValues() {
		XCTAssertEqual(map.toolNames(for: [.edit]), ["apply_edits"])
		XCTAssertEqual(
			map.toolNames(for: FixtureGroup.allCases),
			["read_file", "apply_edits", "ask_user", "run_agent"]
		)
	}

	func testGroupsForToolAreOrderedByAllCasesDeclarationOrder() {
		XCTAssertEqual(map.groups(forToolNamed: "read_file"), [.explore, .conversation])
		XCTAssertEqual(map.groups(forToolNamed: "apply_edits"), [.edit])
	}

	func testUngroupedToolBelongsToNoGroup() {
		XCTAssertEqual(map.groups(forToolNamed: "orphan_tool"), [])
	}

	func testStringLookupResolvesCanonicalWireNamesOnly() {
		XCTAssertEqual(map.groups(forToolNamed: "ask_user_question"), [])
		XCTAssertEqual(map.groups(forToolNamed: "does_not_exist"), [])
	}

	func testIsInGroups() {
		XCTAssertTrue(map.isInGroups("apply_edits", groups: [.edit]))
		XCTAssertTrue(map.isInGroups("read_file", groups: [.conversation]))
		XCTAssertFalse(map.isInGroups("apply_edits", groups: [.explore, .conversation]))
		XCTAssertFalse(map.isInGroups("does_not_exist", groups: FixtureGroup.allCases))
		XCTAssertFalse(map.isInGroups("orphan_tool", groups: FixtureGroup.allCases))
	}
}
