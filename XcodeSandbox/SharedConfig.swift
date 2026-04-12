//
//  SharedConfig.swift
//  XcodeSandbox
//
//  Created by Codex on 4/12/26.
//

import Foundation

enum SharedConfig {
    static let appGroupID = "group.com.yangping.xcodesandbox.shared"
    static let snapshotFolderName = "StudyTimer"
    static let snapshotFileName = "study-data.json"

    static func sharedContainerURL(fileManager: FileManager = .default) -> URL? {
        fileManager.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)
    }

    static func sharedSnapshotURL(fileManager: FileManager = .default) -> URL {
        let baseURL = sharedContainerURL(fileManager: fileManager)
            ?? fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory

        return baseURL
            .appendingPathComponent(snapshotFolderName, isDirectory: true)
            .appendingPathComponent(snapshotFileName)
    }
}
