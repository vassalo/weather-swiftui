//
//  ContentView.swift
//  SwiftUI-Weather
//
//  Created by Daniel Vassalo on 08/11/22.
//

import SwiftUI
import CoreLocation

struct ContentView: View {
    
    @State private var isNight = false
    @StateObject var locationViewModel = LocationViewModel()
    
    var body: some View {
        ZStack {
            BackgroundView(isNight: $isNight)
            switch locationViewModel.authorizationStatus {
                case .notDetermined:
                    AnyView(RequestLocationView())
                        .environmentObject(locationViewModel)
                case .restricted:
                    ErrorView(errorText: "Location use is restricted.")
                case .denied:
                    ErrorView(errorText: "The app does not have location permissions. Please enable them in settings.")
                case .authorizedAlways, .authorizedWhenInUse:
                    WeatherView(isNight: $isNight)
                        .environmentObject(locationViewModel)
                default:
                    Text("Unexpected status")
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(Network())
    }
}

struct WeatherDayView: View {
    
    var dayOfWeek: String
    var imageName: String
    var temperature: Float
    
    var body: some View {
        VStack {
            Text(dayOfWeek)
                .font(.system(size: 16, weight: .medium, design: .default))
                .foregroundColor(.white)
            Image(systemName: imageName)
                .renderingMode(.original)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 40, height: 40)
            
            Text("\(String(format: "%.0f", temperature))°")
                .font(.system(size: 28, weight: .medium))
                .foregroundColor(.white)
            
        }
    }
    
}

struct BackgroundView: View {
    
    @Binding var isNight: Bool
    
    var body: some View {
        LinearGradient(gradient: Gradient(colors: [
                            isNight ? .black : .blue,
                            isNight ? .gray : Color("lightBlue")
                        ]),
                       startPoint: .topLeading,
                       endPoint: .bottomTrailing)
        .ignoresSafeArea(.all)
    }
}

struct CityTextView: View {
    
    @EnvironmentObject var locationViewModel: LocationViewModel
    
    var body: some View {
        Text(getLocationCityAndState())
            .font(.system(size: 32, weight: .medium, design: .default))
            .foregroundColor(.white)
            .multilineTextAlignment(.center)
            .padding()
    }
    
    func getLocationCityAndState() -> String {
        guard let placemark = locationViewModel.currentPlacemark else {
            return ""
        }
        let state = placemark.administrativeArea ?? ""
        let city = placemark.locality ?? ""
        return city + ", " + state
    }
}

struct MainWeatherStatusView: View {
    var imageName: String
    var temperature: Float
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: imageName)
                .renderingMode(.original)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 180, height: 180)
            
            Text("\(String(format: "%.0f", temperature))° C")
                .font(.system(size: 70, weight: .medium))
                .foregroundColor(.white)
        }.padding(.bottom, 40)
    }
}

struct RequestLocationView: View {
    @EnvironmentObject var locationViewModel: LocationViewModel
    
    var body: some View {
        VStack {
            Image(systemName: "location.circle")
                .resizable()
                .frame(width: 100, height: 100, alignment: .center)
                .foregroundColor(/*@START_MENU_TOKEN@*/.blue/*@END_MENU_TOKEN@*/)
            Button(action: {
                locationViewModel.requestPermission()
            }, label: {
                Label("Allow tracking", systemImage: "location")
            })
                .padding(10)
                .foregroundColor(.white)
                .background(Color.blue)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            Text("We need your permission to track you.")
                .foregroundColor(.white)
                .font(.caption)
        }
    }
}

struct ErrorView: View {
    var errorText: String
    
    var body: some View {
        VStack {
            Image(systemName: "xmark.octagon")
                    .resizable()
                .frame(width: 100, height: 100, alignment: .center)
            Text(errorText)
        }
        .padding()
        .foregroundColor(.white)
        .background(Color.red)
    }
}

struct WeatherView: View {
    
    @EnvironmentObject var network: Network
    @EnvironmentObject var locationViewModel: LocationViewModel
    @Binding var isNight: Bool

    var body: some View {
        if network.dailyData != nil {
            VStack {
                CityTextView()
                
                MainWeatherStatusView(imageName: isNight ? "moon.stars.fill" : "cloud.sun.fill",
                                      temperature: network.dailyData!.daily.temperature_2m_max.first!)
                
                HStack(spacing: 20) {
                    ForEach(1...5, id: \.self) { i in
                        WeatherDayView(dayOfWeek: getWeekDay(offset: i),
                                       imageName: getWeatherIcon(fromTemperature: network.dailyData!.daily.temperature_2m_max[i]),
                                       temperature: network.dailyData!.daily.temperature_2m_max[i])
                    }
                }
                
                Spacer()
                
                Button {
                    isNight.toggle()
                } label: {
                    WeatherButton(title: "Change Day Time",
                                  textColor: .blue,
                                  backgroundColor: .white)
                }
                
                Spacer()
            }
        } else {
            ProgressView()
                .onAppear() {
                    locationViewModel.registerLocationChangeListener(callback: { updateForecast() })
                }
        }
    }
    
    func updateForecast() -> Void {
        network.getTemperature(latitude: locationViewModel.lastSeenLocation?.coordinate.latitude ?? 0,
                               longitude: locationViewModel.lastSeenLocation?.coordinate.longitude ?? 0)
    }
    
    func getWeekDay(offset: Int) -> String {
        let currentDate = Date()
        var dateComponent = DateComponents()
        dateComponent.day = offset
        let futureDate = Calendar.current.date(byAdding: dateComponent, to: currentDate)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EE"
        return dateFormatter.string(from: futureDate!)
    }
    
    func getWeatherIcon(fromTemperature: Float) -> String {
        if fromTemperature >= 26 {
            return "sun.max.fill"
        } else {
            return "cloud.sun.fill"
        }
    }
}
