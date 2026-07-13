import SwiftUI
import Combine

struct VolcanoScreenView: View {
    @AppStorage(VolcanoStorageKey.workDayStartMinutes) private var workDayStartMinutes: Int = 8 * 60
    @AppStorage(VolcanoStorageKey.workDayEndMinutes) private var workDayEndMinutes: Int = 20 * 60
    @AppStorage(VolcanoStorageKey.dayMarksJSON) private var dayMarksJSON: String = "{}"
    @AppStorage(VolcanoStorageKey.daySwipeCountsJSON) private var daySwipeCountsJSON: String = "{}"

    @State private var activeStage: VolcanoStage = .calm
    @State private var swipeCountForCurrentStep: Int = 0
    @State private var showSuccessModal = false
    @State private var now = Date()
    @State private var fallingDrops: [FallingDrop] = []

    private let stageSwipeTargets: [VolcanoStage: Int] = [
        .calm: 0,
        .smoking: 3,
        .heating: 10,
        .ash: 15,
        .eruption: 20,
        .critical: 30,
        .destroyed: 50
    ]

    var body: some View {
        GeometryReader { geometry in
            let topContentPadding = max(24, geometry.safeAreaInsets.top + 12)
            let dayMark = currentDayMark
            let timelineBaseStage = timelineStage(for: now)
            let currentBaseStage = timelineBaseStage
            let effectiveStage = dayMark == .done ? VolcanoStage.calm : min(activeStage, currentBaseStage)
            let isDestroyed = dayMark == .missed || nowMinutes >= normalizedWorkDayEndMinutes || effectiveStage == .destroyed
            let currentTarget = stageSwipeTarget(for: effectiveStage)
            let visualStage = visualStage(for: effectiveStage, isDestroyed: isDestroyed)
            let canExtinguish = dayMark == .none && !isDestroyed && currentTarget > 0
            let showsSwipeProgress = dayMark != .done && (isDestroyed || currentTarget > 0)
            let bottomScenePadding = max(0, 83 - geometry.safeAreaInsets.bottom)
            let dropStartY: CGFloat = showsSwipeProgress
                ? topContentPadding + 24 + 26 + 52 + 10 + 8
                : (topContentPadding + 80)
            let dropEndY = max(180, geometry.size.height - bottomScenePadding - 220)

            ZStack(alignment: .bottom) {
                Color.black.opacity(0.6).ignoresSafeArea()

                VStack(alignment: .leading, spacing: 0) {
                    Text("Relax Volcano")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.top, topContentPadding)
                        .padding(.horizontal, 24)

                    if !showsSwipeProgress {
                        infoPill(text: statusText(isDestroyed: isDestroyed, isDone: dayMark == .done))
                            .padding(.top, 24)
                            .padding(.horizontal, 32)
                    }

                    if showsSwipeProgress {
                        progressSection(current: swipeCountForCurrentStep, target: currentTarget, isDestroyed: isDestroyed)
                            .padding(.top, 26)
                            .padding(.horizontal, 24)
                    }

                    Spacer()
                }

                ZStack(alignment: .bottom) {
                    Image("field")
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: 78)
                        .overlay {
                            if let fieldOverlay = fieldOverlayAssetName(for: visualStage) {
                                Image(fieldOverlay)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: geometry.size.width, height: 78)
                            }
                        }

                    Image(volcanoAssetName(for: visualStage))
                        .resizable()
                        .scaledToFit()
                        .frame(width: geometry.size.width)
                        .offset(y: -76)
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, bottomScenePadding)

                ForEach(fallingDrops) { drop in
                    Image("Frame")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 44, height: 44)
                        .position(
                            x: drop.x,
                            y: drop.isFalling ? drop.endY : drop.startY
                        )
                        .opacity(1.0)
                }
            }
            .contentShape(Rectangle())
            .gesture(canExtinguish ? DragGesture(minimumDistance: 18)
                .onEnded { value in
                    guard abs(value.translation.width) > 10 || abs(value.translation.height) > 10 else {
                        return
                    }
                    handleSwipe(
                        baseStage: currentBaseStage,
                        dayMark: dayMark,
                        isDestroyed: isDestroyed,
                        dropStartY: dropStartY,
                        dropEndY: dropEndY,
                        screenWidth: geometry.size.width
                    )
                } : nil)
            .overlay {
                if showSuccessModal {
                    successModal
                }
            }
            .onAppear {
                tickNow()
            }
            .onReceive(Timer.publish(every: 30, on: .main, in: .common).autoconnect()) { _ in
                tickNow()
            }
            .onChange(of: workDayStartMinutes) { _ in
                tickNow()
            }
            .onChange(of: workDayEndMinutes) { _ in
                tickNow()
            }
        }
    }

    private func progressSection(current: Int, target: Int, isDestroyed: Bool) -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "flame")
                    .foregroundStyle(Color(red: 1.0, green: 59 / 255, blue: 48 / 255))
                Text(isDestroyed ? "Don't forget to turn me off tomorrow" : "Swipe anywhere to extinguish!")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(Color(red: 1.0, green: 59 / 255, blue: 48 / 255))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Color(red: 28 / 255, green: 28 / 255, blue: 30 / 255))
            .clipShape(RoundedRectangle(cornerRadius: 70, style: .continuous))
            .shadow(color: Color(red: 1.0, green: 59 / 255, blue: 48 / 255).opacity(0.5), radius: 7.2)

            if !isDestroyed {
                ProgressView(value: Double(current), total: Double(max(target, 1)))
                    .tint(Color(red: 1.0, green: 215 / 255, blue: 0))
                    .background(Color.clear)

                Text("\(current) / \(target) swipes")
                    .font(.system(size: 32 * 0.6, weight: .medium))
                    .foregroundStyle(Color(red: 1.0, green: 215 / 255, blue: 0))
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private func infoPill(text: String) -> some View {
        Text(text)
            .font(.system(size: 15, weight: .regular))
            .foregroundStyle(Color(red: 1.0, green: 59 / 255, blue: 48 / 255))
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Color(red: 28 / 255, green: 28 / 255, blue: 30 / 255))
            .clipShape(RoundedRectangle(cornerRadius: 70, style: .continuous))
            .shadow(color: Color(red: 1.0, green: 59 / 255, blue: 48 / 255).opacity(0.5), radius: 7.2)
    }

    private var successModal: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
            VStack(spacing: 18) {
                Circle()
                    .fill(Color(red: 79 / 255, green: 208 / 255, blue: 255 / 255))
                    .frame(width: 105, height: 105)
                    .overlay {
                        Text("💧")
                            .font(.system(size: 44))
                    }

                Text("Cooled Down!")
                    .font(.system(size: 52 * 0.6, weight: .bold))
                    .foregroundStyle(.white)

                Text("Thank You For Extinguishing Me And Taking A Moment Away From Work.")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Button {
                    SoundManager.shared.playButtonSound()
                    showSuccessModal = false
                } label: {
                    Text("Close")
                        .font(.system(size: 34 * 0.5, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color(red: 1.0, green: 59 / 255, blue: 48 / 255))
                        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                }
                .buttonStyle(.plain)
                .padding(.top, 10)
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 26)
            .frame(maxWidth: 448)
            .background(Color(red: 28 / 255, green: 28 / 255, blue: 30 / 255))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.blue.opacity(0.65), lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .padding(.horizontal, 24)
        }
    }

    private func tickNow() {
        now = Date()
        if currentDayMark == .none && nowMinutes >= normalizedWorkDayEndMinutes {
            saveCurrentDayMark(.missed)
        }
        if currentDayMark == .none {
            activeStage = timelineStage(for: now)
        }
    }

    private func handleSwipe(
        baseStage: VolcanoStage,
        dayMark: DayMarkState,
        isDestroyed: Bool,
        dropStartY: CGFloat,
        dropEndY: CGFloat,
        screenWidth: CGFloat
    ) {
        guard !isDestroyed else { return }
        if dayMark != .none { return }

        let stage = min(activeStage, baseStage)
        let target = stageSwipeTarget(for: stage)
        guard target > 0 else { return }

        spawnWaterDrop(startY: dropStartY, endY: dropEndY, screenWidth: screenWidth)
        swipeCountForCurrentStep += 1
        incrementTodaySwipeCount()
        if swipeCountForCurrentStep >= target {
            let nextStage = max(.calm, stage.previous)
            activeStage = nextStage
            swipeCountForCurrentStep = 0
            if nextStage == .calm {
                showSuccessModal = true
                saveCurrentDayMark(.done)
            }
        }
    }

    private func stageSwipeTarget(for stage: VolcanoStage) -> Int {
        stageSwipeTargets[stage] ?? 50
    }

    private func spawnWaterDrop(startY: CGFloat, endY: CGFloat, screenWidth: CGFloat) {
        let animationDuration: Double = 0.55
        let drop = FallingDrop(
            x: screenWidth / 2,
            startY: startY,
            endY: endY,
            isFalling: false
        )
        fallingDrops.append(drop)

        DispatchQueue.main.async {
            guard let index = fallingDrops.firstIndex(where: { $0.id == drop.id }) else { return }
            withAnimation(.easeIn(duration: animationDuration)) {
                fallingDrops[index].isFalling = true
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
            fallingDrops.removeAll { $0.id == drop.id }
        }
    }

    private func volcanoAssetName(for stage: Int) -> String {
        let clamped = max(0, min(stage, 9))
        switch clamped {
        case 9: return "0"
        case 0...1: return "0"
        case 2: return "1"
        case 3: return "2"
        case 4: return "3"
        case 5: return "4"
        case 6: return "5"
        case 7: return "6"
        default: return "7"
        }
    }

    private func fieldOverlayAssetName(for stage: Int) -> String? {
        let clamped = max(0, min(stage, 9))
        switch clamped {
        case 0...1: return nil
        case 2...4: return "field-4"
        case 5...7: return "field-2"
        default: return "field-4"
        }
    }

    private func statusText(isDestroyed: Bool, isDone: Bool) -> String {
        if isDestroyed {
            return "Don't forget to turn me off tomorrow"
        }
        if isDone {
            return "Thanks for cooling me down and\n taking a little break from work"
        }
        return "Swipe anywhere to extinguish!"
    }

    private func timelineStage(for date: Date) -> VolcanoStage {
        let minutes = minutesSinceMidnight(for: date)
        if minutes < normalizedWorkDayStartMinutes { return .calm }
        if minutes >= normalizedWorkDayEndMinutes { return .destroyed }

        let span = max(1, normalizedWorkDayEndMinutes - normalizedWorkDayStartMinutes)
        let elapsed = max(0, minutes - normalizedWorkDayStartMinutes)
        let progress = Double(elapsed) / Double(span)
        let bucket = min(5, Int(progress * 6.0))
        switch bucket {
        case 0: return .calm
        case 1: return .smoking
        case 2: return .heating
        case 3: return .ash
        case 4: return .eruption
        default: return .critical
        }
    }

    private func visualStage(for stage: VolcanoStage, isDestroyed: Bool) -> Int {
        if isDestroyed || stage == .destroyed { return 9 }
        switch stage {
        case .calm: return 0
        case .smoking: return 2
        case .heating: return 3
        case .ash: return 4
        case .eruption: return 6
        case .critical: return 8
        case .destroyed: return 9
        }
    }

    private var normalizedWorkDayStartMinutes: Int {
        max(0, min(workDayStartMinutes, 23 * 60 + 59))
    }

    private var normalizedWorkDayEndMinutes: Int {
        max(normalizedWorkDayStartMinutes + 1, min(workDayEndMinutes, 24 * 60))
    }

    private var nowMinutes: Int {
        minutesSinceMidnight(for: now)
    }

    private func minutesSinceMidnight(for date: Date) -> Int {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (components.hour ?? 0) * 60 + (components.minute ?? 0)
    }

    private var currentDayMark: DayMarkState {
        let map = VolcanoDayMarksStore.decode(dayMarksJSON)
        let key = VolcanoDayMarksStore.dateKey(for: now)
        guard let mark = map[key] else { return .none }
        switch mark {
        case .done: return .done
        case .breakTime: return .none
        case .missed: return .missed
        }
    }

    private func saveCurrentDayMark(_ mark: VolcanoDayMark) {
        var map = VolcanoDayMarksStore.decode(dayMarksJSON)
        map[VolcanoDayMarksStore.dateKey(for: now)] = mark
        dayMarksJSON = VolcanoDayMarksStore.encode(map)
    }

    private func incrementTodaySwipeCount() {
        let key = VolcanoDayMarksStore.dateKey(for: now)
        var counts = VolcanoDaySwipeCountsStore.decode(daySwipeCountsJSON)
        counts[key, default: 0] += 1
        daySwipeCountsJSON = VolcanoDaySwipeCountsStore.encode(counts)
    }

    private enum DayMarkState {
        case none
        case done
        case missed
    }

    private struct FallingDrop: Identifiable {
        let id = UUID()
        let x: CGFloat
        let startY: CGFloat
        let endY: CGFloat
        var isFalling: Bool
    }

    private enum VolcanoStage: Int, Comparable, CaseIterable {
        case calm
        case smoking
        case heating
        case ash
        case eruption
        case critical
        case destroyed

        var previous: VolcanoStage {
            switch self {
            case .calm: return .calm
            case .smoking: return .calm
            case .heating: return .smoking
            case .ash: return .heating
            case .eruption: return .ash
            case .critical: return .eruption
            case .destroyed: return .critical
            }
        }

        var title: String {
            switch self {
            case .calm: return "Calm"
            case .smoking: return "Smoking"
            case .heating: return "Heating"
            case .ash: return "Ash"
            case .eruption: return "Eruption"
            case .critical: return "Critical"
            case .destroyed: return "Destroyed"
            }
        }

        static func < (lhs: VolcanoStage, rhs: VolcanoStage) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }
}

#Preview {
    VolcanoScreenView()
}
