//
//  StudyModels.swift
//  XcodeSandbox
//
//  Created by Codex on 4/12/26.
//

import Foundation

struct StudyProject: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var colorName: String
    var createdAt: Date

    init(id: UUID = UUID(), name: String, colorName: String, createdAt: Date = .now) {
        self.id = id
        self.name = name
        self.colorName = colorName
        self.createdAt = createdAt
    }
}

struct StudySession: Identifiable, Codable, Hashable {
    var id: UUID
    var projectID: UUID
    var startedAt: Date
    var endedAt: Date

    init(
        id: UUID = UUID(),
        projectID: UUID,
        startedAt: Date,
        endedAt: Date
    ) {
        self.id = id
        self.projectID = projectID
        self.startedAt = startedAt
        self.endedAt = endedAt
    }

    var duration: TimeInterval {
        endedAt.timeIntervalSince(startedAt)
    }
}

struct ActiveSession: Codable, Hashable {
    var projectID: UUID
    var startedAt: Date
}

struct StudySnapshot: Codable {
    var projects: [StudyProject]
    var sessions: [StudySession]
    var activeSession: ActiveSession?
}

enum ProjectColor: String, CaseIterable, Identifiable, Codable {
    case blue
    case green
    case orange
    case pink
    case red
    case teal

    var id: String { rawValue }
}
