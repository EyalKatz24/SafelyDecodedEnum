//
//  SafelyDecodedEnumTests.swift
//  SafelyDecodedEnum
//
//  Created by Eyal Katz on 26/01/2025.
//

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(SafelyDecodedEnumMacros)
@testable import SafelyDecodedEnumMacros

let testMacros: [String: Macro.Type] = [
    "SafelyDecodedEnum": SafelyDecodedEnumMacro.self
]
#endif

final class SafelyDecodedEnumTests: XCTestCase {
    
    func testNotAnEnumDiagnostic() {
        #if canImport(SafelyDecodedEnumMacros)
        assertMacroExpansion(
            """
            @SafelyDecodedEnum
            struct NotAnEnum: String {
            }
            """,
            expandedSource:
            """
            struct NotAnEnum: String {
            }
            
            extension NotAnEnum: Decodable {
            }
            """,
            diagnostics: [
                .init(message: "`SafelyDecodedEnum` macro can only be attached to enums", line: 1, column: 1)
            ],
            macros: testMacros
        )
        #endif
    }
    
    func testEmptyEnum() {
        #if canImport(SafelyDecodedEnumMacros)
        assertMacroExpansion(
            """
            @SafelyDecodedEnum
            enum OperationType: String, Codable {
            }
            """,
            expandedSource:
            """
            enum OperationType: String, Codable {

                /// Used when decoding does not match any user-defined case. Expanded from `@SafelyDecodedEnum`.
                case unknown = "UNKNOWN"

                public init(from decoder: Decoder) throws {
                    let container = try decoder.singleValueContainer()
                    let rawValue = try container.decode(String.self)
                    self = Self(rawValue: rawValue) ?? .unknown
                }

                /// All cases you declared in source, excluding the synthesized safe fallback. Expanded from `@SafelyDecodedEnum`.
                static var allDefinedCases: [Self] {
                    []
                }
            }
            """,
            macros: testMacros
        )
        #endif
    }
    
    func testUnkownCase() {
        #if canImport(SafelyDecodedEnumMacros)
        assertMacroExpansion(
            """
            @SafelyDecodedEnum
            enum OperationType: String, Codable {
                case credit = "CREDIT"
                case debit = "DEBIT"
            }
            """,
            expandedSource:
            """
            enum OperationType: String, Codable {
                case credit = "CREDIT"
                case debit = "DEBIT"

                /// Used when decoding does not match any user-defined case. Expanded from `@SafelyDecodedEnum`.
                case unknown = "UNKNOWN"

                public init(from decoder: Decoder) throws {
                    let container = try decoder.singleValueContainer()
                    let rawValue = try container.decode(String.self)
                    self = Self(rawValue: rawValue) ?? .unknown
                }

                /// All cases you declared in source, excluding the synthesized safe fallback. Expanded from `@SafelyDecodedEnum`.
                static var allDefinedCases: [Self] {
                    [.credit, .debit]
                }
            }
            """,
            macros: testMacros
        )
        #endif
    }
    
    func testDecodable() {
        #if canImport(SafelyDecodedEnumMacros)
        assertMacroExpansion(
            """
            @SafelyDecodedEnum
            public enum OperationType: String, Decodable {
                case credit = "CREDIT"
                case debit = "DEBIT"
            }
            """,
            expandedSource:
            """
            public enum OperationType: String, Decodable {
                case credit = "CREDIT"
                case debit = "DEBIT"

                /// Used when decoding does not match any user-defined case. Expanded from `@SafelyDecodedEnum`.
                case unknown = "UNKNOWN"

                public init(from decoder: Decoder) throws {
                    let container = try decoder.singleValueContainer()
                    let rawValue = try container.decode(String.self)
                    self = Self(rawValue: rawValue) ?? .unknown
                }

                /// All cases you declared in source, excluding the synthesized safe fallback. Expanded from `@SafelyDecodedEnum`.
                public static var allDefinedCases: [Self] {
                    [.credit, .debit]
                }
            }
            """,
            macros: testMacros
        )
        #endif
    }
    
    func testNotDecodable() {
        #if canImport(SafelyDecodedEnumMacros)
        assertMacroExpansion(
            """
            @SafelyDecodedEnum
            enum OperationType: String {
                case credit = "CREDIT"
                case debit = "DEBIT"
            }
            """,
            expandedSource:
            """
            enum OperationType: String {
                case credit = "CREDIT"
                case debit = "DEBIT"

                /// Used when decoding does not match any user-defined case. Expanded from `@SafelyDecodedEnum`.
                case unknown = "UNKNOWN"

                public init(from decoder: Decoder) throws {
                    let container = try decoder.singleValueContainer()
                    let rawValue = try container.decode(String.self)
                    self = Self(rawValue: rawValue) ?? .unknown
                }

                /// All cases you declared in source, excluding the synthesized safe fallback. Expanded from `@SafelyDecodedEnum`.
                static var allDefinedCases: [Self] {
                    [.credit, .debit]
                }
            }

            extension OperationType: Decodable {
            }
            """,
            macros: testMacros
        )
        #endif
    }
    
    func testIntConformance() {
        #if canImport(SafelyDecodedEnumMacros)
        assertMacroExpansion(
            """
            @SafelyDecodedEnum
            public enum Order: Int, Decodable {
                case first = 1
                case second = 2
                case last = 3
            }
            """,
            expandedSource:
            """
            public enum Order: Int, Decodable {
                case first = 1
                case second = 2
                case last = 3

                /// Used when decoding does not match any user-defined case. Expanded from `@SafelyDecodedEnum`.
                case unknown = -1

                public init(from decoder: Decoder) throws {
                    let container = try decoder.singleValueContainer()
                    let rawValue = try container.decode(Int.self)
                    self = Self(rawValue: rawValue) ?? .unknown
                }

                /// All cases you declared in source, excluding the synthesized safe fallback. Expanded from `@SafelyDecodedEnum`.
                public static var allDefinedCases: [Self] {
                    [.first, .second, .last]
                }
            }
            """,
            macros: testMacros
        )
        #endif
    }
    
    func testNoConformances() {
        #if canImport(SafelyDecodedEnumMacros)
        assertMacroExpansion(
            """
            @SafelyDecodedEnum
            enum OperationType {
                case credit
                case debit
            }
            """,
            expandedSource:
            """
            enum OperationType {
                case credit
                case debit
            }
            """,
            diagnostics: [
                .init(message: "`SafelyDecodedEnum` valid rawValues are `String` and `Int`", line: 1, column: 1),
                .init(message: "`SafelyDecodedEnum` valid rawValues are `String` and `Int`", line: 1, column: 1),
            ],
            macros: testMacros
        )
        #endif
    }
    
    func testNotStringOrIntConformance() {
        #if canImport(SafelyDecodedEnumMacros)
        assertMacroExpansion(
            """
            @SafelyDecodedEnum
            enum OperationType: Int8 {
                case credit
                case debit
            }
            """,
            expandedSource:
            """
            enum OperationType: Int8 {
                case credit
                case debit
            }
            """,
            diagnostics: [
                .init(message: "`SafelyDecodedEnum` valid rawValues are `String` and `Int`", line: 1, column: 1),
                .init(message: "`SafelyDecodedEnum` valid rawValues are `String` and `Int`", line: 1, column: 1),
            ],
            macros: testMacros
        )
        #endif
    }
    
    func testStringArgumenWithSafeCase() {
        #if canImport(SafelyDecodedEnumMacros)
        assertMacroExpansion(
            """
            @SafelyDecodedEnum(rawValue: .string("What"), safeCase: .general)
            enum OperationType: String {
                case credit
                case debit
            }
            """,
            expandedSource:
            """
            enum OperationType: String {
                case credit
                case debit

                /// Used when decoding does not match any user-defined case. Expanded from `@SafelyDecodedEnum`.
                case general = "What"

                public init(from decoder: Decoder) throws {
                    let container = try decoder.singleValueContainer()
                    let rawValue = try container.decode(String.self)
                    self = Self(rawValue: rawValue) ?? .general
                }

                /// All cases you declared in source, excluding the synthesized safe fallback. Expanded from `@SafelyDecodedEnum`.
                static var allDefinedCases: [Self] {
                    [.credit, .debit]
                }
            }

            extension OperationType: Decodable {
            }
            """,
            macros: testMacros
        )
        #endif
    }
    
    func testStringArgumenWithoutSafeCase() {
        #if canImport(SafelyDecodedEnumMacros)
        assertMacroExpansion(
            """
            @SafelyDecodedEnum(rawValue: .string("What"))
            enum OperationType: String {
                case credit
                case debit
            }
            """,
            expandedSource:
            """
            enum OperationType: String {
                case credit
                case debit

                /// Used when decoding does not match any user-defined case. Expanded from `@SafelyDecodedEnum`.
                case unknown = "What"

                public init(from decoder: Decoder) throws {
                    let container = try decoder.singleValueContainer()
                    let rawValue = try container.decode(String.self)
                    self = Self(rawValue: rawValue) ?? .unknown
                }

                /// All cases you declared in source, excluding the synthesized safe fallback. Expanded from `@SafelyDecodedEnum`.
                static var allDefinedCases: [Self] {
                    [.credit, .debit]
                }
            }

            extension OperationType: Decodable {
            }
            """,
            macros: testMacros
        )
        #endif
    }
    
    func testSafeCaseWithoutRawValueArgument() {
        #if canImport(SafelyDecodedEnumMacros)
        assertMacroExpansion(
            """
            @SafelyDecodedEnum(safeCase: .undefined)
            enum OperationType: String {
                case credit
                case debit
            }
            """,
            expandedSource:
            """
            enum OperationType: String {
                case credit
                case debit

                /// Used when decoding does not match any user-defined case. Expanded from `@SafelyDecodedEnum`.
                case undefined = "UNDEFINED"

                public init(from decoder: Decoder) throws {
                    let container = try decoder.singleValueContainer()
                    let rawValue = try container.decode(String.self)
                    self = Self(rawValue: rawValue) ?? .undefined
                }

                /// All cases you declared in source, excluding the synthesized safe fallback. Expanded from `@SafelyDecodedEnum`.
                static var allDefinedCases: [Self] {
                    [.credit, .debit]
                }
            }

            extension OperationType: Decodable {
            }
            """,
            macros: testMacros
        )
        #endif
    }
    
    func testRawValueTypeMismatch() {
        #if canImport(SafelyDecodedEnumMacros)
        assertMacroExpansion(
            """
            @SafelyDecodedEnum(rawValue: .int(-10), safeCase: .undefined)
            enum OperationType: String, Codable {
                case credit
                case debit
            }
            """,
            expandedSource:
            """
            enum OperationType: String, Codable {
                case credit
                case debit
            }
            """,
            diagnostics: [
                .init(message: "The `rawValue` argument doesn't match the enum `RawRepresentable` conformance type", line: 1, column: 1)
            ],
            macros: testMacros
        )
        #endif
    }
    
    func testAllDefinedCasesMultipleElementsOnOneLine() {
        #if canImport(SafelyDecodedEnumMacros)
        assertMacroExpansion(
            """
            @SafelyDecodedEnum
            enum Furniture: String, Codable {
                case chair, table, barTable = "BAR_TABLE"
            }
            """,
            expandedSource:
            """
            enum Furniture: String, Codable {
                case chair, table, barTable = "BAR_TABLE"

                /// Used when decoding does not match any user-defined case. Expanded from `@SafelyDecodedEnum`.
                case unknown = "UNKNOWN"

                public init(from decoder: Decoder) throws {
                    let container = try decoder.singleValueContainer()
                    let rawValue = try container.decode(String.self)
                    self = Self(rawValue: rawValue) ?? .unknown
                }

                /// All cases you declared in source, excluding the synthesized safe fallback. Expanded from `@SafelyDecodedEnum`.
                static var allDefinedCases: [Self] {
                    [.chair, .table, .barTable]
                }
            }
            """,
            macros: testMacros
        )
        #endif
    }
    
    func testSafeCaseNone() {
        #if canImport(SafelyDecodedEnumMacros)
        assertMacroExpansion(
            """
            @SafelyDecodedEnum(safeCase: .none)
            enum OperationType: String {
                case credit
                case debit
            }
            """,
            expandedSource:
            """
            enum OperationType: String {
                case credit
                case debit

                /// Used when decoding does not match any user-defined case. Expanded from `@SafelyDecodedEnum`.
                case none = "NONE"

                public init(from decoder: Decoder) throws {
                    let container = try decoder.singleValueContainer()
                    let rawValue = try container.decode(String.self)
                    self = Self(rawValue: rawValue) ?? .none
                }

                /// All cases you declared in source, excluding the synthesized safe fallback. Expanded from `@SafelyDecodedEnum`.
                static var allDefinedCases: [Self] {
                    [.credit, .debit]
                }
            }

            extension OperationType: Decodable {
            }
            """,
            macros: testMacros
        )
        #endif
    }
}
