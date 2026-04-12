//
//  ContentView.swift
//  XcodeSandbox
//
//  Created by Codex on 4/12/26.
//

import SwiftUI

struct ContentView: View {
    @State private var store = StudyStore()

    var body: some View {
        TabView {
            Tab("今天", systemImage: "play.circle.fill") {
                NavigationStack {
                    TodayView(store: store)
                }
            }

            Tab("历史", systemImage: "clock.arrow.circlepath") {
                NavigationStack {
                    HistoryView(store: store)
                }
            }

            Tab("统计", systemImage: "chart.bar.fill") {
                NavigationStack {
                    StatisticsView(store: store)
                }
            }
        }
    }
}

private struct TodayView: View {
    let store: StudyStore

    @State private var newProjectName = ""
    @State private var selectedColor: ProjectColor = .blue
    @State private var isPresentingAddProject = false

    var body: some View {
        List {
            todaySummarySection
            activeSessionSection
            projectSection
        }
        .navigationTitle("学习计时")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isPresentingAddProject = true
                } label: {
                    Label("添加项目", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $isPresentingAddProject) {
            AddProjectView(
                name: $newProjectName,
                selectedColor: $selectedColor
            ) {
                store.addProject(named: newProjectName, color: selectedColor)
                newProjectName = ""
                selectedColor = .blue
                isPresentingAddProject = false
            }
        }
    }

    private var todaySummarySection: some View {
        Section("今日概览") {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                VStack(alignment: .leading, spacing: 12) {
                    summaryRow(
                        title: "今天累计",
                        value: context.date.formattedDuration(store.durationToday(now: context.date))
                    )
                    summaryRow(
                        title: "本周累计",
                        value: context.date.formattedDuration(store.durationThisWeek(now: context.date))
                    )
                }
                .padding(.vertical, 4)
            }
        }
    }

    private var activeSessionSection: some View {
        Section("当前状态") {
            if let activeSession = store.activeSession,
               let project = store.project(for: activeSession.projectID) {
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    VStack(alignment: .leading, spacing: 12) {
                        Label(project.name, systemImage: "book.fill")
                            .font(.headline)
                            .foregroundStyle(project.color)

                        summaryRow(
                            title: "已专注",
                            value: context.date.formattedDuration(
                                context.date.timeIntervalSince(activeSession.startedAt)
                            )
                        )

                        Button("结束本次学习") {
                            store.stopActiveSession(at: .now)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(.vertical, 4)
                }
            } else {
                Text("还没有开始学习。选一个项目，点一下就开始计时。")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var projectSection: some View {
        Section("学习项目") {
            if store.projects.isEmpty {
                ContentUnavailableView(
                    "还没有项目",
                    systemImage: "square.stack.3d.up.slash",
                    description: Text("先添加一个学习项目，再开始计时。")
                )
            } else {
                ForEach(store.projects) { project in
                    ProjectRow(
                        project: project,
                        isRunning: store.activeSession?.projectID == project.id,
                        todayDuration: store.durationToday(for: project.id)
                    ) {
                        if store.activeSession?.projectID == project.id {
                            store.stopActiveSession(at: .now)
                        } else if store.activeSession == nil {
                            store.startSession(for: project.id, at: .now)
                        }
                    }
                }
            }
        }
    }

    private func summaryRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.title3.weight(.semibold))
                .monospacedDigit()
        }
    }
}

private struct HistoryView: View {
    let store: StudyStore

    var body: some View {
        List {
            ForEach(store.groupedSessions(), id: \.date) { group in
                Section(group.date.formatted(date: .abbreviated, time: .omitted)) {
                    ForEach(group.sessions) { session in
                        if let project = store.project(for: session.projectID) {
                            SessionRow(project: project, session: session)
                        }
                    }
                    .onDelete { offsets in
                        store.deleteSessions(at: offsets, from: group.sessions)
                    }
                }
            }
        }
        .navigationTitle("历史记录")
        .overlay {
            if store.sessions.isEmpty {
                ContentUnavailableView(
                    "还没有历史记录",
                    systemImage: "clock.badge.xmark",
                    description: Text("完成一次学习后，这里会自动出现记录。")
                )
            }
        }
    }
}

private struct StatisticsView: View {
    let store: StudyStore

    var body: some View {
        List {
            Section("总览") {
                statisticRow(title: "累计项目数", value: "\(store.projects.count)")
                statisticRow(title: "累计学习次数", value: "\(store.sessions.count)")
                statisticRow(title: "累计学习时长", value: Date.now.formattedDuration(totalDuration))
            }

            Section("项目排行") {
                ForEach(rankedProjects) { item in
                    HStack {
                        Circle()
                            .fill(item.project.color.gradient)
                            .frame(width: 12, height: 12)
                        Text(item.project.name)
                        Spacer()
                        Text(Date.now.formattedDuration(item.duration))
                            .monospacedDigit()
                    }
                }
            }
        }
        .navigationTitle("统计")
    }

    private var totalDuration: TimeInterval {
        store.sessions.reduce(0) { $0 + $1.duration } +
        (store.activeSession.map { Date.now.timeIntervalSince($0.startedAt) } ?? 0)
    }

    private var rankedProjects: [ProjectStatistic] {
        store.projects
            .map { ProjectStatistic(project: $0, duration: store.totalDuration(for: $0.id)) }
            .sorted { $0.duration > $1.duration }
    }

    private func statisticRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
                .monospacedDigit()
        }
    }
}

private struct ProjectStatistic: Identifiable {
    let project: StudyProject
    let duration: TimeInterval

    var id: UUID { project.id }
}

private struct ProjectRow: View {
    let project: StudyProject
    let isRunning: Bool
    let todayDuration: TimeInterval
    let action: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 12)
                .fill(project.color.gradient)
                .frame(width: 44, height: 44)
                .overlay {
                    Image(systemName: isRunning ? "pause.fill" : "play.fill")
                        .foregroundStyle(.white)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(project.name)
                    .font(.headline)
                Text("今天 \(Date.now.formattedDuration(todayDuration))")
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }

            Spacer()

            Button(isRunning ? "停止" : "开始", action: action)
                .buttonStyle(.borderedProminent)
                .tint(isRunning ? .red : project.color)
        }
        .padding(.vertical, 4)
    }
}

private struct SessionRow: View {
    let project: StudyProject
    let session: StudySession

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 10)
                .fill(project.color.gradient)
                .frame(width: 12)

            VStack(alignment: .leading, spacing: 4) {
                Text(project.name)
                    .font(.headline)
                Text(
                    "\(session.startedAt.formatted(date: .omitted, time: .shortened)) - \(session.endedAt.formatted(date: .omitted, time: .shortened))"
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }

            Spacer()

            Text(Date.now.formattedDuration(session.duration))
                .monospacedDigit()
        }
        .padding(.vertical, 4)
    }
}

private struct AddProjectView: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var name: String
    @Binding var selectedColor: ProjectColor
    let onSave: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("项目名称") {
                    TextField("例如：英语阅读", text: $name)
                }

                Section("颜色") {
                    Picker("颜色", selection: $selectedColor) {
                        ForEach(ProjectColor.allCases) { color in
                            Label(color.rawValue.capitalized, systemImage: "circle.fill")
                                .foregroundStyle(color.swiftUIColor)
                                .tag(color)
                        }
                    }
                    .pickerStyle(.inline)
                }
            }
            .navigationTitle("添加项目")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存") {
                        onSave()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

private extension StudyProject {
    var color: Color {
        ProjectColor(rawValue: colorName)?.swiftUIColor ?? .blue
    }
}

private extension ProjectColor {
    var swiftUIColor: Color {
        switch self {
        case .blue: .blue
        case .green: .green
        case .orange: .orange
        case .pink: .pink
        case .red: .red
        case .teal: .teal
        }
    }
}

private extension Date {
    func formattedDuration(_ duration: TimeInterval) -> String {
        let roundedDuration = max(0, Int(duration.rounded()))
        let hours = roundedDuration / 3600
        let minutes = (roundedDuration % 3600) / 60
        let seconds = roundedDuration % 60

        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

#Preview("Main") {
    ContentView()
}
