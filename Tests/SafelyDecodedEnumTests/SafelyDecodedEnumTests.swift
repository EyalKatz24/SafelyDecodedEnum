import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(SafelyDecodedEnumMacros)
import SafelyDecodedEnumMacros

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
                .init(message: "'SafelyDecodedEnum' macro can only be attached to enums", line: 1, column: 1)
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

                case unknown = "UNKNOWN"
            
                public init(from decoder: Decoder) throws {
                    let container = try decoder.singleValueContainer()
                    let rawValue = try container.decode(String.self)
                    self = Self(rawValue: rawValue) ?? .unknown
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
            
                case unknown = "UNKNOWN"
            
                public init(from decoder: Decoder) throws {
                    let container = try decoder.singleValueContainer()
                    let rawValue = try container.decode(String.self)
                    self = Self(rawValue: rawValue) ?? .unknown
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
            
                case unknown = "UNKNOWN"
            
                public init(from decoder: Decoder) throws {
                    let container = try decoder.singleValueContainer()
                    let rawValue = try container.decode(String.self)
                    self = Self(rawValue: rawValue) ?? .unknown
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
            
                case unknown = "UNKNOWN"
            
                public init(from decoder: Decoder) throws {
                    let container = try decoder.singleValueContainer()
                    let rawValue = try container.decode(String.self)
                    self = Self(rawValue: rawValue) ?? .unknown
                }
            }
            
            extension OperationType: Decodable {
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
            
                case unknown = "UNKNOWN"
            
                public init(from decoder: Decoder) throws {
                    let container = try decoder.singleValueContainer()
                    let rawValue = try container.decode(String.self)
                    self = Self(rawValue: rawValue) ?? .unknown
                }
            }
            """,
            diagnostics: [
                .init(message: "'SafelyDecodedEnum' enum must have a `String` rawValue", line: 1, column: 1)
            ],
            macros: testMacros
        )
        #endif
    }
    
    func testNotStringConformance() {
        #if canImport(SafelyDecodedEnumMacros)
        assertMacroExpansion(
            """
            @SafelyDecodedEnum
            enum OperationType: Int {
                case credit
                case debit
            }
            """,
            expandedSource:
            """
            enum OperationType: Int {
                case credit
                case debit
            
                case unknown = "UNKNOWN"
            
                public init(from decoder: Decoder) throws {
                    let container = try decoder.singleValueContainer()
                    let rawValue = try container.decode(String.self)
                    self = Self(rawValue: rawValue) ?? .unknown
                }
            }
            """,
            diagnostics: [
                .init(message: "'SafelyDecodedEnum' enum must have a `String` rawValue", line: 1, column: 1)
            ],
            macros: testMacros
        )
        #endif
    }
}
