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
        
        guard let rawValueType = rawValueType(from: declaration) else {
            // TODO: Fix diagnostic
            context.diagnose(.notStringRawValue, with: declaration)
            return []
        }
        
        let members = enumDecl.memberBlock.members
        let caseDecls = members.compactMap { $0.decl.as(EnumCaseDeclSyntax.self) }
        var declarations: [DeclSyntax] = []
        var safeCase = "unknown"
        var rawValue = rawValueType == "Int" ? "-1" : "UNKNOWN"
        
        if case let .argumentList(arguments) = node.arguments {
            if let safeCaseArgument = arguments.first(where: { $0.label?.identifier?.name == "safeCase" })?.expression.as(MemberAccessExprSyntax.self)?.description.replacingOccurrences(of: ".", with: "") {
                safeCase = safeCaseArgument
            }
            
            let rawValueTypeArgument = arguments.first(where: { $0.label?.identifier?.name == "rawValue" })?.expression.as(FunctionCallExprSyntax.self)?.calledExpression.as(MemberAccessExprSyntax.self)?.description.replacingOccurrences(of: ".", with: "").capitalized
            
            if let rawValueTypeArgument, rawValueType != rawValueTypeArgument {
                // TODO: Fix diagnostic
                context.diagnose(.notStringRawValue, with: declaration)
                return []
            }
            
            rawValue = arguments.first(where: { $0.label?.identifier?.name == "rawValue" })?.expression.as(FunctionCallExprSyntax.self)?.arguments.description.replacingOccurrences(of: "\"", with: "") ?? safeCase.uppercased()
                
            // TODO: Check String/Int conformance
                
        }
                
        let calculatedRawValue = rawValueType == "Int" ? rawValue : "\"\(rawValue)\""
        
        let unknownCaseDecl = try EnumCaseDeclSyntax(
                """
                case \(raw: safeCase) = \(raw: calculatedRawValue)
                """
        )
        declarations.append(DeclSyntax(unknownCaseDecl))
        
        let initDecl = try initDecl(with: safeCase)
        declarations.append(DeclSyntax(initDecl))
        return declarations
    }
    
    // ATM our models are public in modularization - check if this initializer can be internal.
    private static func initDecl(with safeCase: String) throws -> InitializerDeclSyntax {
        try InitializerDeclSyntax("public init(from decoder: Decoder) throws") {
            try VariableDeclSyntax("let container = try decoder.singleValueContainer()")
            try VariableDeclSyntax("let rawValue = try container.decode(String.self)")
            
            """
            self = Self(rawValue: rawValue) ?? .\(raw: safeCase)
            """
        }
    }
}

extension SafelyDecodedEnumMacro: ExtensionMacro {
    public static func expansion(of node: SwiftSyntax.AttributeSyntax, attachedTo declaration: some SwiftSyntax.DeclGroupSyntax, providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol, conformingTo protocols: [SwiftSyntax.TypeSyntax], in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
        let inheritedTypes = declaration.inheritanceClause?.inheritedTypes
        
        guard let inheritedTypes, let _ = rawValueType(from: declaration) else {
            // TODO: Fix diagnostic
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

extension SafelyDecodedEnumMacro {
    
    fileprivate static func rawValueType(from declaration: some SwiftSyntax.DeclGroupSyntax) -> String? {
        let inheritedTypes = declaration.inheritanceClause?.inheritedTypes
        
        guard let type = inheritedTypes?.first?.type.as(IdentifierTypeSyntax.self)?.name.description.trimmed,
              ["String", "Int"].contains(type) else {
            return nil
        }
        
        return type
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
