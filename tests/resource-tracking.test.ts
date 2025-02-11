import { describe, it, expect, beforeEach } from "vitest"

// Mock storage for resource extractions and transports
const resourceExtractions = new Map<
    number,
    { asteroidId: number; claimId: number; resourceType: string; amount: number; timestamp: number }
>()
const resourceTransports = new Map<
    number,
    { extractionId: number; destination: string; amount: number; timestamp: number }
>()
let lastExtractionId = 0
let lastTransportId = 0
let contractOwner = "owner"
let blockHeight = 0

// Mock functions to simulate contract behavior
function recordExtraction(asteroidId: number, claimId: number, resourceType: string, amount: number) {
  const newExtractionId = ++lastExtractionId
  resourceExtractions.set(newExtractionId, {
    asteroidId,
    claimId,
    resourceType,
    amount,
    timestamp: blockHeight,
  })
  return newExtractionId
}

function recordTransport(extractionId: number, destination: string, amount: number) {
  const extraction = resourceExtractions.get(extractionId)
  if (!extraction) throw new Error("Invalid extraction")
  
  const newTransportId = ++lastTransportId
  resourceTransports.set(newTransportId, {
    extractionId,
    destination,
    amount,
    timestamp: blockHeight,
  })
  return newTransportId
}

function getExtraction(extractionId: number) {
  return resourceExtractions.get(extractionId)
}

function getTransport(transportId: number) {
  return resourceTransports.get(transportId)
}

function setContractOwner(newOwner: string, caller: string) {
  if (caller !== contractOwner) throw new Error("Unauthorized")
  contractOwner = newOwner
  return true
}

describe("Resource Tracking Contract", () => {
  beforeEach(() => {
    resourceExtractions.clear()
    resourceTransports.clear()
    lastExtractionId = 0
    lastTransportId = 0
    contractOwner = "owner"
    blockHeight = 0
  })
  
  it("should record a resource extraction", () => {
    const extractionId = recordExtraction(1, 1, "iron", 1000)
    expect(extractionId).toBe(1)
    expect(getExtraction(extractionId)).toEqual({
      asteroidId: 1,
      claimId: 1,
      resourceType: "iron",
      amount: 1000,
      timestamp: 0,
    })
  })
  
  it("should record a resource transport", () => {
    const extractionId = recordExtraction(1, 1, "iron", 1000)
    const transportId = recordTransport(extractionId, "Earth", 500)
    expect(transportId).toBe(1)
    expect(getTransport(transportId)).toEqual({
      extractionId: extractionId,
      destination: "Earth",
      amount: 500,
      timestamp: 0,
    })
  })
  
  it("should not allow recording transport for invalid extraction", () => {
    expect(() => recordTransport(999, "Earth", 500)).toThrow("Invalid extraction")
  })
  
  it("should get extraction details", () => {
    const extractionId = recordExtraction(1, 1, "gold", 500)
    expect(getExtraction(extractionId)).toEqual({
      asteroidId: 1,
      claimId: 1,
      resourceType: "gold",
      amount: 500,
      timestamp: 0,
    })
  })
  
  it("should get transport details", () => {
    const extractionId = recordExtraction(1, 1, "platinum", 2000)
    const transportId = recordTransport(extractionId, "Mars", 1000)
    expect(getTransport(transportId)).toEqual({
      extractionId: extractionId,
      destination: "Mars",
      amount: 1000,
      timestamp: 0,
    })
  })
  
  it("should allow changing contract owner by current owner", () => {
    expect(setContractOwner("newOwner", "owner")).toBe(true)
    expect(contractOwner).toBe("newOwner")
  })
  
  it("should not allow changing contract owner by non-owner", () => {
    expect(() => setContractOwner("newOwner", "user1")).toThrow("Unauthorized")
  })
})

