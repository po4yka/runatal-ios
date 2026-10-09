//
//  ShareRenderingTests.swift
//  RunicQuotes
//
//  Created by Claude on 09.10.26.
//

#if canImport(UIKit)
    @testable import RunicQuotes
    import SwiftUI
    import UIKit
    import XCTest

    @MainActor
    final class ShareRenderingTests: XCTestCase {
        func testGenuineFullQuoteKeepsEveryRunicLineAt320PointsAcrossScriptsAndStyles() throws {
            let quote = try XCTUnwrap(QuoteSeedCatalog.load().first { $0.id == "builtin-0001" })
            for script in RunicScript.allCases {
                let full = RunicTransliterator.transliterate(quote.textLatin, to: script)
                let firstWord = full.glyphOutput.split(separator: " ").first.map(String.init) ?? full.glyphOutput
                for style in ShareCardStyle.allCases {
                    let short = try self.render(runic: firstWord, quote: quote, script: script, style: style)
                    let long = try self.render(runic: full.glyphOutput, quote: quote, script: script, style: style)
                    XCTAssertEqual(short.size.width, 320)
                    XCTAssertEqual(long.size.width, 320)
                    XCTAssertGreaterThan(
                        long.size.height,
                        short.size.height + 20,
                        "Rune content alone must expand the card; Latin/author/disclosure remain identical",
                    )
                    let attachment = XCTAttachment(image: long)
                    attachment.name = "Share-320pt-\(script.rawValue)-\(style.rawValue)-full-quote"
                    attachment.lifetime = .keepAlways
                    self.add(attachment)
                    let text = XCTAttachment(string: "Complete canonical glyph text, including its final line:\n\(full.glyphOutput)")
                    text.name = "Expected-full-runic-text-\(script.rawValue)-\(style.rawValue)"
                    text.lifetime = .keepAlways
                    self.add(text)
                }
            }
        }

        func testShareBodyWrapsAndExpandsAtAccessibilitySizes() throws {
            let quote = try XCTUnwrap(QuoteSeedCatalog.load().first { $0.id == "builtin-0001" })
            let card = ShareCardContent(
                runicText: "", latinText: quote.textLatin, author: quote.author,
                script: .elder, font: .noto, style: .light,
                presentationSource: .storedTransliteration, evidenceTier: nil, primarySourceLabel: nil,
            ).frame(width: 320)
            let normal = ImageRenderer(content: card.environment(\.dynamicTypeSize, .large))
            let accessible = ImageRenderer(content: card.environment(\.dynamicTypeSize, .accessibility5))
            let normalImage = try XCTUnwrap(normal.uiImage)
            let accessibleImage = try XCTUnwrap(accessible.uiImage)
            XCTAssertEqual(normalImage.size.width, accessibleImage.size.width)
            XCTAssertGreaterThan(accessibleImage.size.height, normalImage.size.height + 50)
            let attachment = XCTAttachment(image: accessibleImage)
            attachment.name = "Share-320pt-system-serif-accessibility5"
            attachment.lifetime = .keepAlways
            self.add(attachment)
        }

        private func render(runic: String, quote: QuoteCatalogEntry, script: RunicScript, style: ShareCardStyle) throws -> UIImage {
            let card = ShareCardContent(
                runicText: runic,
                latinText: quote.textLatin,
                author: quote.author,
                script: script,
                font: RunicFontConfiguration.recommendedFont(for: script),
                style: style,
                presentationSource: .storedTransliteration,
                evidenceTier: nil,
                primarySourceLabel: quote.source,
            )
            .frame(width: 320)
            let renderer = ImageRenderer(content: card)
            renderer.scale = 1
            return try XCTUnwrap(renderer.uiImage)
        }
    }
#endif
