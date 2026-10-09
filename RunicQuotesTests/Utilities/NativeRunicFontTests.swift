//
//  NativeRunicFontTests.swift
//  RunicQuotes
//
//  Created by Claude on 09.10.26.
//

#if canImport(UIKit)
    import CoreText
    @testable import RunicQuotes
    import Testing
    import UIKit

    @MainActor
    @Suite(.serialized, .tags(.utility))
    struct NativeRunicFontTests {
        @Test
        func registeredCirthFontEncodesEveryCSURGraphOnTheActualNativeHost() throws {
            let characters = (0xE080 ... 0xE0C1).map { UniChar($0) }
            #expect(characters.count == 66)
            try self.expectGlyphCoverage(name: RunicFontConfiguration.fontName(for: .cirth, font: .cirth), characters: characters)
        }

        @Test
        func eligibleHistoricalFontsEncodeCanonicalElderAndYoungerInventories() throws {
            let elder = "ᚠᚢᚦᚨᚱᚲᚷᚹᚺᚾᛁᛃᛇᛈᛉᛊᛏᛒᛖᛗᛚᛜᛟᛞ"
            let younger = "ᚠᚢᚦᚬᚱᚴᚼᚾᛁᛅᛋᛏᛒᛘᛚᛦ"
            let shortTwig = "ᚠᚢᚦᚭᚱᚴᚽᚿᛁᛆᛌᛐᛓᛙᛚᛧ"
            #expect(shortTwig.utf16.count == 16)
            #expect(elder.utf16.count == 24)
            #expect(younger.utf16.count == 16)
            for font in [RunicFont.noto, .babelstone] {
                try self.expectGlyphCoverage(name: RunicFontConfiguration.fontName(for: .elder, font: font), characters: Array(elder.utf16))
                try self.expectGlyphCoverage(name: RunicFontConfiguration.fontName(for: .younger, font: font), characters: Array(younger.utf16))
                try self.expectGlyphCoverage(name: RunicFontConfiguration.fontName(for: .younger, font: font), characters: Array(shortTwig.utf16))
            }
        }

        private func expectGlyphCoverage(name: String, characters: [UniChar]) throws {
            let nativeFont = try #require(UIFont(name: name, size: 24), "The exact preferred font must be registered; fallback is not sufficient")
            let font = CTFontCreateWithName(nativeFont.fontName as CFString, 24, nil)
            var glyphs = [CGGlyph](repeating: 0, count: characters.count)
            let supported = characters.withUnsafeBufferPointer { input in
                glyphs.withUnsafeMutableBufferPointer { output in
                    guard let inputAddress = input.baseAddress, let outputAddress = output.baseAddress else { return false }
                    return CTFontGetGlyphsForCharacters(font, inputAddress, outputAddress, characters.count)
                }
            }
            #expect(supported)
            #expect(glyphs.allSatisfy { $0 != 0 })
        }
    }
#endif
