//
//  LineChart.swift
//  WatchFirebase Watch App
//
//  Created by Min  on 2024/06/21.
//

import SwiftUI


struct AxisChartView: View{
    var yMax: Double
    var yMin: Double
    
    var body: some View {
        GeometryReader { geometry in
            let height = geometry.size.height
            let width = geometry.size.width
            ZStack(alignment: .leading) {
                
                Path { path in
                    path.move(to: CGPoint(x: 20, y: height))
                    path.addLine(to: CGPoint(
                      x: 20,
                      y: 0)
                    )
                    path.move(to: CGPoint(x: 20, y: height))
                    path.addLine(to: CGPoint(
                      x: width,
                      y: height)
                    )
                    
                }
                .stroke(Color(.gray), style: StrokeStyle(lineWidth: 1, lineCap: .round, lineJoin: .round))
                VStack(alignment: .leading) {
                    Text(String(format: "%.2f", yMax))
                    Spacer()
                    Text(String(format: "%.2f", yMin))
                }
                .font(.system(size: 8))
                VStack(alignment: .trailing) {
                    Spacer()
                    HStack(alignment: .bottom) {
                        Spacer()
                        Text(Date.now, style: .time)
                            .font(.system(size: 8))
                    }
                    
                }
                
            }
        }
    }
}

struct LineView: View {
    var dataPoints: [Double]
    
    var highestPoint: Double
    var lowestPoint: Double
    
    var body: some View {
        GeometryReader { geometry in
            let height = geometry.size.height
            let width = geometry.size.width
            
            Path { path in
                path.move(to: CGPoint(x: 0, y: height * self.ratio(for: 0)))
                
                for index in 1..<dataPoints.count {
                    path.addLine(to: CGPoint(
                        x: CGFloat(index) * width / CGFloat(dataPoints.count - 1),
                        y: height * self.ratio(for: index))
                    )
                }
            }
            .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
        }
        .padding(.vertical)
        
    }
    
    
    private func ratio(for index: Int) -> Double {
        
        1 - ((dataPoints[index] - lowestPoint) / (highestPoint - lowestPoint))
//        1 - (dataPoints[index] / highestPoint)
    }
    
}


struct LineChartView: View {
    var dataPoints_X: [Double]
    var dataPoints_Y: [Double]
    var dataPoints_Z: [Double]
    
    var maxPoint: Double {

        let max_x = dataPoints_X.max() ?? 1.0
        let max_y = dataPoints_Y.max() ?? 1.0
        let max_z = dataPoints_Z.max() ?? 1.0
        let max = [max_x, max_y, max_z].max() ?? 1.0
        return max
    }
    var minPoint: Double {
        let min_x = dataPoints_X.min() ?? 1.0
        let min_y = dataPoints_Y.min() ?? 1.0
        let min_z = dataPoints_Z.min() ?? 1.0
        let min = [min_x, min_y, min_z].min() ?? -1.0
        return min
    }
    
    

      var body: some View {
          ZStack(alignment: .leading) {
              AxisChartView(yMax: maxPoint, yMin: minPoint)
              LineView(dataPoints: dataPoints_X, highestPoint: maxPoint, lowestPoint: minPoint)
                  .accentColor(Color("mPurple"))
              LineView(dataPoints: dataPoints_Y, highestPoint: maxPoint, lowestPoint: minPoint)
                  .accentColor(Color("mPink"))
              LineView(dataPoints: dataPoints_Z, highestPoint: maxPoint, lowestPoint: minPoint)
                  .accentColor(Color("mGreen"))
              Spacer()
          }
          .frame(height: 100)
          .padding(.trailing)
      }
}


