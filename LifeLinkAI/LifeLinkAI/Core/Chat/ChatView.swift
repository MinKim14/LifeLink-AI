//
//  ChatView.swift
//  WatchFirebase
//
//  Created by Min  on 2024/07/19.
//

import SwiftUI
import Firebase

struct DaySummary: Identifiable {
    var id: String
    var startTime: String
    var endTime: String
    var actionKeyword: String
    var metaData: String
    var summary: String
    var duration: Double {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        guard let start = formatter.date(from: startTime),
              let end = formatter.date(from: endTime) else { return 0 }
        return end.timeIntervalSince(start) / 60 // duration in minutes
    }
}


struct ChatHistoryView: View {
    var chatMessages: [ChatMessage]
    var body: some View {
        VStack{
            HStack {
                Text("Chat History")
                    .font(.headline)
                    .padding(.leading, 10)
                Spacer()
                Text(currentDateString()).font(.subheadline)
                    .padding(.trailing, 10)
            }
//            Text("Chat")
            List(chatMessages) { message in
                ChatBubble(direction: message.sender == "user" ? .right : .left, text: message.text)
            }
            .navigationTitle("Chat History")
         }
    }
    private func currentDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: Date())
    }
}

struct DaySummaryView: View {
    @ObservedObject var chatViewModel: FirebaseViewModel
    @State private var isTextBoxVisible: Bool = false
    @Binding var selectedDate: Date
    
    @State private var showSchedule = false
    @State private var selectedTab: Int = 0

    @Environment(\.colorScheme) var colorScheme
    
    
    var daySummary: [DaySummary]?
    // Computed properties outside the body
    private var uniqueSummaries: [DaySummary] {
        var seen = Set<String>()
        return chatViewModel.daySummaries.filter { summary in
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
    
    private var actionColors: [String: Color] {
        generateColorForActions(uniqueSummaries)
    }

    var body: some View {
        VStack {
            HStack {
                DatePicker("Select a date", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(CompactDatePickerStyle())
                    .onChange(of: selectedDate) { newDate in
                        // Fetch summaries for the selected date
                        chatViewModel.fetchDaySummaries(selectedDate)
                    }
                    .padding()
            }
            
            let summaries = chatViewModel.daySummaries

            VStack {
                Picker(selection: $selectedTab, label: Text("Select View")) {
                    Text("Pie Chart").tag(0)
                    Text("Day Schedule").tag(1)
                    Text("Image Summary").tag(2)
                    
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                if selectedTab == 0 {
                    PieChartView(summaries: summaries)
                } else if selectedTab == 1 {
                    DayScheduleView(summaries: summaries, actionColors: actionColors, selectedDate: selectedDate)
                    
                } else if selectedTab == 2 {
                    ImageSummaryView(chatViewModel: chatViewModel, date: selectedDate)
                }
                
                if isTextBoxVisible {
                    ZStack {
                        VisualEffectBlur(blurStyle: .systemUltraThinMaterial)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                        Text(chatViewModel.dateOverview)
                            .padding()
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                            .background(Color.clear)
                            .cornerRadius(5)
                    }
                    .padding()
                    .onTapGesture {
                        withAnimation {
                            isTextBoxVisible.toggle()
                        }
                    }
                } else {
                    ZStack {
                        VisualEffectBlur(blurStyle: .systemUltraThinMaterial)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                        VStack{
                            Text("Tap to show overall summary")
                                .padding()
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                                .background(Color.clear)
                                .cornerRadius(5)
                            ScrollView {
                                ForEach(uniqueSummaries) { summary in
                                    HStack(alignment: .bottom, spacing: 5) {
                                        Spacer()
                                        Rectangle()
                                            .fill(actionColors[summary.actionKeyword] ?? .clear)
                                            .frame(width: 20, height: 20)
                                            .cornerRadius(3)
                                        Text(summary.actionKeyword)
                                            .foregroundColor(colorScheme == .dark ? .white : .black)
                                        Spacer()
                                    }
                                    .frame(maxWidth: .infinity, maxHeight: 100, alignment: .leading)
                                    //                                     .padding(2)
                                }
                            }
                        }
                    }
                    .padding()
                    .onTapGesture {
                        withAnimation {
                            isTextBoxVisible.toggle()
                        }
                    }
                }
            }
        }
        .navigationTitle("Day Summary")
    }
}
// Custom visual effect blur view for glassmorphism
struct VisualEffectBlur: UIViewRepresentable {
    var blurStyle: UIBlurEffect.Style
    var vibrancyStyle: UIVibrancyEffectStyle?

    func makeUIView(context: Context) -> UIVisualEffectView {
        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))

        if let vibrancyStyle = vibrancyStyle {
            let vibrancyView = UIVisualEffectView(effect: UIVibrancyEffect(blurEffect: blurView.effect as! UIBlurEffect, style: vibrancyStyle))
            blurView.contentView.addSubview(vibrancyView)
            vibrancyView.frame = blurView.bounds
            vibrancyView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        }

        return blurView
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

struct ChatBubble: View {
    enum Direction {
        case left, right
    }
    
    var direction: Direction
    var text: String
    
    var body: some View {
        HStack(alignment: .top) {
            if direction == .left {
                Image(systemName: "person.circle.fill") // Using a robot icon
                    .resizable()
                    .frame(width: 30, height: 30) // Smaller size for the image
                    .padding(.trailing, 8)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("gemini")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text(text)
                        .font(.body)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color.blue)
                        .cornerRadius(16)
                        .foregroundColor(.white)
                }
                Spacer()
            } else {
                Spacer()
                Text(text)
                    .font(.body)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color.green)
                    .cornerRadius(16)
                    .foregroundColor(.white)
            }
        }
        .padding(direction == .left ? .leading : .trailing, 10)
        .padding(.vertical, 4) // Add some vertical padding for spacing between bubbles
    }
}

