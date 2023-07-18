import NIO
import NIOPosix

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
                    try socketBootstrap.bind(host: "127.0.0.1", port: 8080)
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
}
