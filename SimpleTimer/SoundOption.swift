import AVFoundation
import UserNotifications

enum SoundOption: String, CaseIterable, Identifiable {
    case alarm = "Alarm"
    case anticipate = "Anticipate"
    case bloom = "Bloom"
    case calypso = "Calypso"
    case chime = "Chime"
    case glass = "Glass"
    case horn = "Horn"
    case ladder = "Ladder"
    case minuet = "Minuet"
    case noir = "Noir"
    case sherwood = "Sherwood"
    case spell = "Spell"
    case suspense = "Suspense"
    case telegraph = "Telegraph"
    case tiptoes = "Tiptoes"
    case triTone = "Tri-tone"

    var id: String { rawValue }

    var fileName: String {
        switch self {
        case .alarm: return "alarm"
        case .anticipate: return "Anticipate"
        case .bloom: return "Bloom"
        case .calypso: return "Calypso"
        case .chime: return "Choo_Choo"
        case .glass: return "Fanfare"
        case .horn: return "Descent"
        case .ladder: return "Ladder"
        case .minuet: return "Minuet"
        case .noir: return "Noir"
        case .sherwood: return "Sherwood_Forest"
        case .spell: return "Spell"
        case .suspense: return "Suspense"
        case .telegraph: return "Telegraph"
        case .tiptoes: return "Tiptoes"
        case .triTone: return "News_Flash"
        }
    }

    var url: URL? {
        Bundle.main.url(forResource: fileName, withExtension: "caf")
    }

    var notificationSound: UNNotificationSound {
        UNNotificationSound(named: UNNotificationSoundName("\(fileName).caf"))
    }

    func play() {
        try? AVAudioSession.sharedInstance().setCategory(.playback)
        try? AVAudioSession.sharedInstance().setActive(true)
        guard let url else { return }
        TimerSection.audioPlayer = try? AVAudioPlayer(contentsOf: url)
        TimerSection.audioPlayer?.play()
    }
}
