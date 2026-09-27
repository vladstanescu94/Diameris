import Testing
@testable import SharedUI

@MainActor
struct ProgressRingTests {

    /// The fill, the label and the VoiceOver value all read `progress`, so an over-funded goal
    /// must show a full ring and "100%", never "140%".
    @Test(arguments: zip([1.4, -0.2, 0.45], [1.0, 0, 0.45]))
    func `Progress is clamped to 0–100%`(input: Double, expected: Double) {
        #expect(ProgressRing(progress: input).progress == expected)
        #expect(ProgressRing.large(progress: input).progress == expected)
    }
}
