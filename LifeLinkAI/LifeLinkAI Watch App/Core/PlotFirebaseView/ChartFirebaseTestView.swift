//
//  ChartFirebaseTestView.swift
//  WatchFirebase Watch App
//
//  Created by Min  on 2022/12/27.
//

import SwiftUI

struct ChartFirebaseTestView: View {
    @EnvironmentObject var workoutManager: WorkoutMananger

    @ObservedObject var imuModel = ImuDataModel()
    @State var motionStarted: Bool = false
    var body: some View {
        VStack(alignment: .center){
            LazyHStack(alignment: .center) {
                DataItemView(dataColor: Color("mPurple"), dataName: "X", dataValue: imuModel.accModel.acc_x().last ?? 0.0)
                DataItemView(dataColor: Color("mPink"), dataName: "Y", dataValue: imuModel.accModel.acc_y().last ?? 0.0)
                DataItemView(dataColor: Color("mGreen"), dataName: "Z", dataValue: imuModel.accModel.acc_z().last ?? 0.0)
            }
            .frame(height: 50)
            Spacer()
            if(motionStarted){
                LineChartView(dataPoints_X: imuModel.accModel.acc_x(), dataPoints_Y: imuModel.accModel.acc_y(), dataPoints_Z: imuModel.accModel.acc_z())
                .padding(.trailing)
                
            } else{
                Button {
                    imuModel.startMotionMananger(onlyPlot: true)
                    workoutManager.startWorkout(workoutType: .other)
                    motionStarted = true
                } label: {
                    Text("Start Motion Manager")
                }
            }
        }
        .padding(.vertical)
    }
}
