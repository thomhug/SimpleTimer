import Foundation
import AVFoundation

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

    init(id: Int) {
        self.id = id
        let saved = UserDefaults.standard.object(forKey: "timer_\(id)_seconds") as? Int ?? [45, 60, 0][id]
        self.configuredSeconds = saved
        self.remainingSeconds = Double(saved)

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
    }

    func stop() {
        guard isRunning else { return }
        isRunning = false
        cancelTimer()
    }

    func reset() {
        let wasRunning = isRunning
        if isStopwatch && elapsedSeconds > 0 {
            TimerLog.shared.log(seconds: Int(elapsedSeconds))
        }
        if wasRunning {
            isRunning = false
            cancelTimer()
        }
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
        TimerLog.shared.log(seconds: configuredSeconds)

        if loopEnabled {
            cancelTimer()
            resetTime()
            scheduleTimer()
        } else {
            isRunning = false
            cancelTimer()
            resetTime()
        }
    }

    static var audioPlayer: AVAudioPlayer?
}
