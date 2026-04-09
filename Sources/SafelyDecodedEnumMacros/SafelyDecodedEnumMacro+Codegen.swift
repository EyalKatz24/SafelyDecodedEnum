//
//  SafelyDecodedEnumMacro+Codegen.swift
//  SafelyDecodedEnum
//
//  Created by Eyal Katz on 10/04/2026.
//

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

extension SafelyDecodedEnumMacro {
    enum SupportedRawValueType: String, CaseIterable {
        case int = "Int"
        case string = "String"

        var defaultValue: String {
            switch self {
            case .int: "-1"
            case .string: "UNKNOWN"
            }
        }
    }

    static func rawValueType(from declaration: some DeclGroupSyntax) -> SupportedRawValueType? {
        let inheritedTypes = declaration.inheritanceClause?.inheritedTypes
        guard let type = inheritedTypes?.first?.type.as(IdentifierTypeSyntax.self)?.name.description.trimmed else {
            return nil
        }
        return SupportedRawValueType(rawValue: type)
    }

    // ATM our models are public in modularization - check if this initializer can be internal.
    static func initDecl(with safeCase: String, rawValueType: SupportedRawValueType) throws -> InitializerDeclSyntax {
        try InitializerDeclSyntax("public init(from decoder: Decoder) throws") {
            try VariableDeclSyntax("let container = try decoder.singleValueContainer()")
            try VariableDeclSyntax("let rawValue = try container.decode(\(raw: rawValueType.rawValue).self)")

            """
            self = Self(rawValue: rawValue) ?? .\(raw: safeCase)
            """
        }
    }

    private static func userDefinedCaseNames(excluding safeCase: String, from enumDecl: EnumDeclSyntax) -> [String] {
        var names: [String] = []
        for member in enumDecl.memberBlock.members {
            guard let caseDecl = member.decl.as(EnumCaseDeclSyntax.self) else { continue }
            for element in caseDecl.elements {
                guard element.parameterClause == nil else { continue }
                let name = element.name.text
                if name != safeCase {
                    names.append(name)
                }
            }
        }
        return names
    }

    /// Leading access keyword and space (e.g. `"public "`), or empty when the enum uses default `internal` access.
    private static func accessLevelModifierPrefix(from enumDecl: EnumDeclSyntax) -> String {
        let accessKeywords: Set<String> = ["public", "internal", "private", "fileprivate", "open", "package"]
        guard let modifier = enumDecl.modifiers.first(where: { accessKeywords.contains($0.name.text) }) else {
            return ""
        }
        return "\(modifier.name.text) "
    }

    static func allDefinedCasesDecl(enumDecl: EnumDeclSyntax, excludingSafeCase safeCase: String) throws -> VariableDeclSyntax {
        let caseNames = userDefinedCaseNames(excluding: safeCase, from: enumDecl)
        let arrayLiteral: String = if caseNames.isEmpty {
            "[]"
        } else {
            "[" + caseNames.map { ".\($0)" }.joined(separator: ", ") + "]"
        }
        let modifierPrefix = accessLevelModifierPrefix(from: enumDecl)
        return try VariableDeclSyntax(
            """
            /// All cases you declared in source, excluding the synthesized safe fallback. Expanded from `@SafelyDecodedEnum`.
            \(raw: modifierPrefix)static var allDefinedCases: [Self] {
                \(raw: arrayLiteral)
            }
            """
        )
    }

    static func safeEnumCaseDecl(
        _ safeCase: String,
        hasSafeCaseArgument: Bool,
        rawValue: String,
        hasRawValueArgument: Bool,
        rawValueType: SupportedRawValueType
    ) throws -> EnumCaseDeclSyntax {
        let calculatedRawValue = switch rawValueType {
        case .int: rawValue
        case .string: hasRawValueArgument ? "\"\(rawValue)\"" : "\"\(safeCase.uppercased())\""
        }

        return try EnumCaseDeclSyntax(
            """
            /// Used when decoding does not match any user-defined case. Expanded from `@SafelyDecodedEnum`.
            case \(raw: safeCase) = \(raw: calculatedRawValue)
            """
        )
    }
}

/// Shared by member expansion parsing and raw-value inference (same module as the macro target).
extension String {
    var trimmed: Self {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func removing<Target>(_ target: Target) -> String where Target: StringProtocol {
        replacingOccurrences(of: target, with: "")
    }
}
