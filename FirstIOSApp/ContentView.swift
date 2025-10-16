//
//  ContentView.swift
//  FirstIOSApp
//
//  Created by admin on 15.10.2025.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
            Text("My First X Code Project").font(.title3).foregroundColor(.blue)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
