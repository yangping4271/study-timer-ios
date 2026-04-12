//
//  WidgetSharedLoader.swift
//  XcodeSandboxWidget
//
//  Created by Codex on 4/12/26.
//

import Foundation

struct WidgetSnapshotSummary {
    let todayDuration: TimeInterval
    let goalMinutes: Int
    let activeProjectName: String?
}

enum WidgetSharedLoader {
    static func loadSummary(now: Date = .now, calendar: Calendar = .current) -> WidgetSnapshotSummary {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let fallback = WidgetSnapshotSummary(todayDuration: 0, goalMinutes: 120, activeProjectName: nil)
        guard let data = try? Data(contentsOf: SharedConfig.sharedSnapshotURL()) else { return fallback }
        guard let snapshot = try? decoder.decode(StudySnapshot.self, from: data) else { return fallback }

        let startOfDay = calendar.startOfDay(for: now)
        let finishedDuration = snapshot.sessions
            .filter { $0.startedAt >= startOfDay }
            .reduce(0) { $0 + $1.duration }

        let activeProjectName = snapshot.activeSession.flatMap { activeSession in
            snapshot.projects.first { $0.id == activeSession.projectID }?.name
        }

        let activeDuration: TimeInterval
        if let activeSession = snapshot.activeSession, activeSession.startedAt >= startOfDay {
            activeDuration = now.timeIntervalSince(activeSession.startedAt)
        } else {
            activeDuration = 0
        }

        return WidgetSnapshotSummary(
            todayDuration: finishedDuration + activeDuration,
            goalMinutes: snapshot.dailyGoalMinutes,
            activeProjectName: activeProjectName
        )
    }
}
