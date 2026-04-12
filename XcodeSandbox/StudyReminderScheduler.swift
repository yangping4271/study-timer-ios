//
//  StudyReminderScheduler.swift
//  XcodeSandbox
//
//  Created by Codex on 4/12/26.
//

import Foundation
import UserNotifications

enum StudyReminderScheduler {
    static let reminderIdentifier = "daily-study-reminder"

    static func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            return false
        }
    }

    static func syncReminder(for store: StudyStore) async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [reminderIdentifier])

        guard store.reminderEnabled else { return }

        let content = UNMutableNotificationContent()
        content.title = "开始今天的学习"
        content.body = "打开 Study Timer，继续推进你的今日目标。"
        content.sound = .default

        var components = DateComponents()
        components.hour = store.reminderHour
        components.minute = store.reminderMinute

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: reminderIdentifier, content: content, trigger: trigger)

        try? await center.add(request)
    }
}
