#if swift(>=5.8)

@_documentation(visibility: internal) @_exported import RediStack
@_documentation(visibility: internal) @_exported import struct Foundation.URL
@_documentation(visibility: internal) @_exported import struct Logging.Logger
@_documentation(visibility: internal) @_exported import struct NIO.TimeAmount

#else

@_exported import RediStack
@_exported import struct Foundation.URL
@_exported import struct Logging.Logger
@_exported import struct NIO.TimeAmount

#endif
