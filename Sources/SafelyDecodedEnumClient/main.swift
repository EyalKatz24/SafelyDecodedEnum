import SafelyDecodedEnum

@SafelyDecodedEnum(rawValue: .int(-3), safeCase: .general)
enum OperationType: Int {
    case credit
    case debit
}
