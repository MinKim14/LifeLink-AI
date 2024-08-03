//
//  PieChartView.swift
//  WatchFirebase
//
//  Created by Min  on 2024/07/21.
//

import SwiftUI
import Charts

func generateColorForActions(_ summaries: [DaySummary]) -> [String: Color] {
    var actionColors: [String: Color] = [:]
    let colors: [Color] = [.blue, .green, .orange, .red, .purple, .yellow, .pink, .gray, .cyan, .teal, .mint, .indigo, .brown]
    var colorIndex = 0
    
    for summary in summaries {
        if actionColors[summary.actionKeyword] == nil {
            actionColors[summary.actionKeyword] = colors[colorIndex % colors.count]
            colorIndex += 1
        }
    }
    
    return actionColors
}



struct ImageSummaryView: View {
    @ObservedObject var chatViewModel: FirebaseViewModel
    let date: Date
    
    var body: some View {
        VStack {
            if chatViewModel.isLoading {
                Text("Loading...")
            } else if let image = chatViewModel.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                Text("Not yet loaded")
            }
        }
    }
}

struct PieChartView: View {
    var summaries: [DaySummary]

    private func timeLabel(for hour: Int) -> String {
        return String(format: "%02d", hour)
    }
    
    var body: some View {
        var uniqueSummaries: [DaySummary] {
            var seen = Set<String>()
            return summaries.filter { summary in
                let cleanedKeyword = summary.actionKeyword
                    .replacingOccurrences(of: "\n", with: "")
                    .trimmingCharacters(in: .whitespaces)
                    .lowercased()
                if seen.contains(cleanedKeyword) {
                    return false
                } else {
                    seen.insert(cleanedKeyword)
                    return true
                }
            }.map { summary in
                var cleanedSummary = summary
                cleanedSummary.actionKeyword = summary.actionKeyword
                    .replacingOccurrences(of: "\n", with: "")
                    .trimmingCharacters(in: .whitespaces)
                    .lowercased()
                return cleanedSummary
            }
        }
        
        var actionColors: [String: Color] {
            generateColorForActions(uniqueSummaries)
        }
        
        var actionKeywordMap: [String: String] {
            var map = [String: String]()
            for summary in summaries {
                let originalKeyword = summary.actionKeyword
                let cleanedKeyword = originalKeyword
                    .replacingOccurrences(of: "\n", with: "")
                    .trimmingCharacters(in: .whitespaces)
                    .lowercased()
                map[originalKeyword] = cleanedKeyword
            }
            return map
        }
        
        VStack {
            Text("Summary of Today's Activities")
                .font(.headline)
            GeometryReader { geometry in
                let radius = min(geometry.size.width, geometry.size.height) / 2
                let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
                let totalMinutes = 24 * 60 // Total minutes in a day
                
                ZStack {
                    ForEach(summaries) { summary in
                        let startAngle = angle(for: summary.startTime, totalMinutes: totalMinutes)
                        let endAngle = angle(for: summary.endTime, totalMinutes: totalMinutes)
 
                        PieSlice(startAngle: startAngle, endAngle: endAngle, radius: radius)
                            .fill(actionColors[actionKeywordMap[summary.actionKeyword] ?? ""] ?? .gray)
                            .offset(x: center.x - radius, y: center.y - radius)
                    }
                    
                    ForEach(summaries) { summary in
                        let startAngle = angle(for: summary.startTime, totalMinutes: totalMinutes)
                        let endAngle = angle(for: summary.endTime, totalMinutes: totalMinutes)
                        
                        let midAngle = Angle.degrees((startAngle.degrees + endAngle.degrees) / 2)
                        
                        let cosMidAngle = cos(midAngle.radians)
                        let sinMidAngle = sin(midAngle.radians)
                        let labelPosition = CGPoint(x: center.x + radius * 0.5 * cosMidAngle, y: center.y + radius * 0.5 * sinMidAngle)
                        
                        let sliceAngle = endAngle.degrees - startAngle.degrees
                        
                        if sliceAngle > 10 { // Adjust this threshold as needed
                            Text(actionKeywordMap[summary.actionKeyword] ?? "")
                                .position(labelPosition)
                                .font(.subheadline)
                                .foregroundColor(.white)
                        }
                    }
                

                    ForEach(0..<8) { index in
                        let hour = index * 3
                        let angle = angle(for: String(format: "%02d:00", hour), totalMinutes: totalMinutes)
                        let cosAngle = cos(angle.radians)
                        let sinAngle = sin(angle.radians)
                        let labelPosition = CGPoint(x: center.x + radius * 0.9 * cosAngle, y: center.y + radius * 0.9 * sinAngle)
                        let timeText = timeLabel(for: hour)
                        Text(timeText)
                            .position(labelPosition)
                            .font(.caption)
                            .foregroundColor(.white)
                    }


                }
 // Glassmorphism background
                
                .background(.gray)
                .clipShape(Circle())

            }
            .aspectRatio(1, contentMode: .fit)
        }
        .padding()
        .background(                        
            VisualEffectBlur(blurStyle: .systemUltraThinMaterial)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            ))

    }
    
    private func angle(for time: String, totalMinutes: Int) -> Angle {

        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        guard let date = formatter.date(from: time) else {
            return .degrees(0)
        }
        
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        
        let minutes = hour * 60 + minute
        let degrees = Double(minutes) / Double(totalMinutes) * 360.0
        return .degrees(degrees - 90) // Adjust for starting angle
    }
    

}
struct DayScheduleView: View {
    @Environment(\.colorScheme) var colorScheme

    var summaries: [DaySummary]
    var actionColors: [String: Color]
    var selectedDate: Date
    var actionKeywordMap: [String: String] {
        var map = [String: String]()
        for summary in summaries {
            let originalKeyword = summary.actionKeyword
            let cleanedKeyword = originalKeyword
                .replacingOccurrences(of: "\n", with: "")
                .trimmingCharacters(in: .whitespaces)
                .lowercased()
            map[originalKeyword] = cleanedKeyword
        }
        return map
    }
    var body: some View {
        VStack {
            // Header with the selected date
            HStack {
                Text(currentDay(for: selectedDate))
                    .font(.headline)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                Spacer()
                Text(currentDate(for: selectedDate))
                    .font(.headline)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
            }
            .padding()


            
            // Time labels and event list
            ScrollView {
                VStack(spacing: 20) {
                    ForEach(0..<24) { hour in
                        HStack {
                            Text("\(hour % 12 == 0 ? 12 : hour % 12) \(hour < 12 ? "AM" : "PM")")
                                .frame(width: 60, alignment: .leading)
                                .font(.caption)
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 1)
                            Spacer()
                        }
                        .padding(.leading)
                        
                        ForEach(summaries.filter { summary in
                            let formatter = DateFormatter()
                            formatter.dateFormat = "HH:mm"
                            guard let start = formatter.date(from: summary.startTime), let end = formatter.date(from: summary.endTime) else { return false }
                            let calendar = Calendar.current
                            let startHour = calendar.component(.hour, from: start)
                            return startHour == hour
                        }) { summary in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("\(summary.startTime) - \(summary.endTime) : \(actionKeywordMap[summary.actionKeyword] ?? "")")
                                        .font(.headline)
                                    Text(summary.metaData
                                        .replacingOccurrences(of: "\n", with: "")
                                        .trimmingCharacters(in: .whitespaces)
                                    )
                                    .font(.subheadline)
                                }

                                .padding(8)
                                .background(actionColors[actionKeywordMap[summary.actionKeyword] ?? ""] ?? Color.blue)
                                .cornerRadius(8)
                                .foregroundColor(.white)
                                Spacer()
                            }
                            .padding(.leading, 70)
                        }
                    }
                }
            }

        }
        .padding()
    }
    
    private func currentDate(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    private func currentDay(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).uppercased()
    }
}
struct PieSlice: Shape {
    var startAngle: Angle
    var endAngle: Angle
    var radius: CGFloat
    
    var animatableData: AnimatablePair<Double, Double> {
        get {
            AnimatablePair(startAngle.radians, endAngle.radians)
        }
        set {
            startAngle = Angle(radians: newValue.first)
            endAngle = Angle(radians: newValue.second)
        }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let center = CGPoint(x: rect.midX, y: rect.midY)
        
        path.move(to: center)
        path.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        
        path.closeSubpath()
        
        return path
    }

}


