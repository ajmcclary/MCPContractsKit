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

	func testSuppliedAliasResolvesToTheSameGroupsAsItsCanonicalName() {
		let aliased = MCPToolGroupMap<FixtureGroup, FixtureTool>(
			mapping: map.mapping,
			aliases: ["ask_user_question": .askUser]
		)
		XCTAssertEqual(aliased.groups(forToolNamed: "ask_user_question"), [.conversation])
		XCTAssertEqual(aliased.groups(forToolNamed: "ask_user_question"), aliased.groups(forToolNamed: "ask_user"))
		XCTAssertEqual(aliased.groups(forToolNamed: "does_not_exist"), [])
	}

	func testIsInGroupsAgreesForSuppliedAliasAndCanonicalName() {
		let aliased = MCPToolGroupMap<FixtureGroup, FixtureTool>(
			mapping: map.mapping,
			aliases: ["ask_user_question": .askUser]
		)
		XCTAssertTrue(aliased.isInGroups("ask_user_question", groups: [.conversation]))
		XCTAssertFalse(aliased.isInGroups("ask_user_question", groups: [.explore, .edit]))
		XCTAssertFalse(aliased.isInGroups("does_not_exist", groups: FixtureGroup.allCases))
	}

	func testCanonicalNameShadowsAnAliasKeyInGroupLookup() {
		// Same canonical-first order as `MCPToolAliasResolver.canonicalTool(named:)`.
		let shadowed = MCPToolGroupMap<FixtureGroup, FixtureTool>(
			mapping: map.mapping,
			aliases: ["read_file": .applyEdits]
		)
		XCTAssertEqual(shadowed.groups(forToolNamed: "read_file"), [.explore, .conversation])
	}

	func testIsInGroups() {
		XCTAssertTrue(map.isInGroups("apply_edits", groups: [.edit]))
		XCTAssertTrue(map.isInGroups("read_file", groups: [.conversation]))
		XCTAssertFalse(map.isInGroups("apply_edits", groups: [.explore, .conversation]))
		XCTAssertFalse(map.isInGroups("does_not_exist", groups: FixtureGroup.allCases))
		XCTAssertFalse(map.isInGroups("orphan_tool", groups: FixtureGroup.allCases))
	}
}
