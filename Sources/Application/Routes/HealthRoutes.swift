import LoggerAPI
import Health
import KituraContracts

@available(OSX 10.12, *)
func initializeHealthRoutes(app: App) {
    
    app.router.get("/health") { (respondWith: (Status?, RequestError?) -> Void) -> Void in
        if health.status.state == .UP {
            respondWith(health.status, nil)
        } else {
            respondWith(nil, RequestError(.serviceUnavailable, body: health.status))
        }
    }
    
}
