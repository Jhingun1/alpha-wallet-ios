// Copyright © 2020 Stormbird PTE. LTD.

import Foundation
import BigInt

struct TokenScriptFilterParser {
    enum Operator: String {
        case equal = "="
        case lessThan = "<"
        case greaterThan = ">"
        case lessThanOrEqual = "<="
        case greaterThanOrEqual = ">="

        func isTrueFor(tokenHolder: TokenHolder, attribute: String, value: String) -> Bool {
            guard let attributeValue = tokenHolder.values[attribute]?.value.resolvedValue else { return false }
            return isTrueFor(attributeValue: attributeValue, value: value)
        }

        func isTrueFor(attributeValue: AssetInternalValue, value: String) -> Bool {
            switch attributeValue {
            case .address(let address):
                switch self {
                case .equal:
                    return address.eip55String.lowercased() == value.lowercased()
                case .lessThan:
                    return false
                case .greaterThan:
                    return false
                case .lessThanOrEqual:
                    return false
                case .greaterThanOrEqual:
                    return false
                }
            case .bool(let bool):
                switch self {
                case .equal:
                    return (bool ? "TRUE": "FALSE") == value
                case .lessThan:
                    return false
                case .greaterThan:
                    return false
                case .lessThanOrEqual:
                    return false
                case .greaterThanOrEqual:
                    return false
                }
            case .string(let string):
                switch self {
                case .equal:
                    return string == value
                case .lessThan:
                    return string < value
                case .greaterThan:
                    return string > value
                case .lessThanOrEqual:
                    return string <= value
                case .greaterThanOrEqual:
                    return string >= value
                }
            case .bytes(let bytes):
                guard let a = BigUInt(bytes.hexEncoded, radix: 16), let b = BigUInt(value, radix: 16) else { return false }
                switch self {
                case .equal:
                    return a == b
                case .lessThan:
                    return a < b
                case .greaterThan:
                    return a > b
                case .lessThanOrEqual:
                    return a <= b
                case .greaterThanOrEqual:
                    return a >= b
                }
            case .int(let int):
                guard let rhs = BigInt(value) else { return false }
                switch self {
                case .equal:
                    return int == rhs
                case .lessThan:
                    return int < rhs
                case .greaterThan:
                    return int > rhs
                case .lessThanOrEqual:
                    return int <= rhs
                case .greaterThanOrEqual:
                    return int >= rhs
                }
            case .uint(let uint):
                //Must check for -ve. Will crash if used to init BigUInt
                if value.trimmed.hasPrefix("-"), let rhs = BigInt(value) {
                    switch self {
                    case .equal:
                        return uint == rhs
                    case .lessThan:
                        return uint < rhs
                    case .greaterThan:
                        return uint > rhs
                    case .lessThanOrEqual:
                        return uint <= rhs
                    case .greaterThanOrEqual:
                        return uint >= rhs
                    }
                } else if let rhs = BigUInt(value) {
                    switch self {
                    case .equal:
                        return uint == rhs
                    case .lessThan:
                        return uint < rhs
                    case .greaterThan:
                        return uint > rhs
                    case .lessThanOrEqual:
                        return uint <= rhs
                    case .greaterThanOrEqual:
                        return uint >= rhs
                    }
                } else {
                    return false
                }
            case .generalisedTime(let generalisedTime):
                guard let rhs = TimeInterval(value) else { return false }
                switch self {
                case .equal:
                    return generalisedTime.date.timeIntervalSince1970 == rhs
                case .lessThan:
                    return generalisedTime.date.timeIntervalSince1970 < rhs
                case .greaterThan:
                    return generalisedTime.date.timeIntervalSince1970 > rhs
                case .lessThanOrEqual:
                    return generalisedTime.date.timeIntervalSince1970 <= rhs
                case .greaterThanOrEqual:
                    return generalisedTime.date.timeIntervalSince1970 >= rhs
                }
            case .subscribable, .openSeaNonFungibleTraits:
                return false
            }
        }
    }

    let expression: String

    func parse() -> (attribute: String, value: String, operator: Operator)? {
        guard let regex = try? NSRegularExpression(pattern: """
                                                            (?x)
                                                            ^
                                                            (?<attribute>[a-zA-Z]([a-zA-Z0-9])*)
                                                            (?<operator>(= | < | > | <= | >=))
                                                            (?<value>[-a-zA-Z0-9]+([\\s\\.\\-a-zA-Z0-9])*)
                                                            $
                                                            """, options: []) else { return nil }
        let range = NSRange(expression.startIndex ..< expression.endIndex, in: expression)
        let matches = regex.matches(in: expression, options: [], range: range)
        guard matches.count == 1 else { return nil }
        guard let attributeRange = Range(matches[0].range(withName: "attribute"), in: expression) else { return nil }
        guard let opRange = Range(matches[0].range(withName: "operator"), in: expression) else { return nil }
        guard let valueRange = Range(matches[0].range(withName: "value"), in: expression) else { return nil }
        let attribute = String(expression[attributeRange])
        let value = String(expression[valueRange])
        guard let op = Operator(rawValue: String(expression[opRange])) else { return nil  }
        return (attribute: attribute, value: value, operator: op)
    }
}
