FROM vapor/swift

ADD Package.swift Package.swift
ADD Sources Sources
ADD Tests Tests

CMD swift test --enable-test-discovery
