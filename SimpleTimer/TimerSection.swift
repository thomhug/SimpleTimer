import Foundation
import AVFoundation
import UserNotifications
import ActivityKit
import UIKit

@Observable
class TimerSection: Identifiable {
    let id: Int
    var configuredSeconds: Int {
        didSet {
            UserDefaults.standard.set(configuredSeconds, forKey: "timer_\(id)_seconds")
            cancelTimer()
            resetTime()
        }
    }
    var isRunning: Bool = false
    var remainingSeconds: Double = 0
    var elapsedSeconds: Double = 0

    var name: String {
        didSet {
            UserDefaults.standard.set(name, forKey: "timer_\(id)_name")
        }
    }

    var selectedSound: SoundOption {
        didSet {
            UserDefaults.standard.set(selectedSound.rawValue, forKey: "timer_\(id)_sound")
        }
    }

    var loopEnabled: Bool {
        didSet {
            UserDefaults.standard.set(loopEnabled, forKey: "timer_\(id)_loop")
        }
    }

    var isStopwatch: Bool { configuredSeconds == 0 }

    var displayTime: String {
        let total: Int
        if isStopwatch {
            total = Int(elapsedSeconds)
        } else {
            total = Int(ceil(remainingSeconds))
        }
        let minutes = total / 60
        let seconds = total % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private var timer: Timer?
    private var currentActivity: Activity<TimerActivityAttributes>?

    init(id: Int) {
        self.id = id
        let saved = UserDefaults.standard.object(forKey: "timer_\(id)_seconds") as? Int ?? [45, 60, 0][id]
        self.configuredSeconds = saved
        self.remainingSeconds = Double(saved)

        let defaultNames = [
            String(localized: "Timer 1"),
            String(localized: "Timer 2"),
            String(localized: "Timer 3")
        ]
        self.name = UserDefaults.standard.string(forKey: "timer_\(id)_name") ?? defaultNames[id]

        if let soundName = UserDefaults.standard.string(forKey: "timer_\(id)_sound"),
           let sound = SoundOption(rawValue: soundName) {
            self.selectedSound = sound
        } else {
            self.selectedSound = .alarm
        }
        self.loopEnabled = UserDefaults.standard.bool(forKey: "timer_\(id)_loop")
    }

    func toggle() {
        if isRunning {
            stop()
        } else {
            start()
        }
    }

    func start() {
        guard !isRunning else { return }

        if !isStopwatch && remainingSeconds <= 0 {
            resetTime()
        }

        isRunning = true
        scheduleTimer()

        if !isStopwatch {
            scheduleNotification()
            startLiveActivity()
        }
    }

    func stop() {
        guard isRunning else { return }
        isRunning = false
        cancelTimer()
        cancelNotification()
        endLiveActivity()
    }

    func reset() {
        let wasRunning = isRunning
        if isStopwatch && elapsedSeconds > 0 {
            TimerLog.shared.log(seconds: Int(elapsedSeconds), timerName: name)
        }
        if wasRunning {
            isRunning = false
            cancelTimer()
        }
        cancelNotification()
        endLiveActivity()
        resetTime()
    }

    // MARK: - Internal helpers

    private func cancelTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func resetTime() {
        remainingSeconds = Double(configuredSeconds)
        elapsedSeconds = 0
    }

    private func scheduleTimer() {
        let startDate = Date()
        let startRemaining = remainingSeconds
        let startElapsed = elapsedSeconds

        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self else { return }
            let elapsed = Date().timeIntervalSince(startDate)

            if self.isStopwatch {
                self.elapsedSeconds = startElapsed + elapsed
            } else {
                self.remainingSeconds = max(0, startRemaining - elapsed)
                if self.remainingSeconds <= 0 {
                    self.timerFinished()
                }
            }
        }
    }

    private func timerFinished() {
        selectedSound.play()
        TimerLog.shared.log(seconds: configuredSeconds, timerName: name)
        cancelNotification()

        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        if loopEnabled {
            cancelTimer()
            endLiveActivity()
            resetTime()
            scheduleTimer()
            scheduleNotification()
            startLiveActivity()
        } else {
            isRunning = false
            cancelTimer()
            endLiveActivity()
            resetTime()
        }
    }

    // MARK: - Notifications

    private var notificationID: String { "timer-\(id)" }

    private func scheduleNotification() {
        let seconds = remainingSeconds
        let sound = selectedSound.notificationSound
        let timerLabel = name
        let notifID = notificationID

        guard seconds > 0 else { return }

        let content = UNMutableNotificationContent()
        content.title = String(localized: "Timer finished")
        content.body = timerLabel
        content.sound = sound

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: seconds,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: notifID,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    private func cancelNotification() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [notificationID])
        center.removeDeliveredNotifications(withIdentifiers: [notificationID])
    }

    // MARK: - Live Activity

    private func startLiveActivity() {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let attributes = TimerActivityAttributes(
            timerName: name
        )
        let endDate = Date().addingTimeInterval(remainingSeconds)
        let state = TimerActivityAttributes.ContentState(endDate: endDate)

        do {
            currentActivity = try Activity.request(
                attributes: attributes,
                content: .init(state: state, staleDate: endDate),
                pushType: nil
            )
        } catch {
            print("Failed to start Live Activity: \(error)")
        }
    }

    private func endLiveActivity() {
        guard let activity = currentActivity else { return }
        let state = TimerActivityAttributes.ContentState(endDate: .now)
        Task {
            await activity.end(
                .init(state: state, staleDate: nil),
                dismissalPolicy: .immediate
            )
        }
        currentActivity = nil
    }

    static var audioPlayer: AVAudioPlayer?
}
