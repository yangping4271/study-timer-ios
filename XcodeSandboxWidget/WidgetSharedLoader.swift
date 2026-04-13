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
    let activeSessionStartedAt: Date?
    let hasStudiedToday: Bool
    let completedDurationToday: TimeInterval
}

enum WidgetSharedLoader {
    static func loadSummary(now: Date = .now, calendar: Calendar = .current) -> WidgetSnapshotSummary {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let fallback = WidgetSnapshotSummary(
            todayDuration: 0,
            goalMinutes: 120,
            activeProjectName: nil,
            activeSessionStartedAt: nil,
            hasStudiedToday: false,
            completedDurationToday: 0
        )
        guard let data = try? Data(contentsOf: SharedConfig.sharedSnapshotURL()) else { return fallback }
        guard let snapshot = try? decoder.decode(StudySnapshot.self, from: data) else { return fallback }

        let startOfDay = calendar.startOfDay(for: now)
        let todaysSessions = snapshot.sessions
            .filter { $0.startedAt >= startOfDay }
            .sorted { $0.endedAt > $1.endedAt }

        let finishedDuration = todaysSessions.reduce(0) { $0 + $1.duration }

        let activeProjectName: String?
        if let activeSession = snapshot.activeSession {
            activeProjectName = snapshot.projects.first { $0.id == activeSession.projectID }?.name
        } else if let latestSession = todaysSessions.first {
            activeProjectName = snapshot.projects.first { $0.id == latestSession.projectID }?.name
        } else {
            activeProjectName = nil
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
            activeProjectName: activeProjectName,
            activeSessionStartedAt: snapshot.activeSession?.startedAt,
            hasStudiedToday: !todaysSessions.isEmpty || activeDuration > 0,
            completedDurationToday: finishedDuration
        )
    }
}
