//
//  Screen 3.swift
//  Petalux
//
//  Created by Alexander Wang on 4/22/26.
//
import SwiftUI

struct OpenCloseScreen: View {
    @State private var isOpen = false
    
    var body: some View {
        ZStack {
            // Background color changes based on state
            (isOpen ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                
                // Icon that animates
                Image(systemName: isOpen ? "door.left.hand.open" : "door.left.hand.closed")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 150)
                    .foregroundColor(isOpen ? .green : .red)
                    .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isOpen)
                
                // Status text
                Text(isOpen ? "Open" : "Closed")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(isOpen ? .green : .red)
                    .animation(.easeInOut, value: isOpen)
                
                // Button
                Button(action: {
                    withAnimation {
                        isOpen.toggle()
                    }
                }) {
                    Text(isOpen ? "Close" : "Open")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(width: 200, height: 55)
                        .background(isOpen ? Color.red : Color.green)
                        .cornerRadius(15)
                        .shadow(radius: 5)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
