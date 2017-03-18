public enum RedisError: Error {
    case pipelineCommandsRequired
    case general(String)
    case invalidInteger
    case unknownResponseType
}

import Debugging

extension RedisError: Debuggable {
    public var reason: String {
        switch self {
        case .general(let string):
            return string
        case .invalidInteger:
            return "A value in the response was unable to be parsed into an integer"
        case .pipelineCommandsRequired:
            return "Pipeline cannot be executed until commands are enqueued"
        case .unknownResponseType:
            return "Unknown response type encounrted"
        }
    }

    public var identifier: String {
        switch self {
        case .general(let s):
            return "general (\(s))"
        case .invalidInteger:
            return "invalidInteger"
        case .pipelineCommandsRequired:
            return "pipelineCommandsRequired"
        case .unknownResponseType:
            return "unknownResponseType"
        }
    }

    public var possibleCauses: [String] {
        return []
    }

    public var suggestedFixes: [String] {
        return []
    }
}
