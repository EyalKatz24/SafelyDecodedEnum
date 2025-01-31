import SafelyDecodedEnum

@SafelyDecodedEnum(rawValue: .int(-3), safeCase: .general)
enum OperationType: Int, Decodable {
    case credit
    case debit
}
