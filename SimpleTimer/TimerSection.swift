import Foundation
import AVFoundation

@Observable
class TimerSection: Identifiable {
    let id: Int
    var configuredSeconds: Int {
        didSet {
            UserDefaults.standard.set(configuredSeconds, forKey: "timer_\(id)_seconds")
            reset()
        }
    }
    var isRunning: Bool = false
    var remainingSeconds: Double = 0
    var elapsedSeconds: Double = 0

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
        self.configuredSeconds = UserDefaults.standard.object(forKey: "timer_\(id)_seconds") as? Int ?? [45, 60, 0][id]
        self.remainingSeconds = Double(self.configuredSeconds)
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
            reset()
        }

        isRunning = true
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
                    self.playBeep()
                    self.reset()
                }
            }
        }
    }

    func stop() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }

    func reset() {
        stop()
        remainingSeconds = Double(configuredSeconds)
        elapsedSeconds = 0
    }

    private static var audioPlayer: AVAudioPlayer?

    private func playBeep() {
        try? AVAudioSession.sharedInstance().setCategory(.playback)
        try? AVAudioSession.sharedInstance().setActive(true)
        if let url = Bundle.main.url(forResource: "alarm", withExtension: "caf")
            ?? URL(fileURLWithPath: "/System/Library/Audio/UISounds/alarm.caf") as URL? {
            Self.audioPlayer = try? AVAudioPlayer(contentsOf: url)
            Self.audioPlayer?.play()
        }
    }
}
