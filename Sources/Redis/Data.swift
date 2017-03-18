/// RESP data format
public enum Data {
    case string(String)
    case error(Error)
    case integer(Int)
    case bulk(Bytes)
    case array([Data?])
}

// MARK: Convenience

extension Data {
    public var bool: Bool? {
        switch self {
        case .integer(let i):
            return i == 1
        case .string(let s):
            return s.bool
        case .bulk(let b):
            return b.makeString().bool
        default:
            return nil
        }
    }

    public var double: Double? {
        if let i = int {
            return Double(i)
        } else {
            return nil
        }
    }

    public var int: Int? {
        switch self {
        case .integer(let int):
            return int
        case .string(let s):
            return s.int
        case .bulk(let b):
            return b.makeString().int
        default:
            return nil
        }
    }

    public var string: String? {
        switch self {
        case .integer(let i):
            return i.description
        case .string(let s):
            return s
        case .bulk(let b):
            return b.makeString()
        default:
            return nil
        }
    }

    public var array: [Data?]? {
        switch self {
        case .array(let a):
            return a
        default:
            return nil
        }
    }

   public var bytes: Bytes? {
        switch self {
        case .string(let s):
            return s.makeBytes()
        case .bulk(let b):
            return b
        default:
            return nil
        }
    }
}

