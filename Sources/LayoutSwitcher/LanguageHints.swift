import Foundation

/// Supplementary language detection using curated word and prefix tables.
/// Used as a fallback when NSSpellChecker fails to recognize common short words.
enum LanguageHints {

    // MARK: - Russian common words (Cyrillic, lowercased)
    // Particles, pronouns, prepositions, conjunctions, common short verbs/nouns
    // that NSSpellChecker sometimes misses (3-6 chars)

    static let russianWords: Set<String> = [
        // Particles & conjunctions
        "так", "что", "как", "вот", "тут", "там", "где", "уже",
        "ещё", "еще", "ведь", "лишь", "даже", "либо", "зато",
        "или", "без", "при", "для", "под", "над", "про",
        "хоть", "пусть", "чтоб", "если", "пока", "тоже", "тогда",
        // Pronouns
        "это", "тот", "тем", "тех", "том", "той", "его",
        "она", "они", "нас", "вас", "них", "нам", "вам",
        "мне", "ему", "чем", "кто", "все", "всё", "сам",
        "сама", "само", "свой", "свою", "наш", "ваш",
        "мой", "моя", "моё", "мою",
        // Common short verbs & words
        "был", "дал", "ест", "мог", "нет", "дом",
        "раз", "два", "три", "день", "год", "час",
        // Common nouns
        "мир", "лес", "ход", "вид", "ряд", "суд",
        "рот", "сон", "путь", "друг",
    ]

    // MARK: - English common words (Latin, lowercased)

    static let englishWords: Set<String> = [
        // Articles, pronouns, prepositions
        "the", "and", "for", "are", "but", "not", "you",
        "all", "can", "had", "her", "was", "one", "our",
        "out", "has", "his", "how", "its", "may", "new",
        "now", "old", "see", "way", "who", "did", "get",
        "let", "say", "she", "too", "use",
        // Common short verbs/words
        "been", "come", "each", "from", "good", "have",
        "help", "here", "just", "like", "long", "make",
        "many", "more", "much", "must", "name", "only",
        "over", "such", "take", "than", "them", "then",
        "this", "time", "very", "when", "will", "with",
        "work", "year", "also", "back", "call",
        "does", "done", "down", "even", "find",
        "give", "goes", "gone", "into", "keep", "know",
        "last", "left", "life", "look", "made", "need",
        "next", "part", "some", "that", "what", "your",
    ]

    // MARK: - Russian trigram prefixes (Cyrillic)
    // Word-initial trigrams that strongly indicate Russian text

    static let russianPrefixes: Set<String> = [
        "что", "как", "это", "при", "все", "про",
        "пер", "пре", "под", "над", "без", "раз",
        "рас", "нач", "кон", "отв", "дел", "ска",
        "ста", "мож", "кот", "пок", "нак",
    ]

    // MARK: - English trigram prefixes (Latin)
    // Word-initial trigrams that strongly indicate English text

    static let englishPrefixes: Set<String> = [
        "the", "and", "for", "tha", "wit", "was",
        "not", "are", "but", "hav", "com", "whe",
        "thi", "wor", "pro", "pre", "con", "str",
        "ove", "out", "und", "dis", "who",
    ]

    // MARK: - Detection

    /// Returns true if the word (in Cyrillic) is likely Russian,
    /// based on exact word match or prefix match.
    static func isLikelyRussian(_ word: String) -> Bool {
        let lowered = word.lowercased()
        if russianWords.contains(lowered) { return true }
        if lowered.count >= 3 {
            let prefix = String(lowered.prefix(3))
            return russianPrefixes.contains(prefix)
        }
        return false
    }

    /// Returns true if the word (in Latin) is likely English,
    /// based on exact word match or prefix match.
    static func isLikelyEnglish(_ word: String) -> Bool {
        let lowered = word.lowercased()
        if englishWords.contains(lowered) { return true }
        if lowered.count >= 3 {
            let prefix = String(lowered.prefix(3))
            return englishPrefixes.contains(prefix)
        }
        return false
    }
}
