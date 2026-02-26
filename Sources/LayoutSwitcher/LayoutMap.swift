import Foundation

/// Physical key position mapping between QWERTY (EN) and ЙЦУКЕН (RU) keyboard layouts.
enum LayoutMap {

    // MARK: - EN → RU (lowercase)

    static let enToRu: [Character: Character] = [
        "q": "й", "w": "ц", "e": "у", "r": "к", "t": "е",
        "y": "н", "u": "г", "i": "ш", "o": "щ", "p": "з",
        "[": "х", "]": "ъ",
        "a": "ф", "s": "ы", "d": "в", "f": "а", "g": "п",
        "h": "р", "j": "о", "k": "л", "l": "д", ";": "ж", "'": "э",
        "z": "я", "x": "ч", "c": "с", "v": "м", "b": "и",
        "n": "т", "m": "ь", ",": "б", ".": "ю",
        "`": "ё",
    ]

    // MARK: - EN → RU (uppercase / shifted)

    static let enToRuUpper: [Character: Character] = [
        "Q": "Й", "W": "Ц", "E": "У", "R": "К", "T": "Е",
        "Y": "Н", "U": "Г", "I": "Ш", "O": "Щ", "P": "З",
        "{": "Х", "}": "Ъ",
        "A": "Ф", "S": "Ы", "D": "В", "F": "А", "G": "П",
        "H": "Р", "J": "О", "K": "Л", "L": "Д", ":": "Ж", "\"": "Э",
        "Z": "Я", "X": "Ч", "C": "С", "V": "М", "B": "И",
        "N": "Т", "M": "Ь", "<": "Б", ">": "Ю",
        "~": "Ё",
    ]

    // MARK: - RU → EN (computed reverses)

    static let ruToEn: [Character: Character] = {
        var map: [Character: Character] = [:]
        for (en, ru) in enToRu { map[ru] = en }
        return map
    }()

    static let ruToEnUpper: [Character: Character] = {
        var map: [Character: Character] = [:]
        for (en, ru) in enToRuUpper { map[ru] = en }
        return map
    }()

    // MARK: - Word mapping

    /// Maps a word character-by-character from English layout to Russian layout.
    /// Returns nil if any character cannot be mapped.
    static func mapEnToRu(_ word: String) -> String? {
        var result = ""
        for char in word {
            if let mapped = enToRu[char] ?? enToRuUpper[char] {
                result.append(mapped)
            } else {
                return nil
            }
        }
        return result
    }

    /// Maps a word character-by-character from Russian layout to English layout.
    /// Returns nil if any character cannot be mapped.
    static func mapRuToEn(_ word: String) -> String? {
        var result = ""
        for char in word {
            if let mapped = ruToEn[char] ?? ruToEnUpper[char] {
                result.append(mapped)
            } else {
                return nil
            }
        }
        return result
    }
}
