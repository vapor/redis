//
//  main.swift
//  Redbird
//
//  Created by Honza Dvorsky on 2/10/16.
//  Copyright © 2016 Honza Dvorsky. All rights reserved.
//

print("Redbird starting")

do {
    let client = try Redbird(port: 6380)
    let response = try client.command("BLAH")
    print(response)
} catch {
    assertionFailure("\(error)")
}

print("Redbird ending")
