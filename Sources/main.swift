
print("Redbird starting")

do {
    let client = try Redbird(port: 6380)
    let response = try client.command("PING")
    print(response)
} catch {
    assertionFailure("\(error)")
}

print("Redbird ending")
