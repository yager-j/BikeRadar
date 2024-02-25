//
//  MapView.swift
//  BikeRadar
//
//  Created by Joanne Yager on 2024-02-23.
//

import SwiftUI
import MapKit

struct MapView: View {
    @ObservedObject var dataService: LocationsDataService
    @ObservedObject var locationsHandler = LocationsHandler.shared
    @State private var position: MapCameraPosition = .userLocation(followsHeading: true, fallback: .automatic)
    @State private var visibleRegion: MKCoordinateRegion?
    @State private var route: MKRoute?
    @State private var showRoute = false
    @State private var selectedStation: Station?
    @State private var selectedCity: MKCoordinateRegion?
    @State var network: Network
    
    var body: some View {
        Map(position: $position) {
            ForEach(dataService.stations) { station in
                Annotation(station.name ?? "\(network.name ?? "Bike") Station", coordinate: CLLocationCoordinate2D(latitude: station.latitude, longitude: station.longitude)) {
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 30, height: 30)
                        .overlay {
                            Image(systemName: "mappin.circle")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        }
                        .onTapGesture {
                            selectedStation = station
                        }
                }
            }
            
            if let route {
                if showRoute {
                    MapPolyline(route)
                        .stroke(.blue, lineWidth: 5)
                }
            }
            
            UserAnnotation()
        }
        .onAppear {
            locationsHandler.requestATTPermission()
        }
        .onAppear {
            if let city = network.location {
                selectedCity = MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: city.latitude, longitude: city.longitude), span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1))
            }
            if let selectedCity {
                position = .region(selectedCity)
            }
        }
        .mapStyle(.standard(elevation: .realistic))
        .safeAreaInset(edge: .bottom) {
            if let selectedStation {
                ItemInfoView(route: $route, showRoute: $showRoute, selectedStation: selectedStation)
            }
        }
        .onChange(of: dataService.stations) {
            position = .automatic
        }
        .onChange(of: selectedStation) {
            if let selectedStation {
                let selectedStationRegion = MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: selectedStation.latitude, longitude: selectedStation.longitude), span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02))
                position = .region(selectedStationRegion)
            }
        }
        .onChange(of: showRoute) {
            if let route {
                let routeRect = route.polyline.boundingMapRect
               // let paddedRouteRect = routeRect.insetBy(dx: -100, dy: -100)
                var routeRegion = MKCoordinateRegion(routeRect)
              //  routeRegion.span = MKCoordinateSpan(latitudeDelta: 0.043, longitudeDelta: 0.043)
                position = .region(routeRegion)
            }
        }
        .onMapCameraChange { context in
            visibleRegion = context.region
        }
        .mapControls {
            MapUserLocationButton()
            MapCompass()
            MapScaleView()
        }
    }
}

/*#Preview {
 MapView()
 }*/
