//
//  ItemInfoView.swift
//  BikeRadar
//
//  Created by Joanne Yager on 2024-02-24.
//

import SwiftUI
import MapKit

struct ItemInfoView: View {
    @ObservedObject var locationsHandler = LocationsHandler.shared
    @State private var lookAroundScene: MKLookAroundScene?
    @State private var showLookAround = false
    @Binding var route: MKRoute?
    @Binding var showRoute: Bool
    
    var selectedStation: Station
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            InfoHeaderView(selectedStation: selectedStation, showLookAround: $showLookAround, lookAroundScene: $lookAroundScene)
            
            ZStack {
                VStack(alignment: .leading, spacing: 6) {
                    InfoDetailsView(selectedStation: selectedStation, route: route, showRoute: $showRoute)
                    
                    InfoFooterView(selectedStation: selectedStation, showRoute: $showRoute)
                }
                if let lookAroundScene {
                    LookAroundPreview(initialScene: lookAroundScene)
                        .frame(height: 128)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 15).fill(Color.white))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding()
        .onAppear {
            getDirections(station: selectedStation)
        }
        .onChange(of: selectedStation) {
            getDirections(station: selectedStation)
            showRoute = false
            showLookAround = false
        }
    }
    
    func getDirections(station: Station) {
        route = nil
        
        let location = locationsHandler.manager.location
        guard let coordinate = location?.coordinate else { return }
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        request.destination = MKMapItem(placemark: .init(coordinate: CLLocationCoordinate2D(latitude: station.latitude, longitude: station.longitude)))
        request.transportType = .walking
        
        Task {
            let directions = MKDirections(request: request)
            let response = try? await directions.calculate()
            withAnimation {
                route = response?.routes.first
            }
        }
    }
}

#Preview {
    ItemInfoView(route: .constant(nil), showRoute: .constant(false), selectedStation: Station(emptySlots: 14, freeBikes: 10, id: "87492ed48d78c573f95e99bc7f87ac9d", latitude: 55.60899, longitude: 12.99907, name: "Malmö C Norra", timestamp: "2024-02-25T08:34:42.895000Z"))
}

struct InfoHeaderView: View {
    var selectedStation: Station
    @Binding var showLookAround: Bool
    @Binding var lookAroundScene: MKLookAroundScene?
    
    var body: some View {
        HStack {
            Text("\(selectedStation.name ?? "")")
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.leading)
                .foregroundColor(.primary)
            Spacer()
            Button {
                showLookAround.toggle()
            } label: {
                Image(systemName: showLookAround ? "info.circle" : "eye")
                    .foregroundColor(.accentColor)
                    .padding()
                    .frame(width: 44, height: 44)
            }
        }
        .onChange(of: showLookAround) {
            if showLookAround {
                getLookAroundScene(station: selectedStation)
            } else {
                lookAroundScene = nil
            }
        }
    }
    
    func getLookAroundScene(station: Station) {
        lookAroundScene = nil
        Task {
            let request = MKLookAroundSceneRequest(coordinate: CLLocationCoordinate2D(latitude: station.latitude, longitude: station.longitude))
            lookAroundScene = try? await request.scene
        }
    }
}

struct InfoDetailsView: View {
    var selectedStation: Station
    var route: MKRoute?
    @Binding var showRoute: Bool
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .bottom, spacing: 4) {
                Text("Free bikes:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(selectedStation.freeBikes)")
                    .font(.caption)
                    .fontWeight(.bold)
            }
            
            HStack(alignment: .bottom, spacing: 4) {
                Text("Empty slots:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                if let emptySlots = selectedStation.emptySlots {
                    Text("\(emptySlots)")
                        .font(.caption)
                        .fontWeight(.bold)
                } else {
                    Text("unknown")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack {
                Image(systemName: "location.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("\(distance ?? "           ")")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Image(systemName: "figure.walk")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("\(travelTime ?? "")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var distance: String? {
        guard let route, route.distance >= 0 else { return nil }
        let formatter = MeasurementFormatter()
        formatter.unitOptions = .providedUnit
        formatter.unitStyle = .medium
        let distanceMeasurement: Measurement<UnitLength>
        if route.distance >= 1000 {
            distanceMeasurement = Measurement(value: route.distance / 1000, unit: UnitLength.kilometers)
        } else {
            distanceMeasurement = Measurement(value: route.distance, unit: UnitLength.meters)
        }
        formatter.numberFormatter.maximumFractionDigits = 1
        return formatter.string(from: distanceMeasurement)
    }
    
    private var travelTime: String? {
        guard let route else { return nil }
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .brief
        formatter.allowedUnits = [.hour, .minute]
        return formatter.string(from: route.expectedTravelTime)
    }
}

struct InfoFooterView: View {
    var selectedStation: Station
    @Binding var showRoute: Bool
    
    var body: some View {
        HStack {
            Button {
                showRoute = true
            } label: {
                Text("See Route")
                    .font(.caption)
            }
            
            Spacer()
            
            Text("Last updated \(timestamp)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var timestamp: String {
        let inputFormatter = ISO8601DateFormatter()
        inputFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let outputFormatter = DateFormatter()
        outputFormatter.dateStyle = .short
        outputFormatter.timeStyle = .short
        
        if let date = inputFormatter.date(from: selectedStation.timestamp) {
            if Calendar.current.isDateInToday(date) {
                outputFormatter.dateStyle = .none
            }
            outputFormatter.locale = Locale(identifier: "en_GB")
            return outputFormatter.string(from: date)
        } else {
            return "Invalid Timestamp"
        }
    }
}
