import Foundation

public struct TelexComposer: Sendable {
    private enum Tone: Int {
        case none = 0
        case acute
        case grave
        case hook
        case tilde
        case dot
    }

    private struct Letter {
        var base: Character
        var tone: Tone
        var uppercase: Bool
    }

    public init() {}

    public func compose(_ raw: String) -> String {
        var output = ""

        for input in raw {
            let lower = Character(input.lowercased())

            switch lower {
            case "s", "f", "r", "x", "j":
                let tone = tone(for: lower)
                if currentTone(in: output) == tone {
                    output = removingTone(from: output)
                    output.append(contentsOf: String(repeating: String(input), count: 2))
                } else if hasVowel(in: output) {
                    output = applyingTone(tone, to: output)
                } else {
                    output.append(input)
                }

            case "z":
                let stripped = removingAllMarks(from: output)
                if stripped == output {
                    output.append(input)
                } else {
                    output = stripped
                }

            case "d":
                if let last = output.last, lowercased(last) == "d" {
                    output.removeLast()
                    output.append(last.isUppercase ? "Đ" : "đ")
                } else if let last = output.last, lowercased(last) == "đ" {
                    output.removeLast()
                    output.append(last.isUppercase ? "D" : "d")
                    output.append(input)
                } else {
                    output.append(input)
                }

            case "a", "e", "o":
                if transformRepeatedVowel(lower, input: input, output: &output) {
                    continue
                }
                output.append(input)

            case "w":
                if !applyW(to: &output) {
                    output.append(input)
                }

            default:
                output.append(input)
            }
        }

        return output.precomposedStringWithCanonicalMapping
    }

    private func transformRepeatedVowel(
        _ trigger: Character,
        input: Character,
        output: inout String
    ) -> Bool {
        guard let last = output.last else { return false }
        let decoded = decode(last)
        let expected: Character
        switch trigger {
        case "a": expected = "a"
        case "e": expected = "e"
        default: expected = "o"
        }
        guard decoded.base == expected else { return false }

        let replacementBase: Character
        switch trigger {
        case "a": replacementBase = "â"
        case "e": replacementBase = "ê"
        default: replacementBase = "ô"
        }

        output.removeLast()
        output.append(encode(Letter(
            base: replacementBase,
            tone: decoded.tone,
            uppercase: decoded.uppercase
        )))
        return true
    }

    private func applyW(to output: inout String) -> Bool {
        var chars = Array(output)
        guard !chars.isEmpty else { return false }

        let vowelIndices = chars.indices.filter { isVowel(chars[$0]) }
        guard let lastIndex = vowelIndices.last else { return false }

        if vowelIndices.count >= 2 {
            let previousIndex = vowelIndices[vowelIndices.count - 2]
            let previous = decode(chars[previousIndex])
            let last = decode(chars[lastIndex])
            if previous.base == "u", last.base == "o" {
                chars[previousIndex] = encode(Letter(
                    base: "ư", tone: previous.tone, uppercase: previous.uppercase
                ))
                chars[lastIndex] = encode(Letter(
                    base: "ơ", tone: last.tone, uppercase: last.uppercase
                ))
                output = String(chars)
                return true
            }
        }

        let letter = decode(chars[lastIndex])
        let replacement: Character?
        switch letter.base {
        case "a": replacement = "ă"
        case "o": replacement = "ơ"
        case "u": replacement = "ư"
        default: replacement = nil
        }
        guard let replacement else { return false }

        chars[lastIndex] = encode(Letter(
            base: replacement,
            tone: letter.tone,
            uppercase: letter.uppercase
        ))
        output = String(chars)
        return true
    }

    private func applyingTone(_ tone: Tone, to word: String) -> String {
        var chars = Array(word)
        let indices = toneCandidateIndices(in: chars)
        guard !indices.isEmpty else { return word }
        let selected = selectToneIndex(indices: indices, chars: chars)
        var letter = decode(chars[selected])
        letter.tone = tone
        chars[selected] = encode(letter)
        return String(chars)
    }

    private func toneCandidateIndices(in chars: [Character]) -> [Int] {
        var result = chars.indices.filter { isVowel(chars[$0]) }
        if result.count > 1,
           result.first == 1,
           lowercased(chars[0]) == "q",
           decode(chars[1]).base == "u" {
            result.removeFirst()
        }
        if result.count > 1,
           result.first == 1,
           lowercased(chars[0]) == "g",
           decode(chars[1]).base == "i" {
            result.removeFirst()
        }
        return result
    }

    private func selectToneIndex(indices: [Int], chars: [Character]) -> Int {
        if let marked = indices.last(where: {
            ["ă", "â", "ê", "ô", "ơ"].contains(decode(chars[$0]).base)
        }) {
            return marked
        }

        if indices.count >= 3 {
            return indices[indices.count - 2]
        }
        if indices.count == 2 {
            let first = decode(chars[indices[0]]).base
            let second = decode(chars[indices[1]]).base
            if ["iê", "yê", "uô", "ươ"].contains(String([first, second])) {
                return indices[1]
            }
            let hasCoda = indices[1] < chars.count - 1
            return hasCoda ? indices[1] : indices[0]
        }
        return indices[0]
    }

    private func hasVowel(in value: String) -> Bool {
        value.contains(where: isVowel)
    }

    private func isVowel(_ character: Character) -> Bool {
        "aăâeêioôơuưy".contains(decode(character).base)
    }

    private func currentTone(in value: String) -> Tone {
        value.lazy.map(decode).first(where: { $0.tone != .none })?.tone ?? .none
    }

    private func removingTone(from value: String) -> String {
        String(value.map {
            var letter = decode($0)
            letter.tone = .none
            return encode(letter)
        })
    }

    private func removingAllMarks(from value: String) -> String {
        String(value.map {
            var letter = decode($0)
            letter.tone = .none
            switch letter.base {
            case "ă", "â": letter.base = "a"
            case "ê": letter.base = "e"
            case "ô", "ơ": letter.base = "o"
            case "ư": letter.base = "u"
            case "đ": letter.base = "d"
            default: break
            }
            return encode(letter)
        })
    }

    private func tone(for trigger: Character) -> Tone {
        switch trigger {
        case "s": return .acute
        case "f": return .grave
        case "r": return .hook
        case "x": return .tilde
        case "j": return .dot
        default: return .none
        }
    }

    private func lowercased(_ character: Character) -> Character {
        Character(character.lowercased())
    }

    private func decode(_ character: Character) -> Letter {
        let uppercase = character.isUppercase
        let lower = Character(character.lowercased())
        if let entry = Self.reverseToneTable[lower] {
            return Letter(base: entry.0, tone: entry.1, uppercase: uppercase)
        }
        return Letter(base: lower, tone: .none, uppercase: uppercase)
    }

    private func encode(_ letter: Letter) -> Character {
        let lower = Self.toneTable[letter.base]?[letter.tone.rawValue] ?? letter.base
        return letter.uppercase ? Character(lower.uppercased()) : lower
    }

    private static let toneTable: [Character: [Character]] = [
        "a": ["a", "á", "à", "ả", "ã", "ạ"],
        "ă": ["ă", "ắ", "ằ", "ẳ", "ẵ", "ặ"],
        "â": ["â", "ấ", "ầ", "ẩ", "ẫ", "ậ"],
        "e": ["e", "é", "è", "ẻ", "ẽ", "ẹ"],
        "ê": ["ê", "ế", "ề", "ể", "ễ", "ệ"],
        "i": ["i", "í", "ì", "ỉ", "ĩ", "ị"],
        "o": ["o", "ó", "ò", "ỏ", "õ", "ọ"],
        "ô": ["ô", "ố", "ồ", "ổ", "ỗ", "ộ"],
        "ơ": ["ơ", "ớ", "ờ", "ở", "ỡ", "ợ"],
        "u": ["u", "ú", "ù", "ủ", "ũ", "ụ"],
        "ư": ["ư", "ứ", "ừ", "ử", "ữ", "ự"],
        "y": ["y", "ý", "ỳ", "ỷ", "ỹ", "ỵ"],
        "đ": ["đ", "đ", "đ", "đ", "đ", "đ"]
    ]

    private static let reverseToneTable: [Character: (Character, Tone)] = {
        var result: [Character: (Character, Tone)] = [:]
        for (base, forms) in toneTable {
            for (index, form) in forms.enumerated() {
                result[form] = (base, Tone(rawValue: index) ?? .none)
            }
        }
        return result
    }()
}

