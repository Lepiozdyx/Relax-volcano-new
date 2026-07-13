import SwiftUI

struct SettingsScreenView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @Binding var isBottomBarHidden: Bool
    @AppStorage(VolcanoStorageKey.workDayStartMinutes) private var storedWorkDayStartMinutes: Int = 8 * 60
    @AppStorage(VolcanoStorageKey.workDayEndMinutes) private var storedWorkDayEndMinutes: Int = 20 * 60
    @AppStorage(VolcanoStorageKey.timerSound) private var selectedTimerSoundRaw: String = TimerSound.rain.rawValue
    private let cardColor = Color(red: 28 / 255, green: 28 / 255, blue: 30 / 255)
    private let borderColor = Color(red: 106 / 255, green: 114 / 255, blue: 130 / 255)
    private let subtitleColor = Color(red: 106 / 255, green: 114 / 255, blue: 130 / 255)
    private let valueColor = Color(red: 153 / 255, green: 161 / 255, blue: 175 / 255)

    private var isCompactPhone: Bool {
        let bounds = UIScreen.main.bounds
        let shortSide = min(bounds.width, bounds.height)
        let longSide = max(bounds.width, bounds.height)
        return shortSide <= 350 || longSide <= 700
    }

    @State private var workDayStartHour: Int = 8
    @State private var workDayStartMinute: Int = 0
    @State private var workDayEndHour: Int = 20
    @State private var workDayEndMinute: Int = 0
    @State private var pickerHour: Int = 0
    @State private var pickerMinute: Int = 0
    @State private var pickerTarget: PickerTarget?
    @State private var hourAppliedDragSteps: Int = 0
    @State private var minuteAppliedDragSteps: Int = 0

    private enum PickerTarget {
        case dayStart
        case dayEnd
    }

    var body: some View {
        GeometryReader { geometry in
            let scale = scaleForScreen(size: geometry.size)
            let topContentPadding = max(24, geometry.safeAreaInsets.top + 12)

            ZStack(alignment: .bottom) {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        header
                        workDayCard
                        ambienceCard
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, topContentPadding)
                    .padding(.bottom, 120)
                    .frame(maxWidth: 390, alignment: .topLeading)
                }
                .scaleEffect(x: 1.0, y: scale, anchor: .top)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .background(Color.black.opacity(0.6).ignoresSafeArea())

                if pickerTarget != nil {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.easeOut(duration: 0.2)) {
                                pickerTarget = nil
                            }
                        }

                    timePickerPanel(bottomInset: geometry.safeAreaInsets.bottom)
                        .transition(.move(edge: .bottom))
                }
            }
        }
        .animation(.easeOut(duration: 0.2), value: pickerTarget != nil)
        .onChange(of: pickerTarget) { newValue in
            isBottomBarHidden = (newValue != nil)
        }
        .onAppear {
            applyStoredTimeValues()
        }
        .onDisappear {
            isBottomBarHidden = false
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Settings")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.white)

            Text("Configure Your Volcano")
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(subtitleColor)
        }
    }

    private var workDayCard: some View {
        VStack(spacing: 0) {
            settingsRow(
                title: "Work Day Starts",
                value: formattedTime(hour: workDayStartHour, minute: workDayStartMinute),
                icon: "clock",
                iconColor: Color(red: 1.0, green: 59 / 255, blue: 48 / 255),
                iconBackground: Color(red: 251 / 255, green: 44 / 255, blue: 54 / 255).opacity(0.1),
                onTap: { openPicker(target: .dayStart) }
            )

            Divider().background(borderColor.opacity(0.6))

            settingsRow(
                title: "Work Day Ends",
                value: formattedTime(hour: workDayEndHour, minute: workDayEndMinute),
                icon: "clock",
                iconColor: Color(red: 1.0, green: 59 / 255, blue: 48 / 255),
                iconBackground: Color(red: 251 / 255, green: 44 / 255, blue: 54 / 255).opacity(0.1),
                onTap: { openPicker(target: .dayEnd) }
            )
        }
        .frame(height: 118)
        .frame(maxWidth: .infinity)
        .background(cardColor)
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(borderColor.opacity(0.8), lineWidth: 0.8)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var ambienceCard: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Circle()
                    .fill(Color(red: 240 / 255, green: 177 / 255, blue: 0).opacity(0.1))
                    .frame(width: 31, height: 31)
                    .overlay {
                        Image(systemName: "music.note")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Color(red: 1.0, green: 215 / 255, blue: 0))
                    }

                Text("Timer Ambience")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)

            ForEach(Array(viewModel.ambienceItems.enumerated()), id: \.offset) { index, item in
                if index > 0 {
                    Divider().background(borderColor.opacity(0.6))
                }

                Button {
                    SoundManager.shared.playButtonSound()
                    selectedTimerSoundRaw = item.rawValue
                } label: {
                    HStack {
                        Text(item.title)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.white)

                        Spacer()

                        Circle()
                            .stroke(borderColor, lineWidth: 1)
                            .frame(width: 18, height: 18)
                            .overlay {
                                if item.rawValue == selectedTimerSoundRaw {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(Color(red: 1.0, green: 215 / 255, blue: 0))
                                }
                            }
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 42)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .frame(height: 273)
        .frame(maxWidth: .infinity)
        .background(cardColor)
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(borderColor.opacity(0.8), lineWidth: 0.8)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func settingsRow(
        title: String,
        value: String,
        icon: String,
        iconColor: Color,
        iconBackground: Color,
        onTap: @escaping () -> Void
    ) -> some View {
        Button {
            SoundManager.shared.playButtonSound()
            onTap()
        } label: {
            HStack(spacing: 12) {
                Circle()
                    .fill(iconBackground)
                    .frame(width: 31, height: 31)
                    .overlay {
                        Image(systemName: icon)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(iconColor)
                    }

                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)

                Spacer()

                HStack(spacing: 5) {
                    Text(value)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(valueColor)

                    Image(systemName: "pencil")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(valueColor)
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 59)
        }
        .buttonStyle(.plain)
    }

    private func timePickerPanel(bottomInset: CGFloat) -> some View {
        VStack(spacing: 8) {
            HStack {
                Spacer()
                Text("Pick a time")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.white)
                Spacer()
            }
            .frame(height: 44)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(Color(red: 186 / 255, green: 186 / 255, blue: 186 / 255))
                    .frame(height: 1)
            }

            HStack(spacing: 22) {
                pickerColumn(
                    values: nearbyValues(around: pickerHour, maxValue: 23),
                    selectedValue: pickerHour,
                    onSelect: { pickerHour = $0 },
                    onStep: { step in
                        pickerHour = wrappedValue(current: pickerHour, delta: step, maxValue: 23)
                    },
                    appliedDragSteps: $hourAppliedDragSteps
                )
                pickerColumn(
                    values: nearbyValues(around: pickerMinute, maxValue: 59),
                    selectedValue: pickerMinute,
                    onSelect: { pickerMinute = $0 },
                    onStep: { step in
                        pickerMinute = wrappedValue(current: pickerMinute, delta: step, maxValue: 59)
                    },
                    appliedDragSteps: $minuteAppliedDragSteps
                )
            }
            .padding(.top, 4)
            .frame(height: 220)

            Button {
                SoundManager.shared.playButtonSound()
                savePickerTime()
            } label: {
                Text("Save")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color(red: 1.0, green: 59 / 255, blue: 48 / 255))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity)
        .frame(height: 354)
        .background(Color(red: 28 / 255, green: 28 / 255, blue: 30 / 255))
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 8,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 8
            )
        )
        .padding(.bottom, max(0, bottomInset))
    }

    private func pickerColumn(
        values: [Int],
        selectedValue: Int,
        onSelect: @escaping (Int) -> Void,
        onStep: @escaping (Int) -> Void,
        appliedDragSteps: Binding<Int>
    ) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(values.enumerated()), id: \.offset) { index, value in
                let isSelected = value == selectedValue
                let textColor: Color = {
                    if isSelected {
                        return Color(red: 1.0, green: 215 / 255, blue: 0)
                    }
                    if index == 1 || index == 3 {
                        return Color.white.opacity(0.45)
                    }
                    return Color.white.opacity(0.18)
                }()

                Button {
                    onSelect(value)
                } label: {
                    Text(String(format: "%02d", value))
                        .font(.system(size: 34 * 0.5, weight: isSelected ? .medium : .regular))
                        .foregroundStyle(textColor)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                }
                .buttonStyle(.plain)
                .overlay(alignment: .bottom) {
                    if isSelected {
                        Rectangle()
                            .fill(Color(red: 186 / 255, green: 186 / 255, blue: 186 / 255))
                            .frame(height: 1)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .highPriorityGesture(
            DragGesture(minimumDistance: 8)
                .onChanged { value in
                    let stepHeight: CGFloat = 44
                    let totalSteps = Int(value.translation.height / stepHeight)
                    let diff = totalSteps - appliedDragSteps.wrappedValue
                    if diff != 0 {
                        onStep(-diff)
                        appliedDragSteps.wrappedValue = totalSteps
                    }
                }
                .onEnded { _ in
                    appliedDragSteps.wrappedValue = 0
                }
        )
    }

    private func nearbyValues(around selected: Int, maxValue: Int) -> [Int] {
        [selected - 2, selected - 1, selected, selected + 1, selected + 2].map {
            ($0 % (maxValue + 1) + (maxValue + 1)) % (maxValue + 1)
        }
    }

    private func wrappedValue(current: Int, delta: Int, maxValue: Int) -> Int {
        let modulo = maxValue + 1
        return (current + delta % modulo + modulo) % modulo
    }

    private func openPicker(target: PickerTarget) {
        pickerTarget = target
        switch target {
        case .dayStart:
            pickerHour = workDayStartHour
            pickerMinute = workDayStartMinute
        case .dayEnd:
            pickerHour = workDayEndHour
            pickerMinute = workDayEndMinute
        }
    }

    private func savePickerTime() {
        guard let target = pickerTarget else { return }
        switch target {
        case .dayStart:
            workDayStartHour = pickerHour
            workDayStartMinute = pickerMinute
            storedWorkDayStartMinutes = pickerHour * 60 + pickerMinute
        case .dayEnd:
            workDayEndHour = pickerHour
            workDayEndMinute = pickerMinute
            storedWorkDayEndMinutes = pickerHour * 60 + pickerMinute
        }
        pickerTarget = nil
        NotificationManager.shared.scheduleDailyVolcanoNotifications(
            startMinutes: storedWorkDayStartMinutes,
            endMinutes: storedWorkDayEndMinutes
        )
    }

    private func applyStoredTimeValues() {
        workDayStartHour = storedWorkDayStartMinutes / 60
        workDayStartMinute = storedWorkDayStartMinutes % 60
        workDayEndHour = storedWorkDayEndMinutes / 60
        workDayEndMinute = storedWorkDayEndMinutes % 60
    }

    private func formattedTime(hour: Int, minute: Int) -> String {
        String(format: "%02d:%02d", hour, minute)
    }

    private func scaleForScreen(size: CGSize) -> CGFloat {
        if !isCompactPhone {
            return 1.0
        }

        let requiredHeight: CGFloat = 760
        let topPadding: CGFloat = isCompactPhone ? 80 : 110
        let bottomPadding: CGFloat = isCompactPhone ? 24 : 40
        let availableHeight = size.height - topPadding - bottomPadding
        let heightScale = min(1.0, availableHeight / requiredHeight)

        let scale = heightScale
        let minScale: CGFloat = 0.85
        return max(minScale, scale)
    }

}

#Preview {
    SettingsScreenView(isBottomBarHidden: .constant(false))
}
