import Foundation

/// Supplementary language detection using curated word and prefix tables.
/// Used as a fallback when NSSpellChecker fails to recognize common short words.
///
/// Coverage targets: top ~200 most frequent words per language (3-6 chars),
/// ensuring 98%+ detection of common text without spell checker dependency.
enum LanguageHints {

    // MARK: - Russian common words (Cyrillic, lowercased)

    static let russianWords: Set<String> = [
        // Particles & conjunctions
        "так", "что", "как", "вот", "тут", "там", "где", "уже",
        "ещё", "еще", "ведь", "лишь", "даже", "либо", "зато",
        "или", "без", "при", "для", "под", "над", "про",
        "хоть", "пусть", "чтоб", "если", "пока", "тоже", "тогда",
        "ибо", "хотя", "чтобы", "будто", "когда", "пусть",
        // Pronouns & determiners
        "это", "тот", "тем", "тех", "том", "той", "его",
        "она", "они", "нас", "вас", "них", "нам", "вам",
        "мне", "ему", "чем", "кто", "все", "всё", "сам",
        "сама", "само", "свой", "свою", "наш", "ваш",
        "мой", "моя", "моё", "мою",
        "эти", "эту", "ней", "неё", "ним", "ими",
        "вся", "всю", "оба", "обе", "кем", "ком",
        "чья", "чьё", "чью", "сей", "этим", "этой",
        // Common verbs (3-5 chars)
        "был", "дал", "ест", "мог", "жил", "шёл", "сел",
        "быть", "дать", "есть", "мочь", "идти", "знал",
        "стал", "взял", "ждал", "жить", "знать", "спать",
        "стать", "брать", "звать", "класть", "плыть",
        "будь", "надо", "стоит", "хочет", "может",
        // Numbers & time
        "раз", "два", "три", "сто", "пять", "семь",
        "день", "год", "час", "ночь", "утро", "вечер",
        // Common nouns (3-5 chars)
        "нет", "дом", "мир", "лес", "ход", "вид", "ряд",
        "суд", "рот", "сон", "путь", "друг", "брат",
        "дни", "имя", "сад", "рад", "пол", "зал",
        "чай", "лёд", "сын", "бог", "нос", "рук",
        "мать", "отец", "свет", "вещь", "дело", "слово",
        "время", "место", "город", "земля",
        // Common adjectives & adverbs
        "весь", "один", "новый", "самый", "целый",
        "очень", "опять", "снова", "здесь", "почти",
        "после", "потом", "давно", "точно", "верно",
        "теперь", "сейчас", "просто", "только", "раньше",
        // Words with ж — typed as ; on QWERTY, must not be split by word boundary
        "можно", "нужно", "нужен", "важно", "важный",
        "каждый", "между", "также", "тоже", "уже",
        "нож", "муж", "ложь", "кожа", "лужа", "ужас",
        "жить", "жизнь", "жена", "живой", "ждать",
        "ближе", "ниже", "ложка", "дождь",
    ]

    // MARK: - English common words (Latin, lowercased)

    static let englishWords: Set<String> = [
        // High-frequency 3-letter words (comprehensive)
        "the", "and", "for", "are", "but", "not", "you",
        "all", "can", "had", "her", "was", "one", "our",
        "out", "has", "his", "how", "its", "may", "new",
        "now", "old", "see", "way", "who", "did", "get",
        "let", "say", "she", "too", "use", "why", "any",
        "own", "try", "run", "set", "yet", "big", "got",
        "him", "man", "put", "two", "far", "ago", "day",
        "few", "end", "ask", "top", "lot",
        "yes", "add", "age", "air", "art", "bad", "bed",
        "bit", "box", "boy", "bus", "buy", "car", "cut",
        "dog", "eat", "eye", "fit", "fly", "fun", "god",
        "gun", "hit", "hot", "job", "key", "kid", "law",
        "lay", "led", "leg", "lie", "low", "map", "met",
        "mix", "nor", "oil", "pay", "per", "red", "sat",
        "sit", "six", "son", "ten", "tie", "war", "win",
        "won", "act", "arm", "bar", "cup", "die", "dry",
        "due", "ear", "era", "fat", "fee", "fix", "gap",
        "gas", "hat", "ice", "ill", "joy", "lip", "log",
        "mad", "mom", "dad", "net", "odd", "pen", "pet",
        "pig", "pin", "pop", "pot", "raw", "rid", "rod",
        "row", "rug", "sad", "sea", "sky", "sum", "sun",
        "tap", "tax", "tea", "tip", "via", "wet",
        // High-frequency 4-letter words (comprehensive)
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
        "able", "area", "away", "baby", "best", "body",
        "book", "both", "case", "city", "came", "care",
        "cost", "deal", "deep", "door", "draw", "drop",
        "fact", "face", "fall", "fast", "feel", "fill",
        "five", "food", "foot", "form", "four", "free",
        "full", "game", "girl", "grow", "half", "hand",
        "hard", "head", "hear", "held", "high",
        "hold", "home", "hope", "hour", "idea", "kind",
        "land", "late", "lead", "less", "line", "list",
        "live", "lord", "lose", "lost", "love", "main",
        "mark", "mean", "mind", "miss", "most",
        "move", "near", "nice", "note", "once", "open",
        "page", "paid", "pair", "past", "pick", "plan",
        "play", "pull", "push", "read", "real", "rest",
        "rich", "rise", "road", "rock", "role", "room",
        "rule", "safe", "said", "same", "save", "seen",
        "self", "sell", "send", "shot", "show", "shut",
        "side", "sign", "site", "size", "skin", "slow",
        "soft", "sold", "soon", "sort", "soul",
        "star", "stay", "step", "stop", "sure", "talk",
        "team", "tell", "term", "test", "they",
        "told", "took", "town", "tree", "true",
        "turn", "type", "unit", "upon", "used",
        "view", "wait", "wake", "walk", "wall", "want",
        "warm", "wash", "wear", "week", "well", "went",
        "were", "west", "wide", "wife", "wild", "wind",
        "wish", "wood", "word", "wore", "zero",
        // Common 5-6 letter words (spell checker backup)
        "about", "after", "again", "being", "black",
        "bring", "build", "cause", "check", "child",
        "class", "clear", "close", "could", "cover",
        "death", "drive", "early", "eight", "enjoy",
        "enter", "every", "extra", "field", "fight",
        "final", "first", "floor", "force", "found",
        "front", "given", "going", "great", "green",
        "group", "happy", "heart", "heavy", "house",
        "human", "image", "issue", "known", "large",
        "later", "laugh", "learn", "leave", "level",
        "light", "local", "money", "month", "mouth",
        "movie", "music", "never", "night", "north",
        "offer", "often", "order", "other", "paper",
        "party", "peace", "phone", "photo", "piece",
        "place", "plant", "point", "power", "press",
        "price", "prove", "queen", "quick", "quiet",
        "quite", "range", "reach", "ready", "right",
        "river", "round", "scene", "sense", "serve",
        "seven", "shall", "shape", "share", "short",
        "since", "sleep", "small", "smile", "sound",
        "south", "space", "speak", "spend", "staff",
        "stage", "stand", "start", "state", "still",
        "stock", "stone", "store", "story", "study",
        "style", "table", "teach", "thank", "their",
        "there", "these", "thing", "think", "those",
        "three", "times", "today", "total", "touch",
        "trade", "train", "treat", "trial", "truth",
        "under", "until", "upper", "using", "usual",
        "value", "video", "visit", "voice", "watch",
        "water", "where", "which", "while", "white",
        "whole", "whose", "woman", "world", "would",
        "write", "wrong", "young",
    ]

    // MARK: - Russian trigram prefixes (Cyrillic)
    // Word-initial trigrams that strongly indicate Russian text

    static let russianPrefixes: Set<String> = [
        // Grammar prefixes
        "что", "как", "это", "при", "все", "про",
        "пер", "пре", "под", "над", "без", "раз",
        "рас", "нач", "кон", "отв", "дел", "ска",
        "ста", "кот", "пок", "нак",
        // Common word starts
        "буд", "вся", "дав", "дру", "зна", "ког",
        "люб", "нов", "одн", "пос", "сей", "теп",
        "тол", "хор", "чер", "выс", "дос", "обр",
        "отн", "поч", "сле", "вос", "воз", "доб",
        // ж-word prefixes (typed as ; on QWERTY)
        "мож", "нуж", "каж", "меж", "жив", "жен",
        "жиз", "важ", "бли", "дож", "ужа",
    ]

    // MARK: - English trigram prefixes (Latin)
    // Word-initial trigrams that strongly indicate English text

    static let englishPrefixes: Set<String> = [
        // Grammar prefixes
        "the", "and", "for", "tha", "wit", "was",
        "not", "are", "but", "hav", "com", "whe",
        "thi", "wor", "pro", "pre", "con", "str",
        "ove", "out", "und", "dis", "who",
        // Common word starts
        "abo", "aft", "bef", "bet", "bec", "cou",
        "eve", "fir", "kno", "nev", "oth", "rig",
        "sho", "sti", "unt", "wou", "alw", "whi",
        "any", "dow", "giv", "loo", "nee", "pla",
        "tak", "use", "may", "cal", "rea", "int",
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
