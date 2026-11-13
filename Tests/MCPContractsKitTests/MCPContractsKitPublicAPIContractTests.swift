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

	func testStringLookupsResolveSuppliedAliasesExactlyLikeCanonicalTool() {
		let aliases: [String: FixtureTool] = ["ask_user_question": .askUser, "read_file": .applyEdits]
		let resolver = MCPToolAliasResolver<FixtureTool>(aliases: aliases)
		let capabilityMap = MCPCapabilityToolMap<FixtureCapability, FixtureTool>(
			mapping: [.userInteraction: [.askUser], .fileRead: [.readFile], .fileEdit: [.applyEdits]],
			aliases: aliases
		)
		let groupMap = MCPToolGroupMap<FixtureGroup, FixtureTool>(
			mapping: [.conversation: [.askUser], .explore: [.readFile], .edit: [.applyEdits]],
			aliases: aliases
		)
		for name in resolver.allRecognizedNames.union(["does_not_exist"]) {
			let tool = resolver.canonicalTool(named: name)
			XCTAssertEqual(
				capabilityMap.capabilities(for: name),
				tool.map { capabilityMap.capabilities(for: $0) } ?? [],
				"capabilities disagree with canonicalTool(named:) for \(name)"
			)
			XCTAssertEqual(
				groupMap.groups(forToolNamed: name),
				tool.map { groupMap.groups(forToolNamed: $0.rawValue) } ?? [],
				"groups disagree with canonicalTool(named:) for \(name)"
			)
			for group in FixtureGroup.allCases {
				XCTAssertEqual(
					groupMap.isInGroups(name, groups: [group]),
					tool.map { groupMap.isInGroups($0.rawValue, groups: [group]) } ?? false,
					"isInGroups disagrees with canonicalTool(named:) for \(name) in \(group)"
				)
			}
		}
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
