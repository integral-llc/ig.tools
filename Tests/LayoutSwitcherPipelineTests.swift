import Testing

@testable import IGTools

/// Simulates the full typing pipeline: char-by-char buffer accumulation →
/// word extraction on boundary → layout mapping → language detection.
/// This mirrors the actual runtime flow through LayoutBuffer + shouldSwitch logic.
@Suite("Layout Switcher Pipeline Tests")
struct LayoutSwitcherPipelineTests {

    // MARK: - Helpers

    /// Simulates typing a string char by char into a LayoutBuffer, ending with a boundary.
    /// Returns the extracted word (if any) and boundary character.
    private func simulateTyping(
        _ text: String,
        boundary: Character = " ",
        buffer: LayoutBuffer = LayoutBuffer()
    ) -> (word: String, boundary: Character)? {
        for char in text {
            if let result = buffer.append(char) {
                // A mid-text boundary was hit (e.g. punctuation in the string)
                return result
            }
        }
        // Simulate the boundary keystroke (space/enter/tab)
        // In the real app, space is handled by forceComplete() via keyCode,
        // not via append(). Test both paths.
        return buffer.forceComplete().map { (word: $0, boundary: boundary) }
    }

    /// Simulates the detection decision: given a word typed on a specific layout,
    /// should the system switch layouts?
    /// This mirrors shouldSwitch() logic without needing NSSpellChecker.
    private func shouldSwitchViaHints(word: String, isRussianLayout: Bool) -> (shouldSwitch: Bool, mapped: String?) {
        // Step 1: check if hints confirm the word in current language
        let hintCurrent = isRussianLayout
            ? LanguageHints.isLikelyRussian(word)
            : LanguageHints.isLikelyEnglish(word)
        if hintCurrent { return (false, nil) }

        // Step 2: map to other layout
        let mapped: String?
        if isRussianLayout {
            mapped = LayoutMap.mapRuToEn(word)
        } else {
            mapped = LayoutMap.mapEnToRu(word)
        }
        guard let m = mapped else { return (false, nil) }

        // Step 3: check if hints recognize the mapped version
        let hintOther = isRussianLayout
            ? LanguageHints.isLikelyEnglish(m)
            : LanguageHints.isLikelyRussian(m)

        return (hintOther, m)
    }

    /// Checks the minWordLength bypass: would a 3-char word pass the length gate
    /// when minWordLength is 4?
    private func passesLengthGate(word: String, minWordLength: Int, isRussianLayout: Bool) -> Bool {
        if word.count >= minWordLength { return true }
        if word.count < 3 { return false }
        // Mirror hasHintForMappedWord logic
        let mapped: String?
        if isRussianLayout {
            mapped = LayoutMap.mapRuToEn(word)
        } else {
            mapped = LayoutMap.mapEnToRu(word)
        }
        guard let m = mapped else { return false }
        return isRussianLayout
            ? LanguageHints.isLikelyEnglish(m)
            : LanguageHints.isLikelyRussian(m)
    }

    // MARK: - Buffer accumulation tests

    @Test("Buffer accumulates characters and extracts word on forceComplete")
    func bufferAccumulation() {
        let buffer = LayoutBuffer()
        #expect(buffer.append("n") == nil)
        #expect(buffer.append("f") == nil)
        #expect(buffer.append("r") == nil)
        let word = buffer.forceComplete()
        #expect(word == "nfr")
    }

    @Test("Buffer extracts word when boundary character is appended")
    func bufferBoundaryViaAppend() {
        let buffer = LayoutBuffer()
        #expect(buffer.append("n") == nil)
        #expect(buffer.append("f") == nil)
        #expect(buffer.append("r") == nil)
        let result = buffer.append(".")
        #expect(result?.word == "nfr")
        #expect(result?.boundary == ".")
    }

    @Test("Buffer clears on digit")
    func bufferClearsOnDigit() {
        let buffer = LayoutBuffer()
        _ = buffer.append("a")
        _ = buffer.append("b")
        _ = buffer.append("3")
        #expect(buffer.forceComplete() == nil)
    }

    @Test("Buffer ignores input when expanding")
    func bufferExpandingGuard() {
        let buffer = LayoutBuffer()
        _ = buffer.append("a")
        buffer.setExpanding(true)
        _ = buffer.append("b") // ignored — expanding
        #expect(buffer.forceComplete() == nil) // forceComplete returns nil during expanding
        buffer.setExpanding(false)
        // "a" is still in the buffer from before expanding was set;
        // "b" was ignored. Adding "x" gives "ax".
        _ = buffer.append("x")
        #expect(buffer.forceComplete() == "ax")
    }

    @Test("Buffer clearCurrentWord preserves phrase history")
    func clearCurrentWordPreservesHistory() {
        let buffer = LayoutBuffer()
        buffer.appendToHistory(word: "hello", boundary: " ")
        _ = buffer.append("w")
        _ = buffer.append("o")
        buffer.clearCurrentWord()
        #expect(buffer.forceComplete() == nil) // current word cleared
        let history = buffer.drainHistory()
        #expect(history.count == 1)
        #expect(history[0].word == "hello")
    }

    // MARK: - Full pipeline: EN layout, typing Russian words

    @Test("Type 'nfr' char by char on EN → extracts 'nfr' → maps to 'так' → switch")
    func pipelineNfrToTak() {
        let result = simulateTyping("nfr")
        #expect(result?.word == "nfr")

        let decision = shouldSwitchViaHints(word: "nfr", isRussianLayout: false)
        #expect(decision.shouldSwitch == true)
        #expect(decision.mapped == "так")
    }

    @Test("Type 'xnj' char by char on EN → extracts 'xnj' → maps to 'что' → switch")
    func pipelineXnjToChto() {
        let result = simulateTyping("xnj")
        #expect(result?.word == "xnj")

        let decision = shouldSwitchViaHints(word: "xnj", isRussianLayout: false)
        #expect(decision.shouldSwitch == true)
        #expect(decision.mapped == "что")
    }

    @Test("Type 'ghbdtn' char by char on EN → extracts 'ghbdtn' → maps to 'привет' → switch")
    func pipelineGhbdtnToPrivet() {
        let result = simulateTyping("ghbdtn")
        #expect(result?.word == "ghbdtn")

        let decision = shouldSwitchViaHints(word: "ghbdtn", isRussianLayout: false)
        #expect(decision.shouldSwitch == true)
        #expect(decision.mapped == "привет")
        // "привет" starts with "при" which is in russianPrefixes
    }

    @Test("Type 'lkz' char by char on EN → extracts 'lkz' → maps to 'для' → switch")
    func pipelineLkzToDlya() {
        let result = simulateTyping("lkz")
        #expect(result?.word == "lkz")

        let decision = shouldSwitchViaHints(word: "lkz", isRussianLayout: false)
        #expect(decision.shouldSwitch == true)
        #expect(decision.mapped == "для")
    }

    // MARK: - Full pipeline: RU layout, typing English words

    @Test("Type 'црщ' char by char on RU → extracts 'црщ' → maps to 'who' → switch")
    func pipelineTsrshchToWho() {
        let result = simulateTyping("црщ")
        #expect(result?.word == "црщ")

        let decision = shouldSwitchViaHints(word: "црщ", isRussianLayout: true)
        #expect(decision.shouldSwitch == true)
        #expect(decision.mapped == "who")
    }

    @Test("Type 'еру' char by char on RU → extracts 'еру' → maps to 'the' → switch")
    func pipelineEruToThe() {
        let result = simulateTyping("еру")
        #expect(result?.word == "еру")

        let decision = shouldSwitchViaHints(word: "еру", isRussianLayout: true)
        #expect(decision.shouldSwitch == true)
        #expect(decision.mapped == "the")
    }

    @Test("Type 'ащк' char by char on RU → extracts 'ащк' → maps to 'for' → switch")
    func pipelineAshchkToFor() {
        let result = simulateTyping("ащк")
        #expect(result?.word == "ащк")

        let decision = shouldSwitchViaHints(word: "ащк", isRussianLayout: true)
        #expect(decision.shouldSwitch == true)
        #expect(decision.mapped == "for")
    }

    // MARK: - No false switches on correct-layout words

    @Test("Typing valid Russian word on RU layout → no switch")
    func noSwitchOnValidRussian() {
        let decision = shouldSwitchViaHints(word: "так", isRussianLayout: true)
        #expect(decision.shouldSwitch == false)
    }

    @Test("Typing valid English word on EN layout → no switch")
    func noSwitchOnValidEnglish() {
        let decision = shouldSwitchViaHints(word: "the", isRussianLayout: false)
        #expect(decision.shouldSwitch == false)
    }

    @Test("Typing unmappable gibberish → no switch")
    func noSwitchOnGibberish() {
        let decision = shouldSwitchViaHints(word: "qzx", isRussianLayout: false)
        // "qzx" maps to "йяч" which is not in hints
        #expect(decision.shouldSwitch == false)
    }

    // MARK: - minWordLength bypass tests

    @Test("3-char word 'nfr' bypasses minWordLength=4 because mapped 'так' is in hints")
    func minLengthBypassNfr() {
        let passes = passesLengthGate(word: "nfr", minWordLength: 4, isRussianLayout: false)
        #expect(passes == true)
    }

    @Test("3-char word 'црщ' bypasses minWordLength=4 because mapped 'who' is in hints")
    func minLengthBypassTsrshch() {
        let passes = passesLengthGate(word: "црщ", minWordLength: 4, isRussianLayout: true)
        #expect(passes == true)
    }

    @Test("3-char gibberish 'qzx' does NOT bypass minWordLength=4")
    func minLengthNoBypassGibberish() {
        let passes = passesLengthGate(word: "qzx", minWordLength: 4, isRussianLayout: false)
        #expect(passes == false)
    }

    @Test("2-char word never bypasses minWordLength even if mappable")
    func minLengthNo2Char() {
        let passes = passesLengthGate(word: "nf", minWordLength: 4, isRussianLayout: false)
        #expect(passes == false)
    }

    @Test("4-char word always passes minWordLength=4 regardless of hints")
    func minLength4CharAlwaysPasses() {
        let passes = passesLengthGate(word: "abcd", minWordLength: 4, isRussianLayout: false)
        #expect(passes == true)
    }

    // MARK: - Semicolon as ж (not a word boundary)

    @Test("Semicolon is NOT a word boundary — 'vj;yj' stays as one word")
    func semicolonNotBoundary() {
        let result = simulateTyping("vj;yj")
        #expect(result?.word == "vj;yj")
    }

    @Test("Type 'vj;yj' on EN → maps to 'можно' → switch")
    func pipelineMozhno() {
        let result = simulateTyping("vj;yj")
        #expect(result?.word == "vj;yj")

        let mapped = LayoutMap.mapEnToRu("vj;yj")
        #expect(mapped == "можно")

        let decision = shouldSwitchViaHints(word: "vj;yj", isRussianLayout: false)
        #expect(decision.shouldSwitch == true)
        #expect(decision.mapped == "можно")
    }

    @Test("Type 'ye;yj' on EN → maps to 'нужно' → switch")
    func pipelineNuzhno() {
        let result = simulateTyping("ye;yj")
        #expect(result?.word == "ye;yj")

        let decision = shouldSwitchViaHints(word: "ye;yj", isRussianLayout: false)
        #expect(decision.shouldSwitch == true)
        #expect(decision.mapped == "нужно")
    }

    // MARK: - 'why' detection (црн on RU layout)

    @Test("Type 'црн' on RU → maps to 'why' → switch")
    func pipelineWhyDetection() {
        let result = simulateTyping("црн")
        #expect(result?.word == "црн")

        let decision = shouldSwitchViaHints(word: "црн", isRussianLayout: true)
        #expect(decision.shouldSwitch == true)
        #expect(decision.mapped == "why")
    }

    @Test("'црн' bypasses minWordLength=4 because mapped 'why' is in hints")
    func minLengthBypassWhy() {
        let passes = passesLengthGate(word: "црн", minWordLength: 4, isRussianLayout: true)
        #expect(passes == true)
    }

    // MARK: - Multi-word phrase simulation

    @Test("Two words typed sequentially accumulate in phrase history")
    func phraseHistoryAccumulation() {
        let buffer = LayoutBuffer()

        // Type first word: "ghj" (maps to "про")
        for c in "ghj" { _ = buffer.append(c) }
        let word1 = buffer.forceComplete()
        #expect(word1 == "ghj")
        buffer.appendToHistory(word: "ghj", boundary: " ")

        // Type second word: "nfr" (maps to "так")
        for c in "nfr" { _ = buffer.append(c) }
        let word2 = buffer.forceComplete()
        #expect(word2 == "nfr")

        // Drain history — should have the first word
        let history = buffer.drainHistory()
        #expect(history.count == 1)
        #expect(history[0].word == "ghj")
        #expect(history[0].boundary == " ")

        // Verify both map correctly
        #expect(LayoutMap.mapEnToRu("ghj") == "про")
        #expect(LayoutMap.mapEnToRu("nfr") == "так")
    }
}
