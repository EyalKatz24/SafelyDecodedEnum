# SafelyDecodedEnum — for AI assistants

Paste this into **project rules**, **Cursor rules**, **Copilot / ChatGPT custom instructions**, **Claude Code** `CLAUDE.md`, **Kiro** project context, **Xcode**-adjacent docs, or your app repo’s **`AGENTS.md`**, so assistants use the API correctly.

---

## Package

- **Module:** `import SafelyDecodedEnum`
- **API:** `@SafelyDecodedEnum` macro, `SafeCase`, `RawValueType` (see package source and README).

---

## Valid usage

- Attach **`@SafelyDecodedEnum` only to `enum` declarations** (not structs, classes, or actors).
- The enum must be **`RawRepresentable` with raw type `String` or `Int`** only. The macro reads the **first** type in the inheritance clause as that raw type, so **`String` or `Int` must appear first** (e.g. `enum Foo: String, Codable` is fine; putting another protocol first can make expansion fail).
- Optional macro arguments:
  - **`safeCase`:** one of **`.unknown`**, **`.undefined`**, **`.none`**, **`.general`** (names the synthesized fallback `case`).
  - **`rawValue`:** **`.string("...")`** on **`String`** enums, or **`.int(...)`** on **`Int`** enums. The **kind must match** the enum’s raw type (`.string` only with `String`, `.int` only with `Int`).
- If the enum **already** declares **`Decodable`** or **`Codable`**, the macro **does not** add a second `extension … : Decodable`. If it does **not**, the macro adds **`extension … : Decodable { }`**.
- The macro synthesizes: the **safe fallback `case`**, **`public init(from decoder: Decoder) throws`**, and **`static var allDefinedCases`**.

---

## Invalid usage (do not suggest or generate)

| Situation | Why |
|-----------|-----|
| Macro on **anything except an `enum`** | Error: macro only attaches to enums. |
| Raw type is **not** `String` or `Int` (e.g. `Int8`, `UInt`, `Double`) | Error: valid raw types are `String` and `Int`. |
| **`rawValue: .int(...)`** on a **`String`** enum, or **`.string(...)`** on an **`Int`** enum | Error: `rawValue` must match the enum’s raw type. |
| **Custom `init(from decoder: Decoder) throws`** on the **same** enum for decoding | **Do not** combine with this macro; pick manual decoding **or** the macro, not both. |
| Assuming **`allDefinedCases`** lists **every** value after decode | Wrong: unknown payloads decode to the **synthesized safe case**, which is **excluded** from `allDefinedCases`. |

---

## Do

- Treat the synthesized safe case as a **normal `case`** on the enum: include it in **exhaustive `switch`** logic when branching on all possibilities.
- Use **`allDefinedCases`** when you need **only user-declared** cases (e.g. labels, migrations, “known” options). Use the **full enum** (including the safe case) when behavior depends on **decoded** data.
- Pass **`rawValue`** when the default string (`UNKNOWN`-style from the safe case name) or default int (`-1`) is wrong for your API.
- Add **`import SafelyDecodedEnum`** in files that use the macro.

---

## Don’t

- Don’t attach the macro to **non-enums** or to enums whose raw type is not **`String`** / **`Int`**.
- Don’t **duplicate** decoding: no custom **`init(from:)`** for this enum if you use **`@SafelyDecodedEnum`** for decoding.
- Don’t use **`allDefinedCases`** as if it were **`CaseIterable.allCases`** for “everything the enum can be at runtime” after JSON; **unknown JSON** maps to the **safe case**, which is **not** in `allDefinedCases`.
- Don’t mismatch **`rawValue`** (`.string` vs `.int`) with the enum’s raw type.

---

## Default raw values for the safe case (when `rawValue` is omitted)

- **`String`:** the safe case’s string raw defaults to the **`safeCase` name in uppercase** (e.g. `.undefined` -> `"UNDEFINED"`), unless **`rawValue: .string(...)`** is set.
- **`Int`:** the safe case’s int raw defaults to **`-1`** unless **`rawValue: .int(...)`** is set.

---

## Macro errors (exact messages)

Assistants should recognize these and fix usage accordingly:

1. **`SafelyDecodedEnum` macro can only be attached to enums**
2. **`SafelyDecodedEnum` valid rawValues are `String` and `Int`**
3. **The `rawValue` argument doesn't match the enum `RawRepresentable` conformance type**

---

For examples and installation, see the package **README**.
