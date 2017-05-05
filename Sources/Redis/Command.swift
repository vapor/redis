/// Redis commands
public enum Command {
    case get
    case set
    case hget
    case hset
    case hdel
    case hkeys
    case keys
    case authorize
    case delete
    case client
    case ping
    case configure
    case flushall
    case publish
    case subscribe
    case custom(Bytes)

    public init(_ custom: BytesRepresentable) throws {
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
        case .hget:
            return [.H, .G, .E, .T]
        case .hset:
            return [.H, .S, .E, .T]
        case .hkeys:
            return [.H, .K, .E, .Y, .S]
        case .hdel:
            return [.H, .D, .E, .L]
        case .keys:
            return [.K, .E, .Y, .S]
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
        case .publish:
            return [.P, .U, .B, .L, .I, .S, .H]
        case .subscribe:
            return [.S, .U, .B, .S, .C, .R, .I, .B, .E]
        case .custom(let bytes):
            return bytes
        }
    }
}
