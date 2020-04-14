// Copyright © 2020 Stormbird PTE. LTD.

import Foundation
import XCTest
import BigInt
@testable import AlphaWallet

class TokenScriptFilterParserTests: XCTestCase {
    private func evaluate(expression: String, againstAttributeValue attributeValue: AssetInternalValue) -> Bool {
        let parser = TokenScriptFilterParser(expression: expression)
        let result = parser.parse()
        guard let (_, value: value, operator: op) = result else {
            XCTFail()
            return false
        }
        return op.isTrueFor(attributeValue: attributeValue, value: value)
    }

    func testEvaluationToTrue() {
        XCTAssertEqual(evaluate(expression: "expired=TRUE", againstAttributeValue: .bool(true)), true)
        XCTAssertEqual(evaluate(expression: "expired=123", againstAttributeValue: .int(BigInt(123))), true)
        XCTAssertEqual(evaluate(expression: "expired=Tokens", againstAttributeValue: .string("Tokens")), true)
        XCTAssertEqual(evaluate(expression: "expired=-Tokens", againstAttributeValue: .string("-Tokens")), true)
        XCTAssertEqual(evaluate(expression: "expired=Two Words", againstAttributeValue: .string("Two Words")), true)
        XCTAssertEqual(evaluate(expression: "expired=123", againstAttributeValue: .uint(BigUInt(123))), true)
    }

    func testEvaluationOfAddresses() {
        XCTAssertEqual(evaluate(expression: "addy=0x007bEe82BDd9e866b2bd114780a47f2261C684E3", againstAttributeValue: .address(.make(address: "0x007bEe82BDd9e866b2bd114780a47f2261C684E3"))), true)
        XCTAssertEqual(evaluate(expression: "addy=0x007bee82bdd9e866b2bd114780a47f2261c684e3", againstAttributeValue: .address(.make(address: "0x007bEe82BDd9e866b2bd114780a47f2261C684E3"))), true)
    }

    func testEvaluationToFalse() {
        XCTAssertEqual(evaluate(expression: "expired=TRUE", againstAttributeValue: .bool(false)), false)
        XCTAssertEqual(evaluate(expression: "expired=true", againstAttributeValue: .bool(true)), false)
        XCTAssertEqual(evaluate(expression: "expired=1.23", againstAttributeValue: .int(BigInt(123))), false)
        XCTAssertEqual(evaluate(expression: "expired=-123", againstAttributeValue: .int(BigInt(123))), false)
        XCTAssertEqual(evaluate(expression: "expired=-1.23", againstAttributeValue: .int(BigInt(123))), false)
    }

    func testEvaluationDoNotCrash() {
        XCTAssertEqual(evaluate(expression: "expired=-123", againstAttributeValue: .uint(BigUInt(123))), false)
        XCTAssertEqual(evaluate(expression: "expired=- 123", againstAttributeValue: .uint(BigUInt(123))), false)
        XCTAssertEqual(evaluate(expression: "expired=1.23", againstAttributeValue: .uint(BigUInt(123))), false)
        XCTAssertEqual(evaluate(expression: "expired=1.2.3", againstAttributeValue: .uint(BigUInt(123))), false)
    }

    func testParsingShouldFailWithLeadingSpaceInRightHandSide() {
        XCTAssertNil(TokenScriptFilterParser(expression: "expired= -123").parse())
        XCTAssertNil(TokenScriptFilterParser(expression: "expired= 123").parse())
    }

    func testParsingShouldFailWithSpaceInLeftHandSide() {
        XCTAssertNil(TokenScriptFilterParser(expression: "expired something=123").parse())
    }
}
