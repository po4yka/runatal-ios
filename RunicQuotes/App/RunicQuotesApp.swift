//
//  RunicQuotesApp.swift
//  RunicQuotes
//
//  Created by Claude on 2025-11-15.
//

import SwiftUI
import SwiftData

@main
struct RunicQuotesApp: App {
    // MARK: - SwiftData Model Container

    let modelContainer: ModelContainer

    // MARK: - Initialization

    init() {
        do {
            // Configure the SwiftData model container
            let schema = Schema([
                Quote.self,
                UserPreferences.self
            ])

            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )

            modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )

            // Seed database on first launch
            Task {
                let context = ModelContext(modelContainer)
                let repository = SwiftDataQuoteRepository(modelContext: context)
                try await repository.seedIfNeeded()
            }
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(modelContainer)
        }
    }
}

/// Temporary placeholder view until we implement the full UI in Phase 2
struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var currentQuote: Quote?
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            // Liquid glass background
            LinearGradient(
                colors: [.black, Color(white: 0.1), .black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 30) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.5)
                } else if let error = errorMessage {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                        .padding()
                } else if let quote = currentQuote {
                    VStack(spacing: 20) {
                        // Runic text
                        if let runicText = quote.runicElder {
                            Text(runicText)
                                .font(.custom("Noto Sans Runic", size: 32))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(.ultraThinMaterial)
                                )
                        }

                        // Latin text
                        Text(quote.textLatin)
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        // Author
                        Text("— \(quote.author)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                            .italic()

                        // Next button
                        Button("Next Quote") {
                            loadRandomQuote()
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.thinMaterial)
                        )
                        .foregroundColor(.white)
                    }
                    .padding()
                }

                Text("Phase 1 Complete ✓")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.bottom)
            }
        }
        .task {
            loadQuoteOfTheDay()
        }
    }

    private func loadQuoteOfTheDay() {
        Task {
            do {
                let repository = SwiftDataQuoteRepository(modelContext: modelContext)
                currentQuote = try await repository.quoteOfTheDay(for: .elder)
                isLoading = false
            } catch {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }

    private func loadRandomQuote() {
        Task {
            do {
                let repository = SwiftDataQuoteRepository(modelContext: modelContext)
                currentQuote = try await repository.randomQuote(for: .elder)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Quote.self, UserPreferences.self], inMemory: true)
}
