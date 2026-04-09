//
//  SafelyDecodedEnumMacro+MemberMacro.swift
//  SafelyDecodedEnum
//
//  Created by Eyal Katz on 10/04/2026.
//

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

extension SafelyDecodedEnumMacro: MemberMacro {
    static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard declaration.isEnum else {
            context.diagnose(.notAnEnum, with: declaration)
            return []
        }

        guard let rawValueType = rawValueType(from: declaration) else {
            context.diagnose(.invalidRawValue, with: declaration)
            return []
        }

        guard let enumDecl = declaration.as(EnumDeclSyntax.self) else {
            return []
        }

        var safeCase = "unknown"
        var rawValue = rawValueType.defaultValue
        var hasSafeCaseArgument = false
        var hasRawValueArgument = false

        if case let .argumentList(arguments) = node.arguments {
            if let safeCaseArgument = arguments.first(where: { $0.label?.identifier?.name == "safeCase" })?
                .expression.as(MemberAccessExprSyntax.self)?
                .description.removing(".") {
                safeCase = safeCaseArgument
                hasSafeCaseArgument = true
            }

            let rawValueTypeArgument = arguments.first(where: { $0.label?.identifier?.name == "rawValue" })?
                .expression.as(FunctionCallExprSyntax.self)?
                .calledExpression.as(MemberAccessExprSyntax.self)?
                .description.replacingOccurrences(of: ".", with: "").capitalized

            if let rawValueTypeArgument,
               let supportedTypeFromArgument = SupportedRawValueType(rawValue: rawValueTypeArgument),
               rawValueType != supportedTypeFromArgument {
                context.diagnose(.rawValueMismatch, with: declaration)
                return []
            }

            if let rawValueFromArgument = arguments.first(where: { $0.label?.identifier?.name == "rawValue" })?
                .expression.as(FunctionCallExprSyntax.self)?
                .arguments.description.removing("\"") {
                rawValue = rawValueFromArgument
                hasRawValueArgument = true
            }
        }

        let safeEnumCaseDecl = try safeEnumCaseDecl(
            safeCase,
            hasSafeCaseArgument: hasSafeCaseArgument,
            rawValue: rawValue,
            hasRawValueArgument: hasRawValueArgument,
            rawValueType: rawValueType
        )
        let initDecl = try initDecl(with: safeCase, rawValueType: rawValueType)
        let allDefinedCasesDecl = try allDefinedCasesDecl(
            enumDecl: enumDecl,
            excludingSafeCase: safeCase
        )
        return [
            DeclSyntax(safeEnumCaseDecl),
            DeclSyntax(initDecl),
            DeclSyntax(allDefinedCasesDecl),
        ]
    }
}

extension DeclGroupSyntax {
    fileprivate var isEnum: Bool {
        self.as(EnumDeclSyntax.self) != nil
    }
}
