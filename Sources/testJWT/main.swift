import Foundation
import Kitura
import LoggerAPI
import HeliumLogger
import Application

do {

    HeliumLogger.use(LoggerMessageType.info)

    if #available(OSX 10.12, *) {
        let app = try App()
        try app.run()
    } 

} catch let error {
    Log.error(error.localizedDescription)
}
