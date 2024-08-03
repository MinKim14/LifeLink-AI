//
//  DataItemView.swift
//  WatchFirebase Watch App
//
//  Created by Min  on 2022/12/23.
//

import SwiftUI

struct DataItemView: View {
    @Environment(\.colorScheme) var colorScheme

    var dataColor: Color
    var dataName: String
    var dataValue: Double
    var body: some View {
        ZStack(alignment: .center) {
            RoundedRectangle(cornerRadius: 12.5)
                .stroke(Color.white)
                .foregroundColor(.clear)
                .opacity(0.7)
            HStack(alignment: .center) {
                Circle()
                    .fill(dataColor)
                    .frame(width: 10, height: 10)
                Spacer()
                VStack(alignment: .leading) {
//                    Text(String("W"))
                    Text(String(format: "%.1f", dataValue))
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                        .font(.footnote)
                    Text(dataName)
                        .foregroundColor(.gray)
                        .font(.footnote)
                }
                Spacer()
                
            }.padding(.all)
            
        }
//        .frame(width: 60)
        
    }
}


