import SwiftUI
import CoreBluetooth

struct ContentView: View {
    @StateObject private var ble = BLEManager()
    @State private var textToSend = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                
                // Status banner
                Text(ble.statusMessage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                
                // Scan / Disconnect button
                if ble.isConnected {
                    Button(role: .destructive) {
                        ble.disconnect()
                    } label: {
                        Label("Disconnect", systemImage: "xmark.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.horizontal)
                } else {
                    Button {
                        ble.isScanning ? ble.stopScanning() : ble.startScanning()
                    } label: {
                        Label(ble.isScanning ? "Stop Scanning" : "Scan for ESP32",
                              systemImage: ble.isScanning ? "stop.circle" : "antenna.radiowaves.left.and.right")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.horizontal)
                }
                
                // Device list
                if !ble.discoveredDevices.isEmpty {
                    List(ble.discoveredDevices, id: \.identifier) { device in
                        Button {
                            ble.connect(to: device)
                        } label: {
                            HStack {
                                Image(systemName: "cpu")
                                Text(device.name ?? "Unknown Device")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .frame(maxHeight: 200)
                    .listStyle(.insetGrouped)
                }
                
                // Communication panel (shown when connected)
                if ble.isConnected {
                    GroupBox("Received from ESP32") {
                        Text(ble.receivedMessage.isEmpty ? "No data yet..." : ble.receivedMessage)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .foregroundStyle(ble.receivedMessage.isEmpty ? .secondary : .primary)
                    }
                    .padding(.horizontal)
                    
                    GroupBox("Send to ESP32") {
                        HStack {
                            TextField("Type a message", text: $textToSend)
                                .textFieldStyle(.roundedBorder)
                            Button("Send") {
                                ble.send(textToSend)
                                textToSend = ""
                            }
                            .buttonStyle(.bordered)
                            .disabled(textToSend.isEmpty)
                        }
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .navigationTitle("ESP32 BLE")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}


#Preview {
    ContentView()
}
