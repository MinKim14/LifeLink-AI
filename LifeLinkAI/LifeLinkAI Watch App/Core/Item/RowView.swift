//
//  RowView.swift
//  WatchFirebase Watch App
//
//  Created by Min  on 2022/12/22.
//

import SwiftUI

struct RowView: View {
    
    var icon: String
    var title: String
    var comment: String
    var iconColor: String
    
    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 12.5)
                .foregroundColor(Color("mDarkGray"))
            HStack {
                ZStack(alignment: .center){
                    RoundedRectangle(cornerRadius: 7.5)
                        .foregroundColor(Color(iconColor))
                        .frame(width: 30, height: 30)
                    Image(systemName: icon)
                        .renderingMode(.template)
                        .foregroundColor(Color.black)
                }
                VStack(alignment: .leading) {
                    Text(title)
                        .font(.caption)
                        .foregroundColor(.white)
                    Text(comment)
                        .font(.footnote)
                        .foregroundColor(.gray)
                }.padding(.all)
            }
            .padding(.horizontal)
        }
        .frame(height: 40)
    }
}

//struct RowView_Previews: PreviewProvider {
//    static var previews: some View {
//        RowView()
//    }
//}
