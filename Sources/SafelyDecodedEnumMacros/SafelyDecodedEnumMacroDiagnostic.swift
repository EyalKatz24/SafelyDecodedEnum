//
//  SafelyDecodedEnumMacroDiagnostic.swift
//  SafelyDecodedEnum
//
//  Created by Eyal Katz on 26/01/2025.
//

import SwiftSyntax
import SwiftDiagnostics
import SwiftSyntaxMacros

enum SafelyDecodedEnumMacroDiagnostic {
    case notAnEnum
    case notStringRawValue
    case rawValueMissmatch
}

extension SafelyDecodedEnumMacroDiagnostic: DiagnosticMessage {
    var severity: DiagnosticSeverity { .error }

    var diagnosticID: MessageID {
        MessageID(domain: "Swift", id: "SafelyDecodedEnum.\(self)")
    }

    func diagnose(at node: some SyntaxProtocol) -> Diagnostic {
        Diagnostic(node: Syntax(node), message: self)
    }

    var message: String {
        switch self {
        case .notAnEnum:
            "'SafelyDecodedEnum' macro can only be attached to enums"
        case .notStringRawValue:
            "'SafelyDecodedEnum' enum must have a `String` rawValue"
        case .rawValueMissmatch:
            "The `rawValue` argument doesn't match the enum `RawRepresentable` conformance type"
        }
    }
}

extension MacroExpansionContext {
    func diagnose(_ diagnostic: SafelyDecodedEnumMacroDiagnostic, with declaration: some DeclGroupSyntax) {
        diagnose(diagnostic.diagnose(at: declaration))
    }
}
