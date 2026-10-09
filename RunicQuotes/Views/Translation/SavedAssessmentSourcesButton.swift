//
//  SavedAssessmentSourcesButton.swift
//  RunicQuotes
//
//  Created by Claude on 09.10.26.
//

import SwiftUI

/// Keeps the displayed saved assessment fixed while its source sheet is open.
struct SavedAssessmentSourcesButton: View {
    let artifact: TranslationResult?
    @State private var selectedArtifact: TranslationResult?
    @State private var isPresented = false

    var body: some View {
        Group {
            if let artifact {
                Button("Saved assessment & sources") {
                    self.selectedArtifact = artifact
                    self.isPresented = true
                }
                .accessibilityIdentifier("saved_assessment_sources_button")
            }
        }
        .sheet(isPresented: self.$isPresented) {
            if let selectedArtifact {
                TranslationProvenanceDetailSheet(
                    provenance: selectedArtifact.provenance,
                    assessmentDisclosure: "Recorded evidence: \(selectedArtifact.evidenceTier.displayName). Saved engine \(selectedArtifact.engineVersion), dataset \(selectedArtifact.datasetVersion). This assessment has not been rechecked by the current engine.",
                )
            }
        }
    }
}
