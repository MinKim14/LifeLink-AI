//
//  ContentView.swift
//  WatchFirebase Watch App
//
//  Created by Min  on 2022/12/13.
//

import SwiftUI



struct ContentView: View {
    var body: some View {
        Group {
                VStack {
                    ChartFirebaseView()
                }
                .padding()
            }
//        }
        
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


