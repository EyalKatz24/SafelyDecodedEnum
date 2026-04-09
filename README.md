# SafelyDecodedEnum

[![Swift](https://img.shields.io/badge/Swift-5.10+-orange.svg)](https://swift.org)
[![SPM](https://img.shields.io/badge/SPM-Compatible-brightgreen.svg)](https://swift.org/package-manager)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

✨ **SafelyDecodedEnum** helps with `String` and `Int` raw-value enums when the payload can include values you have not modeled yet, for example, new API cases. Instead of a failed decode, those values map to a **fallback case** you choose.

You also get **`allDefinedCases`**: only the cases you wrote, not that fallback. If you use `CaseIterable`, **`allCases`** includes the synthesized safe case; **`allDefinedCases`** does not.

> **Note:** Need your own `init(from decoder: Decoder) throws`? This macro is not for that.

## Requirements

- **Swift 5.10+**, an Xcode that supports **Swift macros**, and macro support enabled for your target (defaults are fine on recent Xcode).
- **Platforms:** iOS 13+, macOS 10.15+, tvOS 13+, watchOS 6+, Mac Catalyst 13+ (see `Package.swift` for the full list).

## 📦 Add to your Xcode project

1. **File -> Add Package Dependencies...**
2. Paste:

```
https://github.com/EyalKatz24/SafelyDecodedEnum.git
```

3. Pick a [release](https://github.com/EyalKatz24/SafelyDecodedEnum/releases) or branch, then add **SafelyDecodedEnum** to your target.

You link **SafelyDecodedEnum**; SwiftPM pulls in the macro plugin on its own.

### Using with AI coding assistants

If you use tools such as **Cursor**, **GitHub Copilot**, **Claude Code**, **ChatGPT** (custom instructions), **Kiro**, **Xcode** (e.g. Swift Assist), or similar in **your** app, the assistant only sees what you teach it. **Best practice:** copy the rules from [`AGENTS.md`](AGENTS.md) into your project’s agent or IDE rules, Copilot instructions, or app-level `AGENTS.md`. That keeps the model from misusing `allDefinedCases` or omitting the synthesized safe case in `switch` logic.

## 💡 Basic usage

```swift
import SafelyDecodedEnum

@SafelyDecodedEnum
enum OperationType: String {
    case credit = "CREDIT"
    case debit = "DEBIT"
}
```

**Same enum with the macro expanded** (your cases plus what the macro generates):

```swift
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

extension OperationType: Decodable { }
```

Want encoding too? Add **`Encodable`** or **`Codable`**. Already **`Decodable`**? The macro does not add another `extension` for `Decodable`.

## 🔧 Custom safe case and raw value

Set the fallback's **name** with **`safeCase`** and its **raw value** with **`rawValue`**. The macro still adds **`init(from:)`** and **`allDefinedCases`** the same way as in Basic usage; **`Decodable`** is only added when the enum does not already declare it.

```swift
@SafelyDecodedEnum(rawValue: .int(-999), safeCase: .general)
enum Order: Int, Decodable {
    case first = 1
    case second = 2
    case last = 3
}
```

**Macro adds:** the extra case is `case general = -999`. **`allDefinedCases`** is `[.first, .second, .last]`. No new `extension` for `Decodable` here because the enum already conforms.

### More examples

Custom string raw for the safe case; name stays the default **`unknown`**:

```swift
@SafelyDecodedEnum(rawValue: .string("MY_DEFAULT"))
enum Status: String {
    case ok = "OK"
    case fail = "FAIL"
}
```

**Macro adds:** `case unknown = "MY_DEFAULT"`. Everything else follows Basic usage (`init(from:)`, **`allDefinedCases`**, `Decodable`).

Custom safe case name only; on **`String`** enums the raw value is the **uppercase** spelling of that name unless you also pass **`rawValue`**:

```swift
@SafelyDecodedEnum(safeCase: .undefined)
enum Role: String {
    case user
    case admin
}
```

**Macro adds:** `case undefined = "UNDEFINED"`. Everything else follows Basic usage (`init(from:)`, **`allDefinedCases`**, `Decodable`).

**`SafeCase`:** `.unknown`, `.undefined`, `.none`, `.general`.

If you need behavior outside what the macro generates, write your own decoding and do not use this package for that enum.
