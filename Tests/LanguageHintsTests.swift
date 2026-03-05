import Testing

@testable import IGTools

@Suite("LanguageHints Tests")
struct LanguageHintsTests {

    // MARK: - Russian word detection

    @Test("Recognizes common Russian words")
    func russianWordExactMatch() {
        #expect(LanguageHints.isLikelyRussian("так"))
        #expect(LanguageHints.isLikelyRussian("что"))
        #expect(LanguageHints.isLikelyRussian("это"))
        #expect(LanguageHints.isLikelyRussian("вот"))
        #expect(LanguageHints.isLikelyRussian("где"))
        #expect(LanguageHints.isLikelyRussian("нет"))
        #expect(LanguageHints.isLikelyRussian("мне"))
        #expect(LanguageHints.isLikelyRussian("все"))
        #expect(LanguageHints.isLikelyRussian("для"))
    }

    @Test("Russian word matching is case-insensitive")
    func russianWordCaseInsensitive() {
        #expect(LanguageHints.isLikelyRussian("Так"))
        #expect(LanguageHints.isLikelyRussian("ЧТО"))
        #expect(LanguageHints.isLikelyRussian("Это"))
    }

    @Test("Recognizes Russian prefixes in longer words")
    func russianPrefixMatch() {
        #expect(LanguageHints.isLikelyRussian("чтобы"))
        #expect(LanguageHints.isLikelyRussian("прикол"))
        #expect(LanguageHints.isLikelyRussian("перенос"))
        #expect(LanguageHints.isLikelyRussian("подход"))
        #expect(LanguageHints.isLikelyRussian("начало"))
        #expect(LanguageHints.isLikelyRussian("разбор"))
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

    @Test("Recognizes common English words")
    func englishWordExactMatch() {
        #expect(LanguageHints.isLikelyEnglish("the"))
        #expect(LanguageHints.isLikelyEnglish("and"))
        #expect(LanguageHints.isLikelyEnglish("for"))
        #expect(LanguageHints.isLikelyEnglish("but"))
        #expect(LanguageHints.isLikelyEnglish("not"))
        #expect(LanguageHints.isLikelyEnglish("you"))
        #expect(LanguageHints.isLikelyEnglish("was"))
        #expect(LanguageHints.isLikelyEnglish("from"))
    }

    @Test("English word matching is case-insensitive")
    func englishWordCaseInsensitive() {
        #expect(LanguageHints.isLikelyEnglish("The"))
        #expect(LanguageHints.isLikelyEnglish("AND"))
        #expect(LanguageHints.isLikelyEnglish("For"))
    }

    @Test("Recognizes English prefixes in longer words")
    func englishPrefixMatch() {
        #expect(LanguageHints.isLikelyEnglish("theory"))
        #expect(LanguageHints.isLikelyEnglish("program"))
        #expect(LanguageHints.isLikelyEnglish("control"))
        #expect(LanguageHints.isLikelyEnglish("without"))
        #expect(LanguageHints.isLikelyEnglish("string"))
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

    // MARK: - The original problem scenario

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

    // MARK: - Prefix minimum length

    @Test("црщ on RU keyboard maps to who which is recognized as English")
    func whoScenario() {
        let mapped = LayoutMap.mapRuToEn("црщ")
        #expect(mapped == "who")
        #expect(LanguageHints.isLikelyEnglish("who"))
    }

    @Test("Recognizes 'why' as English")
    func whyIsEnglish() {
        #expect(LanguageHints.isLikelyEnglish("why"))
        #expect(LanguageHints.isLikelyEnglish("Why"))
    }

    @Test("Recognizes Russian words containing ж")
    func russianWordsWithZhe() {
        #expect(LanguageHints.isLikelyRussian("можно"))
        #expect(LanguageHints.isLikelyRussian("нужно"))
        #expect(LanguageHints.isLikelyRussian("каждый"))
        #expect(LanguageHints.isLikelyRussian("между"))
        #expect(LanguageHints.isLikelyRussian("нож"))
        #expect(LanguageHints.isLikelyRussian("муж"))
    }

    @Test("Prefix matching requires at least 3 characters")
    func prefixMinLength() {
        #expect(!LanguageHints.isLikelyRussian("та"))
        #expect(!LanguageHints.isLikelyEnglish("th"))
    }
}
