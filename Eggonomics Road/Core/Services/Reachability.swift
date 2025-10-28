import Network

final class Reachability {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "reachability.queue")

    func isConnected() async -> Bool {
        await withCheckedContinuation { cont in
            monitor.pathUpdateHandler = { path in
                cont.resume(returning: path.status == .satisfied)
                self.monitor.cancel()
            }
            monitor.start(queue: queue)
        }
    }
}
