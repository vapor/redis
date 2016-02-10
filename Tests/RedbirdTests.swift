//
//  RedbirdTests.swift
//  RedbirdTests
//
//  Created by Honza Dvorsky on 2/10/16.
//  Copyright © 2016 Honza Dvorsky. All rights reserved.
//

import XCTest

class RedbirdTests: XCTestCase {
    
    func testConnectedPing() {
        do {
            let client = try Redbird(port: 6380)
            let response = try client.command("PING")
            print(response)
        } catch {
            assertionFailure("\(error)")
        }
    }
        
}
