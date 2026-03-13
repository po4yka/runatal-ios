//
//  CoreModelTests.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
//

import Foundation
@testable import RunicQuotes
import Testing

@Suite(.tags(.model))
struct RunicScriptTests {
    @Test
    func casesExposeDisplayNamesAndRanges() {
        #expect(RunicScript.allCases.count == 3)
        #expect(RunicScript.elder.id == RunicScript.elder.rawValue)
        #expect(RunicScript.younger.unicodeRange == 0x16A0 ... 0x16EA)
        #expect(RunicScript.cirth.unicodeRange == nil)
        #expect(RunicScript.cirth.description.contains("Tolkien"))
    }
}

@Suite(.tags(.model))
struct RunicFontAndPresetTests {
    @Test
    func runicFontCompatibilityAndMetadata() {
        #expect(RunicFont.noto.fileName == "NotoSansRunic-Regular.ttf")
        #expect(RunicFont.babelstone.isCompatible(with: .elder))
        #expect(!RunicFont.noto.isCompatible(with: .cirth))
        #expect(RunicFont.cirth.displayName == "Angerthas")
    }

    @Test
    func readingPresetsMapToExpectedScriptAndFont() {
        #expect(ReadingPreset.elderScholar.script == .elder)
        #expect(ReadingPreset.youngerCarved.font == .babelstone)
        #expect(ReadingPreset.cirthLore.previewLatinText == "Stars guard the hidden road.")
    }

    @Test
    func appThemeAndWidgetEnumsExposeDescriptions() {
        #expect(AppTheme.obsidian.description.contains("Dark"))
        #expect(AppTheme.nordicDawn.displayName == "Nordic Dawn")
        #expect(WidgetMode.daily.description.contains("Same quote"))
        #expect(WidgetStyle.translationFirst.description.contains("Latin translation"))
    }
}

@Suite(.tags(.model))
struct UserPreferencesSnapshotTests {
    @Test
    func toggleSavedQuoteTracksMembership() {
        var snapshot = UserPreferencesSnapshot()
        let quoteID = UUID()

        #expect(!snapshot.isQuoteSaved(quoteID))
        let firstToggle = snapshot.toggleSavedQuote(quoteID)
        #expect(firstToggle)
        #expect(snapshot.isQuoteSaved(quoteID))
        let secondToggle = snapshot.toggleSavedQuote(quoteID)
        #expect(secondToggle == false)
        #expect(!snapshot.isQuoteSaved(quoteID))
    }

    @Test
    func installPackTracksMembership() {
        var snapshot = UserPreferencesSnapshot()
        #expect(!snapshot.isPackInstalled("stoic-pack"))
        let firstInstall = snapshot.installPack("stoic-pack")
        #expect(firstInstall)
        #expect(snapshot.isPackInstalled("stoic-pack"))
        let secondInstall = snapshot.installPack("stoic-pack")
        #expect(secondInstall == false)
    }
}

@Suite(.tags(.model))
struct RunicTextBundleTests {
    @Test
    func returnsTextForRequestedScript() {
        let bundle = RunicTextBundle(elder: "elder", younger: "younger", cirth: "cirth")

        #expect(bundle.text(for: .elder) == "elder")
        #expect(bundle.text(for: .younger) == "younger")
        #expect(bundle.text(for: .cirth) == "cirth")
    }
}

@Suite(.tags(.model))
struct QuoteRecordTests {
    @Test
    func runicTextReturnsRequestedVariant() {
        let record = TestSupport.makeQuoteRecord(
            runicElder: "elder",
            runicYounger: "younger",
            runicCirth: "cirth",
        )

        #expect(record.runicText(for: .elder) == "elder")
        #expect(record.runicText(for: .younger) == "younger")
        #expect(record.runicText(for: .cirth) == "cirth")
    }

    @Test
    func quoteRecordPreservesArchiveFlagsAndUserSource() {
        let deletedAt = Date(timeIntervalSince1970: 42)
        let record = TestSupport.makeQuoteRecord(
            source: "Saga",
            isHidden: true,
            isDeleted: true,
            deletedAt: deletedAt,
            isUserGenerated: true,
        )

        #expect(record.source == "Saga")
        #expect(record.isHidden)
        #expect(record.isDeleted)
        #expect(record.deletedAt == deletedAt)
        #expect(record.isUserGenerated)
    }
}

@Suite(.tags(.model))
struct QuoteDataTests {
    @Test
    func runicTextFallsBackToLatinWhenMissing() {
        let data = QuoteData(
            textLatin: "Fortune favors the bold",
            author: "Virgil",
            runicElder: nil,
            runicYounger: "younger",
            runicCirth: nil,
        )

        #expect(data.runicText(for: .elder) == data.textLatin)
        #expect(data.runicText(for: .younger) == "younger")
        #expect(data.runicText(for: .cirth) == data.textLatin)
    }

    @Test
    func samplesProvidePreviewCoverage() {
        #expect(!QuoteData.sample.textLatin.isEmpty)
        #expect(QuoteData.samples.count >= 3)
    }
}
