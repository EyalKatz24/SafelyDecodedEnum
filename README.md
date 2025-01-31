# SafelyDecodedEnum
 
 A macro for `Decodable` enums, where successful decoding is required. 

 This macro makes sure your enum has `Decodable` conformance,
 and automatically adds a default 'safeCase' with a default `rawValue`,
 unless declared with explicit type and/or value arguments.

 > [!Note] 
 >  When you need another implementation of `init(from decoder: Decoder) throws`, do not use that macro.

 ## Usage examples:
 
 There use of enums is flexible, therefore this macro tries to support the most common ones.
 So far this macro supports the following `RawValue` types:
 
    - **Int**
    - **String**
 
 The basic implementation, is where only `Decodable` conformance is required, 
 and the default safe case and value can be implicit. 
 On that scenario, the macro can be attached to a simple enum (with supported raw value): 
 
```swift
@SafelyDecodedEnum
enum OperationType: String {
    case credit = "CREDIT"
    case debit = "DEBIT"
}
```

 The macro `SafelyDecodedEnum` after macro expansion:
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
}

extension OperationType: Decodable {
}
```

 > [!Note] 
 >  When you need also `Encodalbe` conformance, simply add this conformance by yourself.
 >  Explicit `Decodable` declaration would not add an extesion with the conformance.
 
 
 In some cases the default "safe case" cannot be `unknown`,
 or the default "safe raw value" cannot be the implicit one.
 For those you can declare explicitly the safe `rawValue` and/or the `safeCase`:

```swift
@SafelyDecodedEnum(rawValue: .int(-999), safeCase: .general)
enum Order: Int, Decodable {
    case first = 1
    case second = 2
    case last = 3
}
```

And after expansion:

```swift
@SafelyDecodedEnum(rawValue: .int(-999), safeCase: .general)
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
}
```
