import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct SafelyDecodedEnumMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let enumDecl = declaration.as(EnumDeclSyntax.self) else {
            context.diagnose(.notAnEnum, with: declaration)
            return []
        }
        
        let members = enumDecl.memberBlock.members
        let caseDecls = members.compactMap { $0.decl.as(EnumCaseDeclSyntax.self) }
        let elements = caseDecls.flatMap { $0.elements }
        var declarations: [DeclSyntax] = []
        
        if !elements.contains(where: { $0.name.description.lowercased().trimmed == "unknown" }) {
            let unknownCaseDecl = try EnumCaseDeclSyntax(
                """
                case unknown = "UNKNOWN"
                """
            )
            declarations.append(DeclSyntax(unknownCaseDecl))
        }
        
        let initDecl = try initDecl(from: elements)
        declarations.append(DeclSyntax(initDecl))
        return declarations
    }
    
    // ATM our models are public in modularization - check if this initializer can be internal.
    private static func initDecl(from elements: [EnumCaseElementListSyntax.Element]) throws -> InitializerDeclSyntax {
        try InitializerDeclSyntax("public init(from decoder: Decoder) throws") {
            try VariableDeclSyntax("let container = try decoder.singleValueContainer()")
            try VariableDeclSyntax("let rawValue = try container.decode(String.self)")
            
            """
            self = Self(rawValue: rawValue) ?? .unknown
            """
        }
    }
}

extension SafelyDecodedEnumMacro: ExtensionMacro {
    public static func expansion(of node: SwiftSyntax.AttributeSyntax, attachedTo declaration: some SwiftSyntax.DeclGroupSyntax, providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol, conformingTo protocols: [SwiftSyntax.TypeSyntax], in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
        let inheritedTypes = declaration.inheritanceClause?.inheritedTypes
        
        guard let inheritedTypes, let firstConformance = inheritedTypes.first, firstConformance.type.as(IdentifierTypeSyntax.self)?.name.description.trimmed == "String" else {
            context.diagnose(.notStringRawValue, with: declaration)
            return []
        }
        
        let conformanceTypeNames = inheritedTypes.compactMap({ $0.type.as(IdentifierTypeSyntax.self)?.name.trimmedDescription })
        
        if conformanceTypeNames.contains("Codable") || conformanceTypeNames.contains("Decodable") {
            return []
        }
        
        let extensionDecl = try ExtensionDeclSyntax("extension \(type.trimmed): Decodable { }")
        return [extensionDecl]
    }
}

@main
struct SafelyDecodedEnumMacroPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        SafelyDecodedEnumMacro.self,
    ]
}

fileprivate extension String {
    var trimmed: Self {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
