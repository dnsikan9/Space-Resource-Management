import { describe, it, expect, beforeEach } from "vitest"

// Mock storage for asteroids and token balances
const asteroids = new Map<number, { name: string; size: number; composition: string; owner: string }>()
const tokenBalances = new Map<string, number>()
let lastAsteroidId = 0
let contractOwner = "owner"

// Mock functions to simulate contract behavior
function mintTokens(amount: number, recipient: string, caller: string) {
  if (caller !== contractOwner) throw new Error("Unauthorized")
  const currentBalance = tokenBalances.get(recipient) || 0
  tokenBalances.set(recipient, currentBalance + amount)
  return true
}

function registerAsteroid(name: string, size: number, composition: string, owner: string) {
  const newAsteroidId = ++lastAsteroidId
  asteroids.set(newAsteroidId, { name, size, composition, owner })
  return newAsteroidId
}

function transferAsteroid(asteroidId: number, newOwner: string, caller: string) {
  const asteroid = asteroids.get(asteroidId)
  if (!asteroid) throw new Error("Invalid asteroid")
  if (asteroid.owner !== caller) throw new Error("Unauthorized")
  asteroid.owner = newOwner
  asteroids.set(asteroidId, asteroid)
  return true
}

function getAsteroid(asteroidId: number) {
  return asteroids.get(asteroidId)
}

function getBalance(account: string) {
  return tokenBalances.get(account) || 0
}

function setContractOwner(newOwner: string, caller: string) {
  if (caller !== contractOwner) throw new Error("Unauthorized")
  contractOwner = newOwner
  return true
}

describe("Asteroid Tokenization Contract", () => {
  beforeEach(() => {
    asteroids.clear()
    tokenBalances.clear()
    lastAsteroidId = 0
    contractOwner = "owner"
  })
  
  it("should mint tokens", () => {
    expect(mintTokens(1000, "user1", "owner")).toBe(true)
    expect(getBalance("user1")).toBe(1000)
  })
  
  it("should not allow unauthorized minting", () => {
    expect(() => mintTokens(1000, "user1", "user2")).toThrow("Unauthorized")
  })
  
  it("should register a new asteroid", () => {
    const asteroidId = registerAsteroid("Ceres", 939, "rocky", "user1")
    expect(asteroidId).toBe(1)
    expect(getAsteroid(asteroidId)).toEqual({
      name: "Ceres",
      size: 939,
      composition: "rocky",
      owner: "user1",
    })
  })
  
  it("should transfer asteroid ownership", () => {
    const asteroidId = registerAsteroid("Vesta", 525, "rocky", "user1")
    expect(transferAsteroid(asteroidId, "user2", "user1")).toBe(true)
    expect(getAsteroid(asteroidId)?.owner).toBe("user2")
  })
  
  it("should not allow unauthorized asteroid transfer", () => {
    const asteroidId = registerAsteroid("Pallas", 512, "rocky", "user1")
    expect(() => transferAsteroid(asteroidId, "user3", "user2")).toThrow("Unauthorized")
  })
  
  it("should get asteroid details", () => {
    const asteroidId = registerAsteroid("Hygiea", 431, "carbonaceous", "user1")
    expect(getAsteroid(asteroidId)).toEqual({
      name: "Hygiea",
      size: 431,
      composition: "carbonaceous",
      owner: "user1",
    })
  })
  
  it("should get token balance", () => {
    mintTokens(500, "user1", "owner")
    mintTokens(300, "user2", "owner")
    expect(getBalance("user1")).toBe(500)
    expect(getBalance("user2")).toBe(300)
  })
  
  it("should allow changing contract owner by current owner", () => {
    expect(setContractOwner("newOwner", "owner")).toBe(true)
    expect(contractOwner).toBe("newOwner")
  })
  
  it("should not allow changing contract owner by non-owner", () => {
    expect(() => setContractOwner("newOwner", "user1")).toThrow("Unauthorized")
  })
})

