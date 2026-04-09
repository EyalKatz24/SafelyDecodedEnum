/// Attached macro for `String` and `Int` raw-value enums that need resilient decoding.
///
/// It synthesizes a **safe fallback** `case` (default name `unknown`; configurable via ``SafeCase``),
/// a `public init(from decoder: Decoder) throws` that maps unknown raw values to that case,
/// `Decodable` via an extension when the enum does not already declare it,
/// and a static `allDefinedCases` array containing only the cases you wrote (the safe case is omitted).
///
/// Use ``RawValueType`` and the macro arguments to override the safe case’s raw value when needed.
///
/// - Note: If you need a custom `init(from decoder: Decoder) throws`, do not use this macro.
///
/// ### Example
///
/// ```swift
/// @SafelyDecodedEnum
/// enum OperationType: String {
///     case credit = "CREDIT"
///     case debit = "DEBIT"
/// }
/// ```
///
/// ### Expanded shape (illustrative)
///
/// ```swift
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
///
///     static var allDefinedCases: [Self] {
///         [.credit, .debit]
///     }
/// }
///
/// extension OperationType: Decodable { }
/// ```
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
