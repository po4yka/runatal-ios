//
//  QuoteSourceSheet.swift
//  RunicQuotes
//
//  Created by Claude on 09.10.26.
//

import SwiftUI

struct QuoteSourceSheet: View {
    let source: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                    Text("Original passage source").font(.headline)
                    Text(self.source).textSelection(.enabled)
                    if let url = Self.webURL(in: self.source) {
                        Link("Open source", destination: url)
                            .accessibilityIdentifier("quote_source_link")
                    }
                    Text("This source identifies the original passage. Historical translation evidence is shown separately.")
                        .font(.caption)
                }
                .padding()
            }
            .accessibilityIdentifier("quote_source_sheet")
            .navigationTitle("Passage source")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { self.dismiss() }
                }
            }
        }
    }

    static func webURL(in source: String) -> URL? {
        for line in source.components(separatedBy: .newlines).reversed() {
            guard let url = URL(string: line.trimmingCharacters(in: .whitespacesAndNewlines)),
                  ["http", "https"].contains(url.scheme?.lowercased() ?? ""), url.host != nil else { continue }
            return url
        }
        return nil
    }
}
