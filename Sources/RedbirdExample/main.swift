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
    let client = try Redbird()
    let client_ip = try Redbird(config: RedbirdConfig(address: "localhost"))

    print("Sending 'PING' to Redis server at \(client.address):\(client.port)")
    let response1 = try client.command("PING", params: []).toString()
    print("Response: \(response1)")
    
    print("Sending 'SET mykey hello_redis' to Redis server at \(client.address):\(client.port)")
    let response2 = try client.command("SET", params: ["mykey", "hello_redis"]).toString()
    print("Response: \(response2)")
    
    print("Sending 'GET mykey' to Redis server at \(client.address):\(client.port)")
    let response3 = try client.command("GET", params: ["mykey"]).toString()
    print("Response: \(response3)")
    
    print("Sending 'GET nokey' to Redis server at \(client.address):\(client.port)")
    let response4 = try client.command("GET", params: ["nokey"]).toMaybeString()
    print("Response: \(response4)")
    
} catch {
    print("Encountered error \(error)")
    fatalError("\(error)")
}

print("Redbird ending")
