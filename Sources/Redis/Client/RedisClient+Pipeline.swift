import Foundation

public final class RedisPipeline {
    /// The commands in this pipeline
    var commands = [RedisData]()
    
    /// Adds a command to the pipeline
    public func command(_ command: String, args: [RedisData] = []) {
        let command = RedisData.array([RedisData(bulk: command)] + args)
        self.commands.append(command)
    }
    
    /// Adds a command to the pipeline
    public func command(_ command: String, args: RedisData...) {
        self.command(command, args: args)
    }
}

extension RedisClient {
    /// Executes a pipelined transaction
    public func pipeline(closure: (RedisPipeline)->()) -> Future<[RedisData]> {
        // Fill the pipeline with commnads
        let pipeline = RedisPipeline()
        closure(pipeline)
        
        // Returns a empty fulfilled future if the transaction was empty
        if pipeline.commands.count == 0 {
            return eventLoop.newSucceededFuture(result: [RedisData]())
        }
        
        // Send the commands as a pipeline
        return send(pipeline: pipeline.commands)
    }
    
    /// Executes a multi/exec transaction
    public func multi(closure: (RedisPipeline)->()) -> Future<[RedisData]> {
        // Fill the pipeline with commnads
        let pipeline = RedisPipeline()
        closure(pipeline)
        
        // Returns a empty fulfilled future if the transaction was empty
        if pipeline.commands.count == 0 {
            return eventLoop.newSucceededFuture(result: [RedisData]())
        }
        
        // Create the multi-exec list of commands
        let multiExec = [RedisData.array([.bulkString("MULTI")])] +
            pipeline.commands +
            [RedisData.array([.bulkString("EXEC")])]
        
        // Send the commands as a pipeline
        return send(pipeline: multiExec).map { data in
            guard let value = data.last?.array else {
                throw RedisError(identifier: "multi", reason: "Failed to convert resp to array.")
            }
            return value
        }
    }
}
