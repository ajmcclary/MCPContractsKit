import XCTest
import MCPContractsKit

/// Public-API contract suite. Deliberately imports WITHOUT `@testable`, so any
/// accidental de-publicizing of the contract surface breaks compilation.
///
/// Pins two things:
/// 1. every vocabulary family stays PUBLIC (compile-time tuple/typealias pins);
/// 2. the mechanism semantics a consumer may persist decisions against:
///    canonical-first alias resolution, canonical-names-only string lookups,
///    `allCases`-ordered group results, and the authorization sentinel.
final class MCPContractsKitPublicAPIContractTests: XCTestCase {
	// A tuple type references each member type without needing constructible
	// values; removal or de-publicizing of any member is a compile error.
	private typealias CatalogMechanismFamily = (
		MCPToolAliasResolver<FixtureTool>,
		MCPCapabilityToolMap<FixtureCapability, FixtureTool>,
		MCPToolGroupMap<FixtureGroup, FixtureTool>
	)
	private typealias ContractShapeFamily = (
		(any MCPToolIdentifying)?,
		(any MCPCapabilityIdentifying)?
	)
	private typealias AuthorizationFamily = (
		MCPConnectionOriginLineage,
		MCPToolCallAuthorizationInput,
		MCPToolCallAuthorizationDecision
	)

	func testConformancesAreAdoptableByAnExternalInventory() {
		// FixtureTool/FixtureCapability live in the TEST module: their
		// conformances prove an app-side inventory can adopt the contracts.
		let tool: any MCPToolIdentifying = FixtureTool.readFile
		let capability: any MCPCapabilityIdentifying = FixtureCapability.fileRead
		XCTAssertEqual(tool.rawValue as? String, "read_file")
		XCTAssertEqual(capability.externalName, "file_read")
	}

	func testAliasResolutionIsCanonicalFirst() {
		let resolver = MCPToolAliasResolver<FixtureTool>(aliases: ["read_file": .applyEdits])
		XCTAssertEqual(resolver.canonicalTool(named: "read_file"), .readFile)
	}

	func testStringLookupsAreCanonicalNamesOnly() {
		let capabilityMap = MCPCapabilityToolMap<FixtureCapability, FixtureTool>(
			mapping: [.userInteraction: [.askUser]]
		)
		let groupMap = MCPToolGroupMap<FixtureGroup, FixtureTool>(
			mapping: [.conversation: [.askUser]]
		)
		XCTAssertEqual(capabilityMap.capabilities(for: "ask_user_question"), [])
		XCTAssertEqual(groupMap.groups(forToolNamed: "ask_user_question"), [])
	}

	func testGroupResultsFollowAllCasesOrder() {
		let map = MCPToolGroupMap<FixtureGroup, FixtureTool>(mapping: [
			.explore: [.readFile],
			.conversation: [.readFile]
		])
		XCTAssertEqual(map.groups(forToolNamed: "read_file"), [.explore, .conversation])
	}

	func testAuthorizationSentinelStaysExternalUnknown() {
		XCTAssertEqual(MCPConnectionOriginLineage.externalUnknown.delegationDepth, 0)
		XCTAssertNil(MCPConnectionOriginLineage.externalUnknown.originProvider)
	}
}
