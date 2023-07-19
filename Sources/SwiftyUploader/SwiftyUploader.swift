import NIO
import NIOPosix
import Network
import NIOCore
import NIOPosix
import NIOHTTP1
import Dispatch




@available(iOS 13.4, *)
public class SwiftyUploader {
    public private(set) var text = "Hello, World!"
    private var loopGroup:MultiThreadedEventLoopGroup?

    public init() {
    }
    
    public func run() {
        DispatchQueue.global(qos: .background).async {
            if(self.loopGroup == nil) {
                self.loopGroup = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
            }
            if let loopGroup = self.loopGroup {
                let socketBootstrap = ServerBootstrap(group: loopGroup)
                // Specify backlog and enable SO_REUSEADDR for the server itself
                    .serverChannelOption(ChannelOptions.backlog, value: 256)
                    .serverChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
                
                // Set the handlers that are applied to the accepted Channels
                    .childChannelInitializer{
                        channel in
                        channel.pipeline.configureHTTPServerPipeline(withErrorHandling: true).flatMap {
                            channel.pipeline.addHandler(HTTPHandler())
                        }
                    }
                
                // Enable SO_REUSEADDR for the accepted Channels
                    .childChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
                    .childChannelOption(ChannelOptions.maxMessagesPerRead, value: 1)
                
                do {
                    let serverChannel =
                    try socketBootstrap.bind(host: "0.0.0.0", port: 80)
                        .wait()
                    print("Server running on:", serverChannel.localAddress!)
                    
                    try serverChannel.closeFuture.wait() // runs forever
                }
                catch {
                    fatalError("failed to start server: \(error)")
                }
            }
            
        }
    }
    
    public func stop() {
        do {
            try self.loopGroup?.syncShutdownGracefully()
        } catch let error {
            print("Error shutting down \(error.localizedDescription)")
            exit(0)
        }
        print("Client connection closed")
    }
    
    public func getIPAddress() -> String {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>? = nil
        if getifaddrs(&ifaddr) == 0 {
            var ptr = ifaddr
            while ptr != nil {
                defer { ptr = ptr?.pointee.ifa_next }

                guard let interface = ptr?.pointee else { return "" }
                let addrFamily = interface.ifa_addr.pointee.sa_family
                if addrFamily == UInt8(AF_INET){

                    // wifi = ["en0"]
                    // wired = ["en2", "en3", "en4"]
                    // cellular = ["pdp_ip0","pdp_ip1","pdp_ip2","pdp_ip3"]

                    let name: String = String(cString: (interface.ifa_name))
                    if  name == "en0" {
                        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                        getnameinfo(interface.ifa_addr, socklen_t((interface.ifa_addr.pointee.sa_len)), &hostname, socklen_t(hostname.count), nil, socklen_t(0), NI_NUMERICHOST)
                        address = String(cString: hostname)
                    }
                }
            }
            freeifaddrs(ifaddr)
        }
        return address ?? ""
    }
}
