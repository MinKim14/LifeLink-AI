//
//  AutheticationHeader.swift
//  WatchFirebase
//
//  Created by Min  on 2022/12/15.
//

import SwiftUI

struct RoundedShape: Shape {
    var corners: UIRectCorner
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: 80, height: 80))
        
        return Path(path.cgPath)
    }
}

struct AuthHeaderView: View {
    let title1: String
    let title2: String
    
    
    var body: some View {
        VStack {
            VStack(alignment: .leading){
                HStack { Spacer() }
                Text(title1)
                    .font(.largeTitle)
                    .fontWeight(.semibold)
                Text(title2)
                    .font(.largeTitle)
                    .fontWeight(.semibold)
            }
            .frame(height: 260)
            .padding(.leading)
            .background(Color(.systemBlue))
            .foregroundColor(.white)
            .clipShape(RoundedShape(corners: [.bottomRight]))
            
            
        }
    }
}

struct AuthHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        AuthHeaderView(title1: "Hello", title2: "Welcome Back")
    }
}
