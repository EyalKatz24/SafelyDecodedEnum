//
//  SafelyDecodedEnumMacroPlugin.swift
//  SafelyDecodedEnum
//
//  Created by Eyal Katz on 10/04/2026.
//

import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct SafelyDecodedEnumMacroPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        SafelyDecodedEnumMacro.self
    ]
}
