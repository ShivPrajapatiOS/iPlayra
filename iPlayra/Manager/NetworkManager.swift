//
//  NetworkManager.swift
//  iPlay
//
//  Created by Shiv on 11/11/25.
//

import SwiftUI
import Foundation
import Network
import Combine

class NetworkManager: ObservableObject {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")

    @Published var isConnected = true
    @Published var connectionType: NWInterface.InterfaceType? = nil
    
    @Published var isExpensive = false

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            // Status check
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                self?.isExpensive = path.isExpensive
                
                // Connection Type check
                if path.usesInterfaceType(.wifi) {
                    self?.connectionType = .wifi
                } else if path.usesInterfaceType(.cellular) {
                    self?.connectionType = .cellular
                } else if path.usesInterfaceType(.wiredEthernet) {
                    self?.connectionType = .wiredEthernet
                } else if path.usesInterfaceType(.loopback) {
                    self?.connectionType = .loopback
                } else {
                    self?.connectionType = .other
                }
            }
        }
        
        // Start monitoring on a background queue
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
    
    // Convenience property for readable type
    var connectionTypeString: String {
        guard let type = connectionType else { return "Unknown" }
        switch type {
        case .wifi: return "Wi-Fi"
        case .cellular: return "Cellular Data"
        case .wiredEthernet: return "Wired Ethernet"
        case .loopback: return "Loopback"
        case .other: return "Other"
        @unknown default: return "Unknown"
        }
    }
}
