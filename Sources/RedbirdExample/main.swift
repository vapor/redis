//
//  main.swift
//  Redbird
//
//  Created by Honza Dvorsky on 2/10/16.
//  Copyright © 2016 Honza Dvorsky. All rights reserved.
//

import Redbird

print("Redbird starting")

do {
    let client = try Redbird(port: 6380)
    print("Sending PING to Redis server at \(client.address):\(client.port)")
    let response = try client.command("PING", params: [])
    print("Response: \(response)")
} catch {
    assertionFailure("\(error)")
}

print("Redbird ending")
