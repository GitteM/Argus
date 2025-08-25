import CoreFoundation

enum Spacing {
    /// 1pt
    case xs
    /// 2pt
    case xs2
    /// 3pt
    case xs3
    /// 4pt
    case s
    /// 6pt
    case s2
    /// 8pt
    case s3
    /// 12pt
    case s4
    /// 16pt
    case m
    /// 20pt
    case m2
    /// 24pt
    case m3
    /// 28pt
    case l
    /// 32pt
    case l2
    /// 36pt
    case l3
    /// 40pt
    case l4
    /// 44pt
    case xl
    /// 48pt
    case xl2
    /// 56pt
    case xl3
    /// 64pt
    case xl4
    /// 72pt
    case section
    /// 80pt
    case section2
    /// 96pt
    case section3

    var value: CGFloat {
        switch self {
        case .xs: 1
        case .xs2: 2
        case .xs3: 3
        case .s: 4
        case .s2: 6
        case .s3: 8
        case .s4: 12
        case .m: 16
        case .m2: 20
        case .m3: 24
        case .l: 28
        case .l2: 32
        case .l3: 36
        case .l4: 40
        case .xl: 44
        case .xl2: 48
        case .xl3: 56
        case .xl4: 64
        case .section: 72
        case .section2: 80
        case .section3: 96
        }
    }
}
