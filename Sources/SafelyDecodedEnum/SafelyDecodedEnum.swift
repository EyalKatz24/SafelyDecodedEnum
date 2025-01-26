/// An enum-only macro that adds an `unknown` enum `case`,
/// adds a `Decodable` conformance if necessary,
/// and adds `public init(from decoder: Decoder) throws` .
///
/// The `unknown` case is used as a "default" type on a decode failure (such as new case received in an API call that is not supported yet).
///
/// - NOTE:When you need another implementation of `init(from decoder: Decoder) throws`,
///  do not use that macro.
///
/// Usage example:
///```swift
/// @SafelyDecodedEnum
/// enum OperationType: String {
///     case credit = "CREDIT"
///     case debit = "DEBIT"
/// }
///```
/// The macro `Localized` after macro expansion:
///```swift
/// enum OperationType: String {
///     case credit = "CREDIT"
///     case debit = "DEBIT"
///
///     case unknown = "UNKNOWN"
///
///     public init(from decoder: Decoder) throws {
///         let container = try decoder.singleValueContainer()
///         let rawValue = try container.decode(String.self)
///         self = Self(rawValue: rawValue) ?? .unknown
///     }
/// }
///
/// public extension OperationType: Decodable {
/// }
///```
@attached(member, names: arbitrary)
@attached(extension, conformances: Decodable)
public macro SafelyDecodedEnum(rawValue: RawValueType? = nil, safeCase: SafeCase = .unknown) = #externalMacro(module: "SafelyDecodedEnumMacros", type: "SafelyDecodedEnumMacro")

public enum RawValueType {
    case string(String)
    case int(Int)
}

public enum SafeCase {
    case unknown
    case undefined
    case none
    case general
}
