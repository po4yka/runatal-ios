//
//  PhotoLibraryImageSaver.swift
//  RunicQuotes
//
//  Created by Claude on 08.10.26.
//

import Foundation
import Photos

/// Saves a rendered card with add-only access and waits for Photos to commit the asset.
@MainActor
struct PhotoLibraryImageSaver {
    private let requestAuthorization: @MainActor () async -> PHAuthorizationStatus
    private let writeImage: @MainActor (Data) async throws -> Void

    init(
        requestAuthorization: @escaping @MainActor () async -> PHAuthorizationStatus = {
            await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        },
        writeImage: @escaping @MainActor (Data) async throws -> Void = { data in
            try await PHPhotoLibrary.shared().performChanges {
                let request = PHAssetCreationRequest.forAsset()
                request.addResource(with: .photo, data: data, options: nil)
            }
        },
    ) {
        self.requestAuthorization = requestAuthorization
        self.writeImage = writeImage
    }

    func save(_ imageData: Data) async throws {
        guard await self.requestAuthorization() == .authorized else {
            throw PhotoLibraryImageSaveError.accessDenied
        }
        try await self.writeImage(imageData)
    }
}

enum PhotoLibraryImageSaveError: LocalizedError {
    case accessDenied
    case renderingFailed

    var errorDescription: String? {
        switch self {
        case .accessDenied:
            "Allow Runatal to add photos in Settings, then try saving again."
        case .renderingFailed:
            "The quote image could not be created. Please try again."
        }
    }
}
