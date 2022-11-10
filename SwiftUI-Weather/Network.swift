//
//  Network.swift
//  SwiftUI-Weather
//
//  Created by Daniel Vassalo on 09/11/22.
//

import SwiftUI

class Network: ObservableObject {
    
    @Published var dailyData: DailyWeatherData?
    
    func getTemperature(latitude: Double, longitude: Double) {
        guard let url = URL(string: "https://api.open-meteo.com/v1/forecast?latitude=\(latitude)&longitude=\(longitude)&daily=temperature_2m_max&timezone=GMT") else { fatalError("Missing URL")
        }
        
        let urlRequest = URLRequest(url: url)

        let dataTask = URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
            if let error = error {
                print("Request error: ", error)
                return
            }

            guard let response = response as? HTTPURLResponse else { return }

            if response.statusCode == 200 {
                guard let data = data else { return }
                DispatchQueue.main.async {
                    do {
                        let decodedDailyData = try JSONDecoder().decode(DailyWeatherData.self, from: data)
                        self.dailyData = decodedDailyData
                    } catch let error {
                        print("Error decoding: ", error)
                    }
                }
            }
        }

        dataTask.resume()
    }
    
}

struct DailyWeatherData: Decodable {
    var daily: DailyData
    
    struct DailyData: Decodable  {
        let time: [String]
        let temperature_2m_max: [Float]
    }
}
