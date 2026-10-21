import SwiftUI

struct DailyWheelView: View {
    @EnvironmentObject private var player: PlayerStore
    @Environment(\.dismiss) private var dismiss

    @State private var rotation: Double = 0
    @State private var spinning = false
    @State private var prize: Int?
    @State private var now = Date()
    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private let segments = GameConfig.wheelSegments

    var body: some View {
        ZStack {
            LobbyBackground()
            HStack(spacing: 30) {
                wheel
                    .frame(width: 300, height: 300)

                VStack(spacing: 14) {
                    Text("DAILY BONUS")
                        .font(.system(size: 34, weight: .black, design: .rounded))
                        .foregroundStyle(Theme.gold)
                    Text("Spin once every 24 hours to win\n\(segments.map(\.amount).min()!.chipString) – \(segments.map(\.amount).max()!.chipString) free chips!")
                        .font(.system(size: 14, weight: .semibold))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white.opacity(0.85))

                    if let prize {
                        VStack(spacing: 4) {
                            Text("YOU WON").font(.system(size: 14, weight: .heavy)).foregroundStyle(.white)
                            Text(prize.chipString)
                                .font(.system(size: 36, weight: .black, design: .rounded))
                                .foregroundStyle(Theme.gold)
                                .shadow(color: Theme.gold.opacity(0.7), radius: 10)
                        }
                        .transition(.scale.combined(with: .opacity))
                        Button("COLLECT") { dismiss() }
                            .buttonStyle(GlossyButtonStyle(colors: [Color(hex: "7CD62E"), Color(hex: "2E8B12")], height: 50))
                            .frame(width: 240)
                    } else if player.canSpinWheel(now: now) {
                        Button(spinning ? "GOOD LUCK!" : "SPIN") { spin() }
                            .buttonStyle(GlossyButtonStyle(colors: [Color(hex: "D158F0"), Color(hex: "8E1FB5")], height: 56))
                            .frame(width: 240)
                            .disabled(spinning)
                    } else {
                        VStack(spacing: 4) {
                            Text("NEXT FREE SPIN IN").font(.system(size: 13, weight: .heavy)).foregroundStyle(.white.opacity(0.8))
                            Text(countdown)
                                .font(.system(size: 30, weight: .black, design: .monospaced))
                                .foregroundStyle(.white)
                        }
                        Button("CLOSE") { dismiss() }
                            .buttonStyle(GlossyButtonStyle(colors: [Color(hex: "607D8B"), Color(hex: "37474F")], height: 46))
                            .frame(width: 200)
                    }
                }
                .frame(width: 300)
            }
        }
        .onReceive(ticker) { now = $0 }
        .interactiveDismissDisabled(spinning)
    }

    private var countdown: String {
        let r = max(0, Int(player.nextWheelSpin.timeIntervalSince(now)))
        return String(format: "%02d:%02d:%02d", r / 3600, (r % 3600) / 60, r % 60)
    }

    private func spin() {
        guard !spinning, player.canSpinWheel() else { return }
        spinning = true
        let index = WheelSpinner.pickIndex()
        let target = WheelSpinner.targetRotation(for: index, segmentCount: segments.count, currentRotation: rotation)
        Haptics.tap(player.hapticsOn)
        withAnimation(.timingCurve(0.1, 0.7, 0.1, 1, duration: 5)) {
            rotation = target
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.1) {
            let amount = segments[index].amount
            player.recordWheelSpin(prize: amount)
            Haptics.win(player.hapticsOn)
            withAnimation(.spring) { prize = amount }
            spinning = false
        }
    }

    // MARK: Wheel drawing

    private var wheel: some View {
        ZStack {
            ZStack {
                ForEach(Array(segments.enumerated()), id: \.offset) { i, seg in
                    WheelSlice(index: i, count: segments.count)
                        .fill(Color(hex: seg.colorHex))
                    WheelSlice(index: i, count: segments.count)
                        .stroke(.white.opacity(0.8), lineWidth: 2)
                    Text(seg.amount.shortChipString)
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.5), radius: 1, y: 1)
                        .rotationEffect(.degrees(90))
                        .offset(y: -100)
                        .rotationEffect(.degrees(sliceCenter(i)))
                }
            }
            .rotationEffect(.degrees(rotation))

            Circle().strokeBorder(
                LinearGradient(colors: [Theme.gold, Theme.goldDark], startPoint: .top, endPoint: .bottom),
                lineWidth: 10)
            Circle()
                .fill(RadialGradient(colors: [Theme.gold, Theme.goldDark], center: .center, startRadius: 2, endRadius: 30))
                .frame(width: 56, height: 56)
                .overlay(Text("SPIN").font(.system(size: 13, weight: .black)).foregroundStyle(Color(hex: "4A2A00")))

            // Pointer at the top
            Triangle()
                .fill(.white)
                .frame(width: 28, height: 30)
                .shadow(radius: 3)
                .rotationEffect(.degrees(180))
                .offset(y: -150)
        }
    }

    private func sliceCenter(_ i: Int) -> Double {
        let slice = 360.0 / Double(segments.count)
        return slice * Double(i) + slice / 2
    }
}

/// A wedge starting at the top (12 o'clock) and running clockwise.
struct WheelSlice: Shape {
    let index: Int
    let count: Int

    func path(in rect: CGRect) -> Path {
        let slice = 360.0 / Double(count)
        let start = Angle.degrees(-90 + slice * Double(index))
        let end = Angle.degrees(-90 + slice * Double(index + 1))
        let center = CGPoint(x: rect.midX, y: rect.midY)
        var p = Path()
        p.move(to: center)
        p.addArc(center: center, radius: min(rect.width, rect.height) / 2, startAngle: start, endAngle: end, clockwise: false)
        p.closeSubpath()
        return p
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}
