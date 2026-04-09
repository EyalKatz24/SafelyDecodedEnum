# SafelyDecodedEnum

[![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)
[![SPM](https://img.shields.io/badge/SPM-Compatible-brightgreen.svg)](https://swift.org/package-manager)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

A macro for `String` and `Int` raw-value enums that need **safe decoding**: unknown raw values map to a dedicated fallback case instead of failing decode. It adds that **safe case**, a throwing `init(from:)`, `Decodable` if needed, and a static **`allDefinedCases`** property listing only the cases you wrote, not the safe fallback. By contrast, **`CaseIterable.allCases`** (if you conform) lists every case, including the synthesized safe case.

> [!NOTE]
> If you need a custom `init(from decoder: Decoder) throws`, do not use this macro.

## Basic usage

```swift
@SafelyDecodedEnum
enum OperationType: String {
    case credit = "CREDIT"
    case debit = "DEBIT"
}
```

Roughly expands to:

```swift
enum OperationType: String {
    case credit = "CREDIT"
    case debit = "DEBIT"

    case unknown = "UNKNOWN"

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = Self(rawValue: rawValue) ?? .unknown
    }

    static var allDefinedCases: [Self] {
        [.credit, .debit]
    }
}

extension OperationType: Decodable { }
```

Add `Encodable` (or `Codable`) on the enum yourself if you need encoding. If the enum already declares `Decodable`, the macro does not emit a separate `extension ... : Decodable`.

## Custom safe case and raw value

When the default fallback name (`unknown`) or raw value is wrong for your API, pass `rawValue` and/or `safeCase`:

```swift
@SafelyDecodedEnum(rawValue: .int(-999), safeCase: .general)
enum Order: Int, Decodable {
    case first = 1
    case second = 2
    case last = 3
}
```

Expands to something like:

```swift
enum Order: Int, Decodable {
    case first = 1
    case second = 2
    case last = 3

    case general = -999

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(Int.self)
        self = Self(rawValue: rawValue) ?? .general
    }

    static var allDefinedCases: [Self] {
        [.first, .second, .last]
    }
}
```

`SafeCase` options are `.unknown`, `.undefined`, `.none`, and `.general`. For `String` enums, the safe case's raw value defaults to that name uppercased unless you pass `rawValue`.
