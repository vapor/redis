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

    print("Sending 'PING' to Redis server at \(client.address):\(client.port)")
    let response1 = try client.command("PING", params: [])
    print("Response: \(response1)")
    
    print("Sending 'SET mykey hello_redis' to Redis server at \(client.address):\(client.port)")
    let response2 = try client.command("SET", params: ["mykey", "hello_redis"])
    print("Response: \(response2)")
    
    print("Sending 'GET mykey' to Redis server at \(client.address):\(client.port)")
    let response3 = try client.command("GET", params: ["mykey"])
    print("Response: \(response3)")
    
} catch {
    assertionFailure("\(error)")
}

print("Redbird ending")
