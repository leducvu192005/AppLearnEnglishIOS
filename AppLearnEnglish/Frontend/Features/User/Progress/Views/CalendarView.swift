//
//  CalendarView.swift
//  AppLearnEnglish
//

import SwiftUI

struct CalendarView: View {
    let studyDates: [Date]
    
    private let calendar = Calendar.current
    private let daysOfWeek = ["T2", "T3", "T4", "T5", "T6", "T7", "CN"]
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Lịch Học Tuần Này")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.textDark)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 10) {
                ForEach(0..<7) { index in
                    let date = getDateForOffset(index)
                    let dayName = getDayName(for: date)
                    let isStudied = checkIfStudied(date)
                    let isToday = calendar.isDateInToday(date)
                    
                    VStack(spacing: 8) {
                        Text(dayName)
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(AppTheme.textMuted)
                        
                        ZStack {
                            Circle()
                                .fill(isStudied ? AppTheme.primaryMint : (isToday ? AppTheme.primaryMint.opacity(0.1) : Color.black.opacity(0.03)))
                                .frame(width: 36, height: 36)
                            
                            if isStudied {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                            } else {
                                Text(getDayNumber(for: date))
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundColor(isToday ? AppTheme.primaryMint : AppTheme.textMuted)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(16)
        .cuteCardStyle()
    }
    
    // MARK: - Date Helpers
    
    private func getDateForOffset(_ offset: Int) -> Date {
        // Return dates starting from Monday of current week
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        // Convert Sunday as 1 to Sunday as 7, Monday as 2 to Monday as 1
        let daysToSubtract = (weekday == 1) ? 6 : (weekday - 2)
        
        let monday = calendar.date(byAdding: .day, value: -daysToSubtract, to: today) ?? today
        return calendar.date(byAdding: .day, value: offset, to: monday) ?? today
    }
    
    private func getDayName(for date: Date) -> String {
        let weekday = calendar.component(.weekday, from: date)
        // calendar weekday: 1 = Sunday, 2 = Monday, etc.
        let index = (weekday == 1) ? 6 : (weekday - 2)
        guard index >= 0 && index < daysOfWeek.count else { return "" }
        return daysOfWeek[index]
    }
    
    private func getDayNumber(for date: Date) -> String {
        return String(calendar.component(.day, from: date))
    }
    
    private func checkIfStudied(_ date: Date) -> Bool {
        return studyDates.contains { calendar.isDate($0, inSameDayAs: date) }
    }
}

#Preview {
    CalendarView(studyDates: [Date()])
        .padding()
        .background(AppTheme.bgGradientStart)
}
