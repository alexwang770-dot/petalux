//
//  BLEManager.swift
//  Petalux
//
//  Created by Max Zhang on 4/25/26.
//

import CoreBluetooth
import Combine

class BLEManager: NSObject, ObservableObject {
    
    // Match these UUIDs with your ESP32 sketch
    let serviceUUID       = CBUUID(string: "12345678-1234-1234-1234-123456789012")
    let characteristicUUID = CBUUID(string: "87654321-4321-4321-4321-210987654321")
    
    private var centralManager: CBCentralManager!
    private var peripheral: CBPeripheral?
    private var characteristic: CBCharacteristic?
    
    @Published var isScanning        = false
    @Published var isConnected       = false
    @Published var discoveredDevices: [CBPeripheral] = []
    @Published var receivedMessage   = ""
    @Published var statusMessage     = "Idle"
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func startScanning() {
        guard centralManager.state == .poweredOn else { return }
        discoveredDevices.removeAll()
        isScanning = true
        statusMessage = "Scanning..."
        centralManager.scanForPeripherals(withServices: [serviceUUID])
    }
    
    func stopScanning() {
        centralManager.stopScan()
        isScanning = false
        statusMessage = "Scan stopped"
    }
    
    func connect(to peripheral: CBPeripheral) {
        self.peripheral = peripheral
        centralManager.stopScan()
        isScanning = false
        statusMessage = "Connecting to \(peripheral.name ?? "Unknown")..."
        centralManager.connect(peripheral)
    }
    
    func disconnect() {
        guard let peripheral else { return }
        centralManager.cancelPeripheralConnection(peripheral)
    }
    
    func send(_ text: String) {
        guard let characteristic, let data = text.data(using: .utf8) else { return }
        peripheral?.writeValue(data, for: characteristic, type: .withResponse)
    }
}

// MARK: - CBCentralManagerDelegate
extension BLEManager: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            statusMessage = "Bluetooth ready"
        } else {
            statusMessage = "Bluetooth unavailable: \(central.state.rawValue)"
        }
    }
    
    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any],
                        rssi RSSI: NSNumber) {
        if !discoveredDevices.contains(peripheral) {
            discoveredDevices.append(peripheral)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        isConnected = true
        statusMessage = "Connected to \(peripheral.name ?? "Unknown")"
        peripheral.delegate = self
        peripheral.discoverServices([serviceUUID])
    }
    
    func centralManager(_ central: CBCentralManager,
                        didDisconnectPeripheral peripheral: CBPeripheral,
                        error: Error?) {
        isConnected = false
        statusMessage = "Disconnected"
        self.peripheral = nil
        self.characteristic = nil
    }
    
    func centralManager(_ central: CBCentralManager,
                        didFailToConnect peripheral: CBPeripheral,
                        error: Error?) {
        statusMessage = "Failed to connect: \(error?.localizedDescription ?? "Unknown error")"
    }
}

// MARK: - CBPeripheralDelegate
extension BLEManager: CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services {
            peripheral.discoverCharacteristics([characteristicUUID], for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverCharacteristicsFor service: CBService,
                    error: Error?) {
        guard let characteristics = service.characteristics else { return }
        for char in characteristics {
            if char.uuid == characteristicUUID {
                characteristic = char
                peripheral.setNotifyValue(true, for: char) // subscribe to notifications
                statusMessage = "Ready to communicate!"
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateValueFor characteristic: CBCharacteristic,
                    error: Error?) {
        guard let data = characteristic.value,
              let message = String(data: data, encoding: .utf8) else { return }
        DispatchQueue.main.async {
            self.receivedMessage = message
        }
    }
}
