import Debugging
import COperatingSystem

/// Errors that can be thrown while working with Redis.
public struct RedisError: Debuggable {
    /// See `Debuggable`.
    public static let readableName = "Redis Error"
    
    /// See `Debuggable`.
    public let identifier: String
    
    /// See `Debuggable`.
    public var reason: String
    
    /// See `Debuggable`.
    public var sourceLocation: SourceLocation?
    
    /// See `Debuggable`.
    public var stackTrace: [String]
    
    /// See `Debuggable`.
    public var possibleCauses: [String]
    
    /// See `Debuggable`.
    public var suggestedFixes: [String]

    /// Create a new `RedisError`.
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
        self.sourceLocation = SourceLocation.init(file: file, function: function, line: line, column: column, range: nil)
        self.stackTrace = RedisError.makeStackTrace()
        self.possibleCauses = possibleCauses
        self.suggestedFixes = suggestedFixes
    }
}

func VERBOSE(_ string: @autoclosure () -> (String)) {
    #if VERBOSE
    print("[VERBOSE] [Redis] \(string())")
    #endif
}
