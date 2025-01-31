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
        guard declaration.isEnum else {
            context.diagnose(.notAnEnum, with: declaration)
            return []
        }
        
        guard let rawValueType = rawValueType(from: declaration) else {
            context.diagnose(.invalidRawValue, with: declaration)
            return []
        }
        
        var declarations: [DeclSyntax] = []
        var safeCase = "unknown"
        var rawValue = rawValueType.defaultValue
        var hasSafeCaseArgument = false
        var hasRawValueArgument = false
        
        if case let .argumentList(arguments) = node.arguments {
            if let safeCaseArgument = arguments.first(where: { $0.label?.identifier?.name == "safeCase" })?.expression.as(MemberAccessExprSyntax.self)?.description.removing(".") {
                safeCase = safeCaseArgument
                hasSafeCaseArgument = true
            }
            
            let rawValueTypeArgument = arguments.first(where: { $0.label?.identifier?.name == "rawValue" })?.expression.as(FunctionCallExprSyntax.self)?.calledExpression.as(MemberAccessExprSyntax.self)?.description.replacingOccurrences(of: ".", with: "").capitalized
            
            if let rawValueTypeArgument, let supportedTypeFromArgument = SupportedRawValueType(rawValue: rawValueTypeArgument), rawValueType != supportedTypeFromArgument {
                context.diagnose(.rawValueMismatch, with: declaration)
                return []
            }
            
            if let rawValueFromArgument = arguments.first(where: { $0.label?.identifier?.name == "rawValue" })?.expression.as(FunctionCallExprSyntax.self)?.arguments.description.removing("\"") {
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
        declarations.append(DeclSyntax(safeEnumCaseDecl))
        declarations.append(DeclSyntax(initDecl))
        return declarations
    }
    
    // ATM our models are public in modularization - check if this initializer can be internal.
    private static func initDecl(with safeCase: String, rawValueType: SupportedRawValueType) throws -> InitializerDeclSyntax {
        try InitializerDeclSyntax("public init(from decoder: Decoder) throws") {
            try VariableDeclSyntax("let container = try decoder.singleValueContainer()")
            try VariableDeclSyntax("let rawValue = try container.decode(\(raw: rawValueType.rawValue).self)")
            
            """
            self = Self(rawValue: rawValue) ?? .\(raw: safeCase)
            """
        }
    }
    
    private static func safeEnumCaseDecl(_ safeCase: String, hasSafeCaseArgument: Bool, rawValue: String, hasRawValueArgument: Bool, rawValueType: SupportedRawValueType) throws -> EnumCaseDeclSyntax {
        let calculatedRawValue = switch rawValueType {
        case .int: rawValue
        case .string: hasRawValueArgument ? "\"\(rawValue)\"" : "\"\(safeCase.uppercased())\""
        }
        
        return try EnumCaseDeclSyntax(
            """
            case \(raw: safeCase) = \(raw: calculatedRawValue)
            """
        )
    }
}

extension SafelyDecodedEnumMacro: ExtensionMacro {
    public static func expansion(of node: SwiftSyntax.AttributeSyntax, attachedTo declaration: some SwiftSyntax.DeclGroupSyntax, providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol, conformingTo protocols: [SwiftSyntax.TypeSyntax], in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
        let inheritedTypes = declaration.inheritanceClause?.inheritedTypes
        
        guard let inheritedTypes, let _ = rawValueType(from: declaration) else {
            context.diagnose(.invalidRawValue, with: declaration)
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
    
    fileprivate enum SupportedRawValueType: String, CaseIterable {
        case int = "Int"
        case string = "String"
        
        var defaultValue: String {
            switch self {
            case .int: "-1"
            case .string: "UNKNOWN"
            }
        }
    }
    
    fileprivate static func rawValueType(from declaration: some SwiftSyntax.DeclGroupSyntax) -> SupportedRawValueType? {
        let inheritedTypes = declaration.inheritanceClause?.inheritedTypes
        guard let type = inheritedTypes?.first?.type.as(IdentifierTypeSyntax.self)?.name.description.trimmed else { return nil }
        return SupportedRawValueType(rawValue: type)
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
    
    func removing<Target>(_ target: Target) -> String where Target: StringProtocol {
        replacingOccurrences(of: target, with: "")
    }
}

fileprivate extension DeclGroupSyntax {
    
    var isEnum: Bool {
        self.as(EnumDeclSyntax.self) != nil
    }
}
