import Testing

@testable import IGTools

@Suite("LanguageHints Tests")
struct LanguageHintsTests {

    // MARK: - Russian word detection

    @Test("Recognizes common Russian particles and conjunctions")
    func russianParticles() {
        let words = ["так", "что", "как", "вот", "тут", "там", "где", "уже",
                     "ещё", "еще", "ведь", "лишь", "даже", "либо", "зато",
                     "или", "без", "при", "для", "под", "над", "про",
                     "хоть", "пусть", "чтоб", "если", "пока", "тоже", "тогда",
                     "хотя", "чтобы", "когда"]
        for word in words {
            #expect(LanguageHints.isLikelyRussian(word), "Expected '\(word)' to be recognized as Russian")
        }
    }

    @Test("Recognizes common Russian pronouns")
    func russianPronouns() {
        let words = ["это", "тот", "тем", "тех", "том", "той", "его",
                     "она", "они", "нас", "вас", "них", "нам", "вам",
                     "мне", "ему", "чем", "кто", "все", "всё", "сам",
                     "мой", "моя", "моё", "наш", "ваш", "свой",
                     "эти", "эту", "вся", "оба", "обе"]
        for word in words {
            #expect(LanguageHints.isLikelyRussian(word), "Expected '\(word)' to be recognized as Russian")
        }
    }

    @Test("Recognizes common Russian verbs")
    func russianVerbs() {
        let words = ["был", "дал", "ест", "мог", "жил", "шёл", "сел",
                     "быть", "дать", "есть", "мочь", "идти", "знал",
                     "стал", "взял", "жить", "знать", "будь", "надо"]
        for word in words {
            #expect(LanguageHints.isLikelyRussian(word), "Expected '\(word)' to be recognized as Russian")
        }
    }

    @Test("Recognizes common Russian nouns")
    func russianNouns() {
        let words = ["нет", "дом", "мир", "лес", "путь", "друг",
                     "день", "год", "час", "ночь", "сын", "бог",
                     "мать", "свет", "дело", "слово", "время", "место"]
        for word in words {
            #expect(LanguageHints.isLikelyRussian(word), "Expected '\(word)' to be recognized as Russian")
        }
    }

    @Test("Recognizes Russian words containing ж (semicolon on QWERTY)")
    func russianWordsWithZhe() {
        let words = ["можно", "нужно", "нужен", "важно", "важный",
                     "каждый", "между", "также", "тоже", "уже",
                     "нож", "муж", "ложь", "кожа", "лужа", "ужас",
                     "жить", "жизнь", "жена", "живой", "ждать",
                     "ближе", "ниже", "ложка", "дождь"]
        for word in words {
            #expect(LanguageHints.isLikelyRussian(word), "Expected '\(word)' to be recognized as Russian")
        }
    }

    @Test("Recognizes Russian ж-word prefixes in longer words")
    func russianZhePrefixMatch() {
        #expect(LanguageHints.isLikelyRussian("можешь"))   // мож prefix
        #expect(LanguageHints.isLikelyRussian("нужный"))   // нуж prefix
        #expect(LanguageHints.isLikelyRussian("кажется"))  // каж prefix
        #expect(LanguageHints.isLikelyRussian("жизненный")) // жиз prefix
        #expect(LanguageHints.isLikelyRussian("женщина"))  // жен prefix
    }

    @Test("Russian word matching is case-insensitive")
    func russianWordCaseInsensitive() {
        #expect(LanguageHints.isLikelyRussian("Так"))
        #expect(LanguageHints.isLikelyRussian("ЧТО"))
        #expect(LanguageHints.isLikelyRussian("Это"))
        #expect(LanguageHints.isLikelyRussian("МОЖНО"))
    }

    @Test("Recognizes Russian prefixes in longer words")
    func russianPrefixMatch() {
        #expect(LanguageHints.isLikelyRussian("чтобы"))
        #expect(LanguageHints.isLikelyRussian("прикол"))
        #expect(LanguageHints.isLikelyRussian("перенос"))
        #expect(LanguageHints.isLikelyRussian("подход"))
        #expect(LanguageHints.isLikelyRussian("начало"))
        #expect(LanguageHints.isLikelyRussian("разбор"))
        #expect(LanguageHints.isLikelyRussian("будущий"))
        #expect(LanguageHints.isLikelyRussian("другой"))
        #expect(LanguageHints.isLikelyRussian("только"))
        #expect(LanguageHints.isLikelyRussian("хороший"))
    }

    @Test("Does not match Latin text as Russian")
    func russianRejectsLatin() {
        #expect(!LanguageHints.isLikelyRussian("the"))
        #expect(!LanguageHints.isLikelyRussian("hello"))
        #expect(!LanguageHints.isLikelyRussian("xyz"))
    }

    @Test("Rejects short or empty strings for Russian")
    func russianRejectsShort() {
        #expect(!LanguageHints.isLikelyRussian("яя"))
        #expect(!LanguageHints.isLikelyRussian(""))
    }

    // MARK: - English word detection

    @Test("Recognizes high-frequency 3-letter English words")
    func english3LetterWords() {
        let words = ["the", "and", "for", "are", "but", "not", "you",
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
                     "tap", "tax", "tea", "tip", "via", "wet"]
        for word in words {
            #expect(LanguageHints.isLikelyEnglish(word), "Expected '\(word)' to be recognized as English")
        }
    }

    @Test("Recognizes high-frequency 4-letter English words")
    func english4LetterWords() {
        let words = ["been", "come", "each", "from", "good", "have",
                     "help", "here", "just", "like", "long", "make",
                     "many", "more", "much", "must", "name", "only",
                     "over", "such", "take", "than", "them", "then",
                     "this", "time", "very", "when", "will", "with",
                     "work", "year", "also", "back", "call", "does",
                     "done", "down", "even", "find", "give", "gone",
                     "into", "keep", "know", "last", "left", "life",
                     "look", "made", "need", "next", "part", "some",
                     "that", "what", "your",
                     "able", "area", "away", "best", "body", "book",
                     "both", "case", "city", "cost", "deal", "deep",
                     "door", "fact", "face", "fall", "fast", "feel",
                     "five", "food", "form", "four", "free", "full",
                     "game", "girl", "half", "hand", "hard", "head",
                     "high", "hold", "home", "hope", "hour", "idea",
                     "kind", "land", "late", "lead", "less", "line",
                     "live", "lose", "lost", "love", "main", "mean",
                     "mind", "miss", "most", "move", "near", "nice",
                     "once", "open", "page", "paid", "past", "plan",
                     "play", "read", "real", "rest", "rich", "road",
                     "role", "room", "rule", "safe", "said", "same",
                     "save", "seen", "self", "send", "show", "shut",
                     "side", "sign", "site", "size", "slow", "soft",
                     "soon", "sort", "star", "stay", "step", "stop",
                     "sure", "talk", "team", "tell", "term", "test",
                     "they", "told", "took", "town", "tree", "true",
                     "turn", "type", "unit", "upon", "used", "view",
                     "wait", "walk", "wall", "want", "warm", "wash",
                     "wear", "week", "well", "went", "were", "west",
                     "wide", "wife", "wild", "wind", "wish", "wood",
                     "word", "zero"]
        for word in words {
            #expect(LanguageHints.isLikelyEnglish(word), "Expected '\(word)' to be recognized as English")
        }
    }

    @Test("Recognizes common 5-6 letter English words")
    func english5to6LetterWords() {
        let words = ["about", "after", "again", "being", "black",
                     "bring", "build", "cause", "check", "child",
                     "class", "clear", "close", "could", "cover",
                     "death", "drive", "early", "every", "extra",
                     "field", "final", "first", "force", "found",
                     "front", "going", "great", "green", "group",
                     "happy", "heart", "house", "human", "image",
                     "issue", "known", "large", "later", "learn",
                     "leave", "level", "light", "local", "money",
                     "month", "music", "never", "night", "north",
                     "offer", "often", "order", "other", "paper",
                     "party", "peace", "phone", "piece", "place",
                     "point", "power", "press", "price", "prove",
                     "quick", "quiet", "quite", "range", "reach",
                     "ready", "right", "river", "round", "scene",
                     "sense", "serve", "seven", "shall", "shape",
                     "share", "short", "since", "sleep", "small",
                     "smile", "sound", "south", "space", "speak",
                     "spend", "staff", "stage", "stand", "start",
                     "state", "still", "stone", "store", "story",
                     "study", "style", "table", "thank", "their",
                     "there", "these", "thing", "think", "those",
                     "three", "today", "total", "touch", "trade",
                     "train", "truth", "under", "until", "using",
                     "usual", "value", "video", "visit", "voice",
                     "watch", "water", "where", "which", "while",
                     "white", "whole", "woman", "world", "would",
                     "write", "wrong", "young"]
        for word in words {
            #expect(LanguageHints.isLikelyEnglish(word), "Expected '\(word)' to be recognized as English")
        }
    }

    @Test("English word matching is case-insensitive")
    func englishWordCaseInsensitive() {
        #expect(LanguageHints.isLikelyEnglish("The"))
        #expect(LanguageHints.isLikelyEnglish("AND"))
        #expect(LanguageHints.isLikelyEnglish("For"))
        #expect(LanguageHints.isLikelyEnglish("WHY"))
    }

    @Test("Recognizes English prefixes in longer words")
    func englishPrefixMatch() {
        #expect(LanguageHints.isLikelyEnglish("theory"))
        #expect(LanguageHints.isLikelyEnglish("program"))
        #expect(LanguageHints.isLikelyEnglish("control"))
        #expect(LanguageHints.isLikelyEnglish("without"))
        #expect(LanguageHints.isLikelyEnglish("string"))
        #expect(LanguageHints.isLikelyEnglish("about"))
        #expect(LanguageHints.isLikelyEnglish("before"))
        #expect(LanguageHints.isLikelyEnglish("because"))
        #expect(LanguageHints.isLikelyEnglish("knowledge"))
        #expect(LanguageHints.isLikelyEnglish("otherwise"))
        #expect(LanguageHints.isLikelyEnglish("shoulder"))
        #expect(LanguageHints.isLikelyEnglish("whistle"))
    }

    @Test("Does not match Cyrillic text as English")
    func englishRejectsCyrillic() {
        #expect(!LanguageHints.isLikelyEnglish("так"))
        #expect(!LanguageHints.isLikelyEnglish("что"))
        #expect(!LanguageHints.isLikelyEnglish("для"))
    }

    @Test("Rejects short or empty strings for English")
    func englishRejectsShort() {
        #expect(!LanguageHints.isLikelyEnglish("zz"))
        #expect(!LanguageHints.isLikelyEnglish(""))
    }

    // MARK: - Cross-layout mapping scenarios

    @Test("nfr on EN keyboard maps to так which is recognized as Russian")
    func originalProblemScenario() {
        let mapped = LayoutMap.mapEnToRu("nfr")
        #expect(mapped == "так")
        #expect(LanguageHints.isLikelyRussian("так"))
    }

    @Test("xnj on EN keyboard maps to что which is recognized as Russian")
    func whatScenario() {
        let mapped = LayoutMap.mapEnToRu("xnj")
        #expect(mapped == "что")
        #expect(LanguageHints.isLikelyRussian("что"))
    }

    @Test("црщ on RU keyboard maps to who which is recognized as English")
    func whoScenario() {
        let mapped = LayoutMap.mapRuToEn("црщ")
        #expect(mapped == "who")
        #expect(LanguageHints.isLikelyEnglish("who"))
    }

    @Test("црн on RU keyboard maps to why which is recognized as English")
    func whyScenario() {
        let mapped = LayoutMap.mapRuToEn("црн")
        #expect(mapped == "why")
        #expect(LanguageHints.isLikelyEnglish("why"))
    }

    @Test("vj;yj on EN keyboard maps to можно which is recognized as Russian")
    func mozhnoScenario() {
        let mapped = LayoutMap.mapEnToRu("vj;yj")
        #expect(mapped == "можно")
        #expect(LanguageHints.isLikelyRussian("можно"))
    }

    @Test("ye;yj on EN keyboard maps to нужно which is recognized as Russian")
    func nuzhnoScenario() {
        let mapped = LayoutMap.mapEnToRu("ye;yj")
        #expect(mapped == "нужно")
        #expect(LanguageHints.isLikelyRussian("нужно"))
    }

    // MARK: - Prefix minimum length

    @Test("Prefix matching requires at least 3 characters")
    func prefixMinLength() {
        #expect(!LanguageHints.isLikelyRussian("та"))
        #expect(!LanguageHints.isLikelyEnglish("th"))
    }
}
