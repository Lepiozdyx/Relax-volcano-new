import SwiftUI

struct BreakScreenView: View {
    @StateObject private var viewModel = BreakTimerViewModel()
    @AppStorage(VolcanoStorageKey.dayMarksJSON) private var dayMarksJSON: String = "{}"
    @AppStorage(VolcanoStorageKey.timerSound) private var selectedTimerSoundRaw: String = TimerSound.rain.rawValue

    @State private var selectedDuration = 15 * 60

    private let backgroundColor = Color.black.opacity(0.6)
    private let cardColor = Color(red: 28 / 255, green: 28 / 255, blue: 30 / 255)
    private let activeRed = Color(red: 1.0, green: 59 / 255, blue: 48 / 255)
    private let accentYellow = Color(red: 1.0, green: 215 / 255, blue: 0)
    private let controlBg = Color(red: 30 / 255, green: 41 / 255, blue: 57 / 255)

    private var isCompactPhone: Bool {
        let bounds = UIScreen.main.bounds
        let shortSide = min(bounds.width, bounds.height)
        let longSide = max(bounds.width, bounds.height)
        return shortSide <= 350 || longSide <= 700
    }

  
    @State private var isRunning = false
    @State private var isPaused = false
    @State private var showModal = false
    @State private var totalDuration: TimeInterval = 15 * 60
    @State private var remainingTime: TimeInterval = 15 * 60
    @State private var lastTickDate: Date?
    @State private var timer: Timer?

    var body: some View {
        GeometryReader { geometry in
            let scale = scaleForScreen(size: geometry.size)
            let topContentPadding = max(24, geometry.safeAreaInsets.top + 12)

            VStack(alignment: .leading) {
                Text("Break Timer")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.top, topContentPadding)

                Spacer()

                timerGraphic
                    .frame(maxWidth: .infinity)
                    .padding()
                Text(formattedTimer)
                    .font(.custom("Consolas", size: 56))
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()

                if !isRunning {
                    durationSegmented
                        .padding(.top)
                }

                Spacer()

                if isRunning {
                    controlsRow
                } else {
                    startButton
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 103)
            .frame(maxWidth: 390, maxHeight: .infinity, alignment: .topLeading)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .scaleEffect(scale, anchor: .top)
            .background(backgroundColor.ignoresSafeArea())
            .overlay { if showModal { modalOverlay } }
        }
    }

    private var timerGraphic: some View {
        VStack(spacing: 10) {
            let topInnerHeight: CGFloat = 80
            let bottomInnerHeight: CGFloat = 78

            ZStack {
                TrapezoidShape(topInset: 10)
                    .fill(Color(red: 42 / 255, green: 42 / 255, blue: 42 / 255))
                    .overlay {
                        TrapezoidShape(topInset: 10)
                            .stroke(Color(red: 68 / 255, green: 68 / 255, blue: 68 / 255), lineWidth: 2)
                    }
                    .frame(width: 112, height: 92)

            
                TrapezoidShape(topInset: 8)
                    .fill(activeRed)
                    .frame(width: 90, height: topInnerHeight)
                    .mask(alignment: .bottom) {
                        Rectangle().frame(height: max(0, topInnerHeight * (1 - progress)))
                    }
            }
            .frame(width: 104, height: 90)

            Rectangle()
                .fill(Color(red: 26 / 255, green: 26 / 255, blue: 26 / 255))
                .frame(width: 15, height: 54)
                .overlay(
                    RoundedRectangle(cornerRadius: 40)
                        .fill(activeRed.opacity(isRunning ? 1 : 0))
                        .frame(width: 12, height: 46)
                        .animation(.easeInOut(duration: 0.25), value: isRunning)
                )

            ZStack {
                TrapezoidShape(topInset: 10)
                    .fill(Color(red: 26 / 255, green: 26 / 255, blue: 26 / 255))
                    .overlay {
                        TrapezoidShape(topInset: 10)
                            .stroke(Color(red: 68 / 255, green: 68 / 255, blue: 68 / 255), lineWidth: 2)
                    }
                    .frame(width: 104, height: 90)
                    .rotationEffect(.degrees(180))

             
                TrapezoidShape(topInset: 8)
                    .fill(accentYellow)
                    .frame(width: 90, height: bottomInnerHeight)
                    .rotationEffect(.degrees(180))
                    .offset(y: 6)
                    .mask(alignment: .bottom) {
                        Rectangle().frame(height: max(0, bottomInnerHeight * progress))
                    }
            }
            .frame(width: 104, height: 90)
        }
    }

    private var durationSegmented: some View {
        HStack(spacing: 0) {
            ForEach(viewModel.durations.indices, id: \.self) { index in
                let value = viewModel.durations[index]
                let isSelected = selectedDuration == value

                Button {
                    SoundManager.shared.playButtonSound()
                    selectedDuration = value
                    totalDuration = TimeInterval(value)
                    remainingTime = totalDuration
                } label: {
                    Text(viewModel.durationTitle(value))
                        .font(.system(size: 10, weight: .regular))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 28)
                        .background(
                            Group {
                                if isSelected {
                                    RoundedRectangle(cornerRadius: 60, style: .continuous)
                                        .fill(activeRed)
                                } else {
                                    Color.clear
                                }
                            }
                        )
                }
                .buttonStyle(.plain)

                if index < viewModel.durations.count - 1 {
                    Rectangle()
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 1, height: 18)
                        .padding(.horizontal, 3)
                }
            }
        }
        .padding(2)
        .frame(height: 32)
        .background(cardColor)
        .clipShape(RoundedRectangle(cornerRadius: 70, style: .continuous))
    }

    private var startButton: some View {
        Button {
            SoundManager.shared.playButtonSound()
            totalDuration = TimeInterval(selectedDuration)
            remainingTime = totalDuration
            startTimer()
        } label: {
            Text("Start Break")
                .font(.system(size: 32 * 0.47, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(activeRed)
                .clipShape(RoundedRectangle(cornerRadius: 90, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var controlsRow: some View {
        HStack(spacing: 56) {
            Button {
                SoundManager.shared.playButtonSound()
                if isPaused {
                    resumeTimer()
                } else {
                    pauseTimer()
                }
            } label: {
                ZStack {
                    Circle().fill(controlBg).frame(width: 64, height: 64)
                    if isPaused {
                        Image(systemName: "play.fill")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(.white)
                    } else {
                        HStack(spacing: 6) {
                            Rectangle().fill(.white).frame(width: 6, height: 24).cornerRadius(2)
                            Rectangle().fill(.white).frame(width: 6, height: 24).cornerRadius(2)
                        }
                    }
                }
            }
            .buttonStyle(.plain)

            Button {
                SoundManager.shared.playButtonSound()
                stopTimerAndShowModal()
            } label: {
                ZStack {
                    Circle().fill(controlBg).frame(width: 64, height: 64)
                    Image(systemName: "xmark")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
    }

    private var modalOverlay: some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea()

            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(gradient: Gradient(colors: [Color(red: 1, green: 81 / 255, blue: 81 / 255),
                                                                         Color(red: 0.99, green: 0.33, blue: 0.33)]),
                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 80, height: 80)
                        .shadow(color: activeRed.opacity(0.6), radius: 30)
                    Image(systemName: "flame.fill")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(.white)
                }
                .padding(.top, 12)

                Text("You've Stepped Out Of\n“Work” Mode.")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)

                Text("Thank You For Extinguishing Me And Taking\n A Moment Away From Work.")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)

                Button {
                    SoundManager.shared.playButtonSound()
                    showModal = false
                    resetTimerToInitialState()
                } label: {
                    Text("Close")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(activeRed)
                        .clipShape(RoundedRectangle(cornerRadius: 90, style: .continuous))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }
            .frame(width: 342, height: 314)
            .background(cardColor)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(activeRed.opacity(0.5), lineWidth: 0.8)
            }
            .shadow(color: activeRed.opacity(0.5), radius: 11.2)
        }
        .transition(.opacity.combined(with: .scale))
        .animation(.easeOut(duration: 0.2), value: showModal)
    }

    private var formattedTimer: String {
        let rounded = Int(ceil(remainingTime.clamped(to: 0...totalDuration)))
        let minutes = rounded / 60
        let seconds = rounded % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func scaleForScreen(size: CGSize) -> CGFloat {
        if !isCompactPhone {
            return 1.0
        }

        let requiredHeight: CGFloat = 780
        let topPadding: CGFloat = 80
        let bottomPadding: CGFloat = 24
        let availableHeight = size.height - topPadding - bottomPadding
        let heightScale = min(1.0, availableHeight / requiredHeight)

        let widthScale = min(1.0, (size.width - 24) / 390)

        return max(0.99, min(heightScale, widthScale))
    }

   
    private var progress: CGFloat {
        let total = CGFloat(max(1, totalDuration))
        return 1 - CGFloat(remainingTime.clamped(to: 0...totalDuration)) / total
    }

   
    private func startTimer() {
        saveBreakDayMarkIfNeeded()
        if let sound = TimerSound(rawValue: selectedTimerSoundRaw) {
            SoundManager.shared.playTimerLoop(sound: sound)
        } else {
            SoundManager.shared.stopTimerLoop()
        }
        isRunning = true
        isPaused = false
        timer?.invalidate()
        lastTickDate = Date()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { t in
            if isPaused { return }
            let now = Date()
            let delta = now.timeIntervalSince(lastTickDate ?? now)
            lastTickDate = now

            if remainingTime > 0 {
                remainingTime -= delta
            } else {
                t.invalidate()
                timer = nil
                isRunning = false
                showModal = true
                SoundManager.shared.stopTimerLoop()
                SoundManager.shared.playCompletionSound()
            }

            if remainingTime <= 0 {
                remainingTime = 0
                t.invalidate()
                timer = nil
                isRunning = false
                showModal = true
                SoundManager.shared.stopTimerLoop()
                SoundManager.shared.playCompletionSound()
            }
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    private func pauseTimer() {
        isPaused = true
        SoundManager.shared.stopTimerLoop()
    }

    private func resumeTimer() {
        isPaused = false
        lastTickDate = Date()
        if let sound = TimerSound(rawValue: selectedTimerSoundRaw) {
            SoundManager.shared.playTimerLoop(sound: sound)
        }
    }

    private func stopTimerAndShowModal() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        isPaused = false
        showModal = true
        SoundManager.shared.stopTimerLoop()
    }

    private func resetTimerToInitialState() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        isPaused = false
        totalDuration = TimeInterval(selectedDuration)
        remainingTime = totalDuration
        lastTickDate = nil
        SoundManager.shared.stopTimerLoop()
    }

    private func saveBreakDayMarkIfNeeded() {
        let key = VolcanoDayMarksStore.dateKey(for: Date())
        var marks = VolcanoDayMarksStore.decode(dayMarksJSON)
        if marks[key] == nil {
            marks[key] = .breakTime
            dayMarksJSON = VolcanoDayMarksStore.encode(marks)
        }
    }
}

private struct TrapezoidShape: Shape {
    let topInset: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: topInset, y: 0))
        path.addLine(to: CGPoint(x: rect.width - topInset, y: 0))
        path.addLine(to: CGPoint(x: rect.width * 0.65, y: rect.height))
        path.addLine(to: CGPoint(x: rect.width * 0.35, y: rect.height))
        path.closeSubpath()
        return path
    }
}

private extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        min(max(self, limits.lowerBound), limits.upperBound)
    }
}

private extension TimeInterval {
    func clamped(to limits: ClosedRange<TimeInterval>) -> TimeInterval {
        min(max(self, limits.lowerBound), limits.upperBound)
    }
}
#Preview {
    RootTabContainerView()
}
