import Debugging
import COperatingSystem

/// Errors that can be thrown while working with Redis.
public struct RedisError: Traceable, Debuggable, Helpable, Swift.Error, Encodable {
    public static let readableName = "Redis Error"
    public let identifier: String
    public var reason: String
    public var file: String
    public var function: String
    public var line: UInt
    public var column: UInt
    public var stackTrace: [String]
    public var possibleCauses: [String]
    public var suggestedFixes: [String]

    /// Create a new TCP error.
    public init(
        identifier: String,
        reason: String,
        possibleCauses: [String] = [],
        suggestedFixes: [String] = [],
        file: String = #file,
        function: String = #function,
        line: UInt = #line,
        column: UInt = #column
    ) {
        self.identifier = identifier
        self.reason = reason
        self.file = file
        self.function = function
        self.line = line
        self.column = column
        self.stackTrace = RedisError.makeStackTrace()
        self.possibleCauses = possibleCauses
        self.suggestedFixes = suggestedFixes
    }
}

