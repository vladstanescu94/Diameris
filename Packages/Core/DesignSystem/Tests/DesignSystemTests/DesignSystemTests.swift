import Testing
import SwiftUI
import UIKit
@testable import DesignSystem

struct ColorTests {

    @Test(arguments: [
        (UInt(0xD946EF), 0xD9, 0x46, 0xEF),
        (UInt(0x000000), 0x00, 0x00, 0x00),
        (UInt(0xFFFFFF), 0xFF, 0xFF, 0xFF)
    ])
    func `Hex initializer splits RGB channels`(hex: UInt, red: Int, green: Int, blue: Int) {
        #expect(components(of: UIColor(Color(hex: hex))) == [red, green, blue])
    }

    @Test func `Adaptive color resolves per interface style`() {
        let color = UIColor(DiamerisColors.accentPrimary)
        let light = color.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
        let dark = color.resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark))

        #expect(components(of: light) == [0xA2, 0x1C, 0xAF])
        #expect(components(of: dark) == [0xE8, 0x79, 0xF9])
    }

    /// Accents are used as text and icon tint, so the light values must meet WCAG AA (4.5:1)
    /// on both white and the grouped background; dark values against black and elevated gray.
    @Test(arguments: [DiamerisColors.accentPrimary, DiamerisColors.accentSecondary])
    func `Accents meet AA text contrast in both appearances`(accent: Color) {
        let color = UIColor(accent)
        let light = color.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
        let dark = color.resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark))

        #expect(contrast(light, .white) >= Self.minimumTextContrast)
        #expect(contrast(light, UIColor(Color(hex: 0xF2F2F7))) >= Self.minimumTextContrast)
        #expect(contrast(dark, .black) >= Self.minimumTextContrast)
        #expect(contrast(dark, UIColor(Color(hex: 0x1C1C1E))) >= Self.minimumTextContrast)
    }

    /// Prominent buttons put white labels on this fill, in both appearances.
    @Test(arguments: [UIUserInterfaceStyle.light, .dark])
    func `White text on the prominent fill meets AA`(style: UIUserInterfaceStyle) {
        let fill = UIColor(DiamerisColors.accentPrimaryFill)
            .resolvedColor(with: UITraitCollection(userInterfaceStyle: style))
        #expect(contrast(fill, .white) >= Self.minimumTextContrast)
    }

    private static let minimumTextContrast = 4.5

    private func contrast(_ first: UIColor, _ second: UIColor) -> Double {
        let (lighter, darker) = [luminance(first), luminance(second)].sorted(by: >).pair
        return (lighter + 0.05) / (darker + 0.05)
    }

    private func luminance(_ color: UIColor) -> Double {
        let channels = components(of: color).map { value -> Double in
            let channel = Double(value) / 255
            return channel <= 0.03928 ? channel / 12.92 : pow((channel + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * channels[0] + 0.7152 * channels[1] + 0.0722 * channels[2]
    }

    private func components(of color: UIColor) -> [Int] {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return [red, green, blue].map { Int(($0 * 255).rounded()) }
    }
}

private extension Array where Element == Double {
    var pair: (Double, Double) { (self[0], self[1]) }
}
