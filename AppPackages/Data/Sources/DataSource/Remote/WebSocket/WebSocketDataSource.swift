public protocol WebSocketDataSourceProtocol {}

public actor WebSocketDataSource: WebSocketDataSourceProtocol {
    private let websocketmanager: WebSocketManager

    init(webSocketManager: WebSocketManager) {
        websocketmanager = webSocketManager
    }
}
