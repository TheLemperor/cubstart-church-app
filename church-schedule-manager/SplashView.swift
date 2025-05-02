//
//  SplashView.swift
//  church-schedule-manager
//
//  Created by Lemuel Sumardy on 5/1/25.
//

import SwiftUI

struct SplashView: View {
    @State private var isActive = false
    
    var body: some View {
        if isActive {
            MainView()
        } else {
            VStack {
                Image(systemName: "cross.fill") // Placeholder for your church logo
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 150, height: 150)
                    .foregroundColor(.blue)
                
                Text("Church Schedule Manager")
                    .font(.title)
                    .padding()
            }
            .onAppear {
                // Simulate a delay for the splash screen
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation {
                        self.isActive = true
                    }
                }
            }
        }
    }
}
