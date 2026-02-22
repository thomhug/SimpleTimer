import AVFoundation

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

    private var fileName: String {
        switch self {
        case .alarm: return "alarm"
        case .anticipate: return "Anticipate.caf"
        case .bloom: return "Bloom.caf"
        case .calypso: return "Calypso.caf"
        case .chime: return "Chime.caf"
        case .glass: return "Glass.caf"
        case .horn: return "Horn.caf"
        case .ladder: return "Ladder.caf"
        case .minuet: return "Minuet.caf"
        case .noir: return "Noir.caf"
        case .sherwood: return "Sherwood_Forest.caf"
        case .spell: return "Spell.caf"
        case .suspense: return "Suspense.caf"
        case .telegraph: return "Telegraph.caf"
        case .tiptoes: return "Tiptoes.caf"
        case .triTone: return "tri-tone_new.caf"
        }
    }

    private var url: URL? {
        if self == .alarm {
            return Bundle.main.url(forResource: "alarm", withExtension: "caf")
                ?? URL(fileURLWithPath: "/System/Library/Audio/UISounds/alarm.caf")
        }
        return URL(fileURLWithPath: "/System/Library/Audio/UISounds/\(fileName)")
    }

    func play() {
        try? AVAudioSession.sharedInstance().setCategory(.playback)
        try? AVAudioSession.sharedInstance().setActive(true)
        guard let url else { return }
        TimerSection.audioPlayer = try? AVAudioPlayer(contentsOf: url)
        TimerSection.audioPlayer?.play()
    }
}
