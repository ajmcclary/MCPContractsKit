import XCTest
@testable import MCPContractsKit

/// Characterization of the capability↔tool map algebra, mirroring the
/// semantics RepoPrompt's `MCPToolCapabilities` pinned before extraction.
final class MCPCapabilityToolMapTests: XCTestCase {
	/// `askUser` is deliberately a member of TWO capabilities so reverse
	/// lookup proves multi-membership; `agentControl` spans two tools so
	/// forward lookup proves union semantics; `orphan` is covered by nothing.
	private let map = MCPCapabilityToolMap<FixtureCapability, FixtureTool>(mapping: [
		.fileRead: [.readFile],
		.fileEdit: [.applyEdits],
		.userInteraction: [.askUser],
		.agentControl: [.runAgent, .askUser]
	])

	func testToolsForCapabilitiesUnionsMemberSets() {
		XCTAssertEqual(map.tools(for: [.fileRead]), [.readFile])
		XCTAssertEqual(map.tools(for: [.fileRead, .agentControl]), [.readFile, .runAgent, .askUser])
		XCTAssertEqual(map.tools(for: []), [])
	}

	func testTypedAndStringAPIsAgree() {
		for capability in FixtureCapability.allCases {
			XCTAssertEqual(
				map.toolNames(for: [capability]),
				Set(map.tools(for: [capability]).map(\.rawValue)),
				"typed/string derivations disagree for \(capability.externalName)"
			)
		}
		XCTAssertEqual(
			map.toolNames(for: Set(FixtureCapability.allCases)),
			["read_file", "apply_edits", "ask_user", "run_agent"]
		)
	}

	func testCapabilitiesForToolReportsEveryMembership() {
		XCTAssertEqual(map.capabilities(for: FixtureTool.askUser), [.userInteraction, .agentControl])
		XCTAssertEqual(map.capabilities(for: FixtureTool.readFile), [.fileRead])
	}

	func testUncoveredToolHasNoCapabilities() {
		XCTAssertEqual(map.capabilities(for: FixtureTool.orphan), [])
	}

	func testStringLookupResolvesCanonicalWireNamesOnly() {
		XCTAssertEqual(map.capabilities(for: "ask_user"), [.userInteraction, .agentControl])
		// Alias-style and unknown names have no capabilities — empty, never nil/throw.
		XCTAssertEqual(map.capabilities(for: "ask_user_question"), [])
		XCTAssertEqual(map.capabilities(for: "does_not_exist"), [])
	}

	func testCapabilityAbsentFromMappingDerivesNoTools() {
		let partial = MCPCapabilityToolMap<FixtureCapability, FixtureTool>(mapping: [
			.fileRead: [.readFile]
		])
		XCTAssertEqual(partial.tools(for: [.agentControl]), [])
		XCTAssertEqual(partial.toolNames(for: [.agentControl, .fileRead]), ["read_file"])
	}
}
