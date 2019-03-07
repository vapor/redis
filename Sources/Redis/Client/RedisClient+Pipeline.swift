import Foundation

public final class RedisPipeline {
    /// The commands in this pipeline
    var commands = [RedisData]()
    
    /// Adds a command to the pipeline
    public func command(_ command: String, _ arguments: [RedisData] = []) {
        let command = RedisData.array([RedisData(bulk: command)] + arguments)
        self.commands.append(command)
    }
}

extension RedisClient {
    /// Executes a pipelined transaction
    public func pipeline(closure: (RedisPipeline)->()) -> Future<[RedisData]> {
        // Fill the pipeline with commnads
        let pipeline = RedisPipeline()
        closure(pipeline)
        
        // Send the commands as a pipeline
        return send(pipeline: pipeline.commands)
    }
    
    /// Executes a multi/exec transaction
    public func multi(closure: (RedisPipeline)->()) -> Future<[RedisData]> {
        // Fill the pipeline with commnads
        let pipeline = RedisPipeline()
        closure(pipeline)
        
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
