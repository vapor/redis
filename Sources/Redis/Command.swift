/// Redis commands
public enum Command {
    case get
    case set
    case authorize
    case delete
    case client
    case ping
    case configure
    case flushall
    case custom(Bytes)

    public init(custom: BytesRepresentable) throws {
        self = .custom(try custom.makeBytes())
    }
}

extension Command {
    var raw: Bytes {
        switch self {
        case .get:
            return [.G, .E, .T]
        case .set:
            return [.S, .E, .T]
        case .authorize:
            return [.A, .U, .T, .H]
        case .delete:
            return [.D, .E, .L]
        case .client:
            return [.C, .L, .I, .E, .N, .T]
        case .ping:
            return [.P, .I, .N, .G]
        case .configure:
            return [.C, .O, .N, .F, .I, .G]
        case .flushall:
            return [.F, .L, .U, .S, .H, .A, .L, .L]
        case .custom(let bytes):
            return bytes
        }
    }
}
