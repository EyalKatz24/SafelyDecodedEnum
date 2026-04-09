//
//  SafelyDecodedEnumMacro+ExtensionMacro.swift
//  SafelyDecodedEnum
//
//  Created by Eyal Katz on 10/04/2026.
//

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

extension SafelyDecodedEnumMacro: ExtensionMacro {
    static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        let inheritedTypes = declaration.inheritanceClause?.inheritedTypes

        guard let inheritedTypes, rawValueType(from: declaration) != nil else {
            context.diagnose(.invalidRawValue, with: declaration)
            return []
        }

        let conformanceTypeNames = inheritedTypes.compactMap { $0.type.as(IdentifierTypeSyntax.self)?.name.trimmedDescription }

        if conformanceTypeNames.contains("Codable") || conformanceTypeNames.contains("Decodable") {
            return []
        }

        let extensionDecl = try ExtensionDeclSyntax("extension \(type.trimmed): Decodable { }")
        return [extensionDecl]
    }
}
