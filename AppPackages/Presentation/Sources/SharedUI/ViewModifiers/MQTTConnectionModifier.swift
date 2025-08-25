import DataSource
import Entities
import SwiftUI

public struct MQTTConnectionHandler: ViewModifier {
    @EnvironmentObject private var connectionManager: MQTTConnectionManager
    @State private var showConnectionError = false
    @State private var mqttConnectionError: Error?

    private let connectOnAppear: Bool

    public init(connectOnAppear: Bool = true) {
        self.connectOnAppear = connectOnAppear
    }

    public func body(content: Content) -> some View {
        content
            .task {
                if connectOnAppear, connectionManager.connectionStatus == .disconnected {
                    await attemptConnection()
                }
            }
            .alert(Strings.mqttConnectionFailed, isPresented: $showConnectionError) {
                Button(Strings.retry) {
                    Task { await attemptConnection() }
                }
                Button(Strings.cancel, role: .cancel) {}
            } message: {
                Text(
                    mqttConnectionError?.localizedDescription
                        ?? Strings.unableToConnectToMQTTbroker
                )
            }
    }

    private func attemptConnection() async {
        do {
            try await connectionManager.connect()
        } catch {
            mqttConnectionError = error
            showConnectionError = true
        }
    }
}

public extension View {
    func mqttConnectionHandler(connectOnAppear: Bool = true) -> some View {
        modifier(MQTTConnectionHandler(connectOnAppear: connectOnAppear))
    }
}
