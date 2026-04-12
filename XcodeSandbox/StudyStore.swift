//
//  StudyStore.swift
//  XcodeSandbox
//
//  Created by Codex on 4/12/26.
//

import Foundation
import Observation

@Observable
final class StudyStore {
    private(set) var projects: [StudyProject]
    private(set) var sessions: [StudySession]
    private(set) var activeSession: ActiveSession?
    private(set) var dailyGoalMinutes: Int

    private let calendar: Calendar
    private let saveURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(
        projects: [StudyProject] = [],
        sessions: [StudySession] = [],
        activeSession: ActiveSession? = nil,
        dailyGoalMinutes: Int = 120,
        calendar: Calendar = .current,
        saveURL: URL? = nil
    ) {
        self.projects = projects
        self.sessions = sessions
        self.activeSession = activeSession
        self.dailyGoalMinutes = dailyGoalMinutes
        self.calendar = calendar
        self.saveURL = saveURL ?? Self.defaultSaveURL()

        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601

        if saveURL == nil {
            load()
        }

        if self.projects.isEmpty {
            self.projects = [
                StudyProject(name: "英语", colorName: ProjectColor.blue.rawValue),
                StudyProject(name: "算法", colorName: ProjectColor.green.rawValue),
                StudyProject(name: "iOS", colorName: ProjectColor.orange.rawValue)
            ]
            persist()
        }
    }

    func addProject(named name: String, color: ProjectColor) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        projects.insert(
            StudyProject(name: trimmedName, colorName: color.rawValue),
            at: 0
        )
        persist()
    }

    func updateProject(id: UUID, name: String, color: ProjectColor) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        guard let index = projects.firstIndex(where: { $0.id == id }) else { return }

        projects[index].name = trimmedName
        projects[index].colorName = color.rawValue
        persist()
    }

    func deleteProject(_ projectID: UUID) {
        if activeSession?.projectID == projectID {
            activeSession = nil
        }
        projects.removeAll { $0.id == projectID }
        sessions.removeAll { $0.projectID == projectID }
        persist()
    }

    func setDailyGoalMinutes(_ minutes: Int) {
        dailyGoalMinutes = max(15, min(minutes, 600))
        persist()
    }

    func startSession(for projectID: UUID, at startDate: Date = .now) {
        guard activeSession == nil else { return }
        activeSession = ActiveSession(projectID: projectID, startedAt: startDate)
        persist()
    }

    func stopActiveSession(at endDate: Date = .now) {
        guard let activeSession else { return }
        guard endDate > activeSession.startedAt else { return }

        sessions.insert(
            StudySession(
                projectID: activeSession.projectID,
                startedAt: activeSession.startedAt,
                endedAt: endDate
            ),
            at: 0
        )
        self.activeSession = nil
        persist()
    }

    func deleteSessions(at offsets: IndexSet, from source: [StudySession]) {
        let idsToDelete = Set(offsets.map { source[$0].id })
        sessions.removeAll { idsToDelete.contains($0.id) }
        persist()
    }

    func project(for id: UUID) -> StudyProject? {
        projects.first { $0.id == id }
    }

    func durationToday(for projectID: UUID? = nil, now: Date = .now) -> TimeInterval {
        let startOfDay = calendar.startOfDay(for: now)
        let todaysSessions = sessions.filter { session in
            session.startedAt >= startOfDay && (projectID == nil || session.projectID == projectID)
        }
        let finishedDuration = todaysSessions.reduce(0) { $0 + $1.duration }
        let activeDuration = activeDurationIfMatching(projectID: projectID, now: now, intervalStart: startOfDay)
        return finishedDuration + activeDuration
    }

    func durationThisWeek(for projectID: UUID? = nil, now: Date = .now) -> TimeInterval {
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        let weekSessions = sessions.filter { session in
            session.startedAt >= weekStart && (projectID == nil || session.projectID == projectID)
        }
        let finishedDuration = weekSessions.reduce(0) { $0 + $1.duration }
        let activeDuration = activeDurationIfMatching(projectID: projectID, now: now, intervalStart: weekStart)
        return finishedDuration + activeDuration
    }

    func totalDuration(for projectID: UUID) -> TimeInterval {
        let finishedDuration = sessions
            .filter { $0.projectID == projectID }
            .reduce(0) { $0 + $1.duration }

        let activeDuration = activeDurationIfMatching(projectID: projectID, now: .now, intervalStart: .distantPast)
        return finishedDuration + activeDuration
    }

    func dailyGoalProgress(now: Date = .now) -> Double {
        guard dailyGoalMinutes > 0 else { return 0 }
        return min(durationToday(now: now) / Double(dailyGoalMinutes * 60), 1)
    }

    func lastSevenDays(now: Date = .now) -> [DailyDurationPoint] {
        let today = calendar.startOfDay(for: now)

        return (0..<7).compactMap { offset -> DailyDurationPoint? in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            let nextDate = calendar.date(byAdding: .day, value: 1, to: date) ?? date

            let finishedDuration = sessions
                .filter { $0.startedAt >= date && $0.startedAt < nextDate }
                .reduce(0) { $0 + $1.duration }

            let activeDuration: TimeInterval
            if let activeSession, activeSession.startedAt >= date && activeSession.startedAt < nextDate {
                activeDuration = now.timeIntervalSince(activeSession.startedAt)
            } else {
                activeDuration = 0
            }

            return DailyDurationPoint(date: date, duration: finishedDuration + activeDuration)
        }
        .reversed()
    }

    func groupedSessions() -> [(date: Date, sessions: [StudySession])] {
        let grouped = Dictionary(grouping: sessions) { session in
            calendar.startOfDay(for: session.startedAt)
        }

        return grouped
            .map { (date: $0.key, sessions: $0.value.sorted { $0.startedAt > $1.startedAt }) }
            .sorted { $0.date > $1.date }
    }

    private func activeDurationIfMatching(projectID: UUID?, now: Date, intervalStart: Date) -> TimeInterval {
        guard let activeSession else { return 0 }
        guard activeSession.startedAt >= intervalStart else { return 0 }
        guard projectID == nil || activeSession.projectID == projectID else { return 0 }
        return now.timeIntervalSince(activeSession.startedAt)
    }

    private func load() {
        guard let data = try? Data(contentsOf: saveURL) else { return }
        guard let snapshot = try? decoder.decode(StudySnapshot.self, from: data) else { return }

        projects = snapshot.projects
        sessions = snapshot.sessions.sorted { $0.startedAt > $1.startedAt }
        activeSession = snapshot.activeSession
        dailyGoalMinutes = snapshot.dailyGoalMinutes
    }

    private func persist() {
        let snapshot = StudySnapshot(
            projects: projects,
            sessions: sessions,
            activeSession: activeSession,
            dailyGoalMinutes: dailyGoalMinutes
        )

        do {
            let folderURL = saveURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
            let data = try encoder.encode(snapshot)
            try data.write(to: saveURL, options: [.atomic])
        } catch {
            assertionFailure("Failed to persist study data: \(error)")
        }
    }

    private static func defaultSaveURL() -> URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return baseURL
            .appendingPathComponent("StudyTimer", isDirectory: true)
            .appendingPathComponent("study-data.json")
    }
}
