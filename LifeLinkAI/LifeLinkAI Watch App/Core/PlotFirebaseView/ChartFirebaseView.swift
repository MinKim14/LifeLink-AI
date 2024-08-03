//
//  ChartFirebaseView.swift
//  WatchFirebase Watch App
//
//  Created by Min  on 2022/12/22.
//

import SwiftUI

struct ChartFirebaseView: View {
    @EnvironmentObject var workoutManager: WorkoutMananger
    @ObservedObject var connector = PhoneConnector.shared
    @ObservedObject var imuModel = ImuDataModel()
    @State var motionStarted: Bool = false
    @State private var selection: Tab = .controls
    
    @State var response: String = ""
    @State var question: String = ""
    enum Tab {
        case controls, interact, question, acc, ori
    }
    var body: some View {
        TabView(selection: $selection) {
            controlView.tag(Tab.controls)
            interactView.tag(Tab.interact)
            questionView.tag(Tab.question)
//            accView.tag(Tab.acc)
//            oriView.tag(Tab.ori)
        }
        
    }
}


extension ChartFirebaseView {
    
    var controlView: some View {
        HStack {
            VStack {
                Button {
                    imuModel.toggleSave()
                    
                } label: {
                    Image(systemName: imuModel.saveRunning ? "xmark" : "play")
                }
                .tint(.red)
                .font(.title2)
                Text(imuModel.saveRunning ? "Stop Save": "Start Save")
            }
            VStack {
                Button {
                    imuModel.toggleMotion()
                    workoutManager.toggleWorkout()
                } label: {
                    Image(systemName: imuModel.imuRunning ? "xmark" : "play")
                }
                .tint(.yellow)
                .font(.title2)
                Text(imuModel.imuRunning ? "Stop IMU" : "Start IMU")
            }
        }
    }
    var interactView: some View{
        VStack{
            HStack(alignment: .center, spacing: 6){
                TextField("Respond to Gemini", text: $response)
                    .onChange(of: response){ newValue in
                        if !newValue.isEmpty {
                            connector.sendTextToPhone(newValue){
                                DispatchQueue.main.async {
                                    self.response = ""
                                }
                            }
                            

                        }
                    }
            }
            Text(connector.model_response)
        }
    }
    var questionView: some View{
        VStack{
            HStack {
               Text("?")
               TextField("Ask Gemini", text: $question)
                   .onChange(of: question) { newValue in
                       if !newValue.isEmpty {
                           connector.sendQuestionToPhone(newValue){
                               DispatchQueue.main.async {
                                   self.question = ""
                               }
                           }
                       }
                   }
           }
        Text(connector.model_answer)


        }
    }
    var accView: some View {
        VStack(alignment: .center){
            LazyHStack(alignment: .center) {
                DataItemView(dataColor: Color("mPurple"), dataName: "X", dataValue: imuModel.accModel.acc_x().last ?? 0.0)
                DataItemView(dataColor: Color("mPink"), dataName: "Y", dataValue: imuModel.accModel.acc_y().last ?? 0.0)
                DataItemView(dataColor: Color("mGreen"), dataName: "Z", dataValue: imuModel.accModel.acc_z().last ?? 0.0)
            }
            .frame(height: 50)
            Spacer()
            LineChartView(dataPoints_X: imuModel.accModel.acc_x(), dataPoints_Y: imuModel.accModel.acc_y(), dataPoints_Z: imuModel.accModel.acc_z())
                .padding(.trailing)
        }
        .padding(.vertical)
    }
    
    var oriView: some View {
        VStack(alignment: .center){
            LazyHStack(alignment: .center) {
                DataItemView(dataColor: Color("mPurple"), dataName: "", dataValue: imuModel.gyroModel.pitch_x().last ?? 0.0)
                DataItemView(dataColor: Color("mPink"), dataName: "Y", dataValue: imuModel.gyroModel.roll_y().last ?? 0.0)
                DataItemView(dataColor: Color("mGreen"), dataName: "Z", dataValue: imuModel.gyroModel.yaw_z().last ?? 0.0)
            }
            .frame(height: 50)
            Spacer()
            LineChartView(dataPoints_X: imuModel.gyroModel.pitch_x(), dataPoints_Y: imuModel.gyroModel.roll_y(), dataPoints_Z: imuModel.gyroModel.yaw_z())
                .padding(.trailing)
        }
        .padding(.vertical)
    }
}



struct ChartFirebaseView_Previews: PreviewProvider {
    static var previews: some View {
        ChartFirebaseView()
    }
}
