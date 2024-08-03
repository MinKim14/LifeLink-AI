//
//  ContentView.swift
//  WatchFirebase
//
//  Created by Min  on 2024/06/15.
//

import SwiftUI
import WatchConnectivity

struct ContentView: View {
    @State private var showMenu = false
    @ObservedObject var connector = WatchConnector.shared
    
    @EnvironmentObject var authViewModel: AuthViewModel
//    @ObservedObject var messageReader = MessageReader()
    

    @ObservedObject private var messageReader: MessageReader
    @ObservedObject var chatViewModel: FirebaseViewModel
//    @StateObject private var messageManager = MessageManager()

    init(authViewModel: AuthViewModel) {
        _messageReader = ObservedObject(wrappedValue: MessageReader(authViewModel: authViewModel))
        _chatViewModel = ObservedObject(wrappedValue: FirebaseViewModel(authViewModel: authViewModel))
    }
//    @ObservedObject var chatViewModel = FirebaseViewModel()
    @State private var selectedDate: Date = Date()

    
    var body: some View {
        Group{
            if authViewModel.userSession == nil {
                //no user logged in
                LoginView().environmentObject(authViewModel)
            } else {
                TabView {
                    
                    
                    ChatHistoryView(chatMessages: chatViewModel.chatMessages).tabItem{
                        Label("Chat", systemImage: "message")
                    }
                    
                    DaySummaryView(chatViewModel: chatViewModel, selectedDate: $selectedDate)
                        .tabItem {
                            Label("Summary", systemImage: "calendar")
                        }
                    Group{
                        
                        VStack(alignment: .center){
                            
                            HStack {
                                Spacer()
                                Button(action: {
                                    authViewModel.signOut()
                                }) {
                                    Text("Logout")
                                        .foregroundColor(.white)
                                        .padding()
                                        .background(Color.gray)
                                        .cornerRadius(8)
                                }
                                .padding(.trailing)
                            }
                            Spacer()
                            ScrollView {
                                Text(messageReader.message)
                                    .padding()
                            }
                            .frame(maxWidth: .infinity, maxHeight: 200) // Set a fixed height for the scroll view
                            .padding(.horizontal)
                            
                            Spacer()
                            
                            LazyHStack(alignment: .center) {
                                DataItemView(dataColor: Color("mPurple"), dataName: "Acc_X", dataValue: self.connector.accModel.acc_x().last ?? 0.0)
                                DataItemView(dataColor: Color("mPink"), dataName: "Acc_Y", dataValue: self.connector.accModel.acc_y().last ?? 0.0)
                                DataItemView(dataColor: Color("mGreen"), dataName: "Acc_Z", dataValue: self.connector.accModel.acc_z().last ?? 0.0)
                            }
                            .frame(height: 50)
                            LineChartView(dataPoints_X: self.connector.accModel.acc_x(), dataPoints_Y: self.connector.accModel.acc_y(), dataPoints_Z: self.connector.accModel.acc_z())
                                .padding(.trailing)
                                .padding(.vertical)
                            Spacer()
                            LazyHStack(alignment: .center) {
                                DataItemView(dataColor: Color("mPurple"), dataName: "Pitch_X", dataValue: self.connector.oriModel.pitch_x().last ?? 0.0)
                                DataItemView(dataColor: Color("mPink"), dataName: "Roll_Y", dataValue: self.connector.oriModel.roll_y().last ?? 0.0)
                                DataItemView(dataColor: Color("mGreen"), dataName: "Yaw_Z", dataValue: self.connector.oriModel.yaw_z().last ?? 0.0)
                            }
                            .frame(height: 50)
                            LineChartView(dataPoints_X: self.connector.oriModel.pitch_x(), dataPoints_Y: self.connector.oriModel.roll_y(), dataPoints_Z: self.connector.oriModel.yaw_z())
                                .padding(.trailing)
                                .padding(.vertical)
                            Spacer()
                            
                        }
                    }.tabItem {
                        Label("Signal", systemImage: "house.fill")
                    }
                }
            }
        }
    }
}
//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView()
//    }
//}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter
}()


