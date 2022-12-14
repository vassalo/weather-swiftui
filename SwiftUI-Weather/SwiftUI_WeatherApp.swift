//
//  SwiftUI_WeatherApp.swift
//  SwiftUI-Weather
//
//  Created by Daniel Vassalo on 08/11/22.
//

import SwiftUI

@main
struct SwiftUI_WeatherApp: App {
    
    var network = Network()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(network)
        }
    }
}
