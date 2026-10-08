//
//  PhotoLibraryImageSaverTests.swift
//  RunicQuotes
//
//  Created by Claude on 08.10.26.
//

import Foundation
import Photos
@testable import RunicQuotes
import Testing

@MainActor
@Suite(.tags(.utility))
struct PhotoLibraryImageSaverTests {
    @Test
    func authorizedSaveWritesImageAndAwaitsCompletion() async throws {
        let imageData = Data([0x89, 0x50, 0x4E, 0x47])
        var writtenData: Data?
        var writeCompleted = false
        let saver = PhotoLibraryImageSaver(
            requestAuthorization: { .authorized },
            writeImage: { data in
                await Task.yield()
                writtenData = data
                writeCompleted = true
            },
        )

        try await saver.save(imageData)

        #expect(writtenData == imageData)
        #expect(writeCompleted)
    }

    @Test(arguments: [
        PHAuthorizationStatus.denied,
        .restricted,
        .notDetermined,
        .limited,
    ])
    func unauthorizedSaveThrowsWithoutWriting(status: PHAuthorizationStatus) async {
        var didWrite = false
        let saver = PhotoLibraryImageSaver(
            requestAuthorization: { status },
            writeImage: { _ in didWrite = true },
        )

        await #expect(throws: PhotoLibraryImageSaveError.accessDenied) {
            try await saver.save(Data([0x89]))
        }
        #expect(!didWrite)
    }

    @Test
    func writeFailurePropagatesToCaller() async {
        let saver = PhotoLibraryImageSaver(
            requestAuthorization: { .authorized },
            writeImage: { _ in throw TestWriteError.failed },
        )

        await #expect(throws: TestWriteError.failed) {
            try await saver.save(Data([0x89]))
        }
    }
}

private enum TestWriteError: Error {
    case failed
}
