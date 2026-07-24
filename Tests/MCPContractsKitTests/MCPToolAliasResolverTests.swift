import XCTest
@testable import MCPContractsKit

/// Characterization of the alias-aware name-resolution mechanism, mirroring
/// the semantics RepoPrompt's `MCPToolCatalog` pinned before extraction.
final class MCPToolAliasResolverTests: XCTestCase {
	private let resolver = MCPToolAliasResolver<FixtureTool>(
		aliases: ["ask_user_question": .askUser]
	)

	func testAllRecognizedNamesIsCanonicalPlusAliasKeys() {
		XCTAssertEqual(
			resolver.allRecognizedNames,
			Set(FixtureTool.allCases.map(\.rawValue)).union(["ask_user_question"])
		)
		XCTAssertEqual(resolver.allRecognizedNames.count, FixtureTool.allCases.count + 1)
	}

	func testCanonicalNameResolves() {
		XCTAssertEqual(resolver.canonicalTool(named: "ask_user"), .askUser)
		XCTAssertEqual(resolver.canonicalTool(named: "read_file"), .readFile)
	}

	func testAliasResolvesToItsCanonicalTool() {
		XCTAssertEqual(resolver.canonicalTool(named: "ask_user_question"), .askUser)
	}

	func testUnknownNameResolvesToNil() {
		XCTAssertNil(resolver.canonicalTool(named: "does_not_exist"))
	}

	func testCanonicalNameShadowsAnAliasKeyOfTheSameName() {
		// Resolution order is canonical-first (`Tool(rawValue:) ?? aliases[name]`):
		// an alias key colliding with a canonical wire name can never redirect it.
		let shadowed = MCPToolAliasResolver<FixtureTool>(
			aliases: ["read_file": .applyEdits]
		)
		XCTAssertEqual(shadowed.canonicalTool(named: "read_file"), .readFile)
	}

	func testEmptyAliasTableRecognizesExactlyTheCanonicalNames() {
		let bare = MCPToolAliasResolver<FixtureTool>(aliases: [:])
		XCTAssertEqual(bare.allRecognizedNames, Set(FixtureTool.allCases.map(\.rawValue)))
		XCTAssertNil(bare.canonicalTool(named: "ask_user_question"))
	}
}
