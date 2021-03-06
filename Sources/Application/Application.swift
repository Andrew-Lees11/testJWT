import Foundation
import Kitura
import LoggerAPI
import Configuration
import CloudEnvironment
import KituraContracts
import Health
import SwiftJWT
import CryptorRSA

public let projectPath = ConfigurationManager.BasePath.project.path
public let health = Health()

@available(OSX 10.12, *)
public class App {
    let router = Router()
    let cloudEnv = CloudEnv()
    let rsaPubKey = 
"""
-----BEGIN PUBLIC KEY-----
MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCqGKukO1De7zhZj6+H0qtjTkVxwTCpvKe4eCZ0
FPqri0cb2JZfXJ/DgYSF6vUpwmJG8wVQZKjeGcjDOL5UlsuusFncCzWBQ7RKNUSesmQRMSGkVb1/
3j+skZ6UtW+5u09lHNsj6tQ51s1SPrCBkedbNf0Tp0GbMJDyR4e9T04ZZwIDAQAB
-----END PUBLIC KEY-----
"""
    let rsaPrivKey = 
"""
-----BEGIN RSA PRIVATE KEY-----
MIICXAIBAAKBgQCqGKukO1De7zhZj6+H0qtjTkVxwTCpvKe4eCZ0FPqri0cb2JZfXJ/DgYSF6vUp
wmJG8wVQZKjeGcjDOL5UlsuusFncCzWBQ7RKNUSesmQRMSGkVb1/3j+skZ6UtW+5u09lHNsj6tQ5
1s1SPrCBkedbNf0Tp0GbMJDyR4e9T04ZZwIDAQABAoGAFijko56+qGyN8M0RVyaRAXz++xTqHBLh
3tx4VgMtrQ+WEgCjhoTwo23KMBAuJGSYnRmoBZM3lMfTKevIkAidPExvYCdm5dYq3XToLkkLv5L2
pIIVOFMDG+KESnAFV7l2c+cnzRMW0+b6f8mR1CJzZuxVLL6Q02fvLi55/mbSYxECQQDeAw6fiIQX
GukBI4eMZZt4nscy2o12KyYner3VpoeE+Np2q+Z3pvAMd/aNzQ/W9WaI+NRfcxUJrmfPwIGm63il
AkEAxCL5HQb2bQr4ByorcMWm/hEP2MZzROV73yF41hPsRC9m66KrheO9HPTJuo3/9s5p+sqGxOlF
L0NDt4SkosjgGwJAFklyR1uZ/wPJjj611cdBcztlPdqoxssQGnh85BzCj/u3WqBpE2vjvyyvyI5k
X6zk7S0ljKtt2jny2+00VsBerQJBAJGC1Mg5Oydo5NwD6BiROrPxGo2bpTbu/fhrT8ebHkTz2epl
U9VQQSQzY1oZMVX8i1m5WUTLPz2yLJIBQVdXqhMCQBGoiuSoSjafUhV7i1cEGpb88h5NBYZzWXGZ
37sJ5QsW+sJyoNde3xH8vdXhzU7eT82D6X/scw9RZz+/6rCJ4p0=
-----END RSA PRIVATE KEY-----
"""
    var globalJWT = JWT(claims: ClaimsStandardJWT(iss: "Kitura"))
    var globalJWTString: String?
    
    public init() throws {
        // Run the metrics initializer
        initializeMetrics(router: router)
        globalJWTString = try globalJWT.sign(using: .rs256(privateKey: self.rsaPrivKey.data(using: .utf8)!))
    }

    func postInit() throws {
        // Endpoints
        initializeHealthRoutes(app: self)
        router.get("/signVerifyJWT") { request, response, next in
            var jwt = JWT(claims: ClaimsStandardJWT(iss: "Kitura"))
            let jwtString = try jwt.sign(using: .rs256(privateKey: self.rsaPrivKey.data(using: .utf8)!))
            let verified = JWT<ClaimsStandardJWT>.verify(jwtString, using: .rs256(publicKey: self.rsaPubKey.data(using: .utf8)!))
            response.send(verified.value)
            next()
        }
        router.get("/verifyJWT") { request, response, next in
            if let jwtString = self.globalJWTString {
                let verified = JWT<ClaimsStandardJWT>.verify(jwtString, using: .rs256(publicKey: self.rsaPubKey.data(using: .utf8)!))
                response.send(verified.value)
            }
            next()
        }
        router.get("/signJWT") { request, response, next in
            var jwt = JWT(claims: ClaimsStandardJWT(iss: "Kitura"))
            let jwtString = try jwt.sign(using: .rs256(privateKey: self.rsaPrivKey.data(using: .utf8)!))
            response.send(jwtString)
            next()
        }
        router.get("/rsaPrivKey") { request, response, next in
            let _ = try CryptorRSA.createPrivateKey(withPEM: self.rsaPrivKey)
            response.send("PrivKey")
            next()
        }
        router.get("/rsaPublicKey") { request, response, next in
            let _ = try CryptorRSA.createPublicKey(withPEM: self.rsaPubKey)
            response.send("PubKey")
            next()
        }
        router.get("/rsaEncrypt") { request, response, next in
            let rsaPriv = try CryptorRSA.createPrivateKey(withPEM: self.rsaPrivKey)
            let rsaPub = try CryptorRSA.createPublicKey(withPEM: self.rsaPubKey)
            let plaintext = try CryptorRSA.createPlaintext(with: "Hello", using: .utf8)
            let encrypted = try plaintext.encrypted(with: rsaPub, algorithm: .gcm)
            let decrypted = try encrypted?.decrypted(with: rsaPriv, algorithm: .gcm)
            try response.send(decrypted?.string(using: .utf8))
            next()
        }
    }

    public func run() throws {
        try postInit()
        Kitura.addHTTPServer(onPort: cloudEnv.port, with: router)
        Kitura.run()
    }
}
