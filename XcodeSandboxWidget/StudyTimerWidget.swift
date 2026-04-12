//
//  StudyTimerWidget.swift
//  XcodeSandboxWidget
//
//  Created by Codex on 4/12/26.
//

import SwiftUI
import WidgetKit

struct StudyTimerEntry: TimelineEntry {
    let date: Date
    let summary: WidgetSnapshotSummary

    var progress: Double {
        guard summary.goalMinutes > 0 else { return 0 }
        return min(summary.todayDuration / Double(summary.goalMinutes * 60), 1)
    }
}

struct StudyTimerProvider: TimelineProvider {
    func placeholder(in context: Context) -> StudyTimerEntry {
        StudyTimerEntry(
            date: .now,
            summary: WidgetSnapshotSummary(todayDuration: 60 * 45, goalMinutes: 120, activeProjectName: "iOS")
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (StudyTimerEntry) -> Void) {
        completion(StudyTimerEntry(date: .now, summary: WidgetSharedLoader.loadSummary()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StudyTimerEntry>) -> Void) {
        let now = Date()
        let entry = StudyTimerEntry(date: now, summary: WidgetSharedLoader.loadSummary(now: now))
        let refreshDate = Calendar.current.date(byAdding: .minute, value: 15, to: now) ?? now.addingTimeInterval(900)
        completion(Timeline(entries: [entry], policy: .after(refreshDate)))
    }
}

struct StudyTimerWidgetEntryView: View {
    var entry: StudyTimerProvider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("今天")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(entry.summary.goalMinutes)m")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            Text(entry.date.formattedDuration(entry.summary.todayDuration))
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .monospacedDigit()

            ProgressView(value: entry.progress)
                .tint(entry.progress >= 1 ? .green : .orange)

            if let activeProjectName = entry.summary.activeProjectName {
                Label(activeProjectName, systemImage: "book.fill")
                    .font(.footnote.weight(.medium))
                    .lineLimit(1)
            } else {
                Text("未开始学习")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct StudyTimerWidget: Widget {
    let kind = "StudyTimerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StudyTimerProvider()) { entry in
            StudyTimerWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("学习进度")
        .description("在桌面查看今日学习时长和目标完成度。")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

private extension Date {
    func formattedDuration(_ duration: TimeInterval) -> String {
        let roundedDuration = max(0, Int(duration.rounded()))
        let hours = roundedDuration / 3600
        let minutes = (roundedDuration % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}

#Preview(as: .systemSmall) {
    StudyTimerWidget()
} timeline: {
    StudyTimerEntry(
        date: .now,
        summary: WidgetSnapshotSummary(todayDuration: 60 * 72, goalMinutes: 120, activeProjectName: "iOS")
    )
}
