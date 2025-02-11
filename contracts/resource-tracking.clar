;; Resource Tracking Contract

;; Define data structures
(define-map resource-extractions
  { extraction-id: uint }
  { asteroid-id: uint, claim-id: uint, resource-type: (string-utf8 64), amount: uint, timestamp: uint }
)

(define-map resource-transports
  { transport-id: uint }
  { extraction-id: uint, destination: (string-utf8 64), amount: uint, timestamp: uint }
)

(define-data-var last-extraction-id uint u0)
(define-data-var last-transport-id uint u0)

;; Error codes
(define-constant err-unauthorized (err u100))
(define-constant err-invalid-extraction (err u101))
(define-constant err-invalid-transport (err u102))

;; Define the contract owner
(define-data-var contract-owner principal tx-sender)

;; Record a resource extraction
(define-public (record-extraction (asteroid-id uint) (claim-id uint) (resource-type (string-utf8 64)) (amount uint))
  (let
    ((new-extraction-id (+ (var-get last-extraction-id) u1)))
    (map-set resource-extractions
      { extraction-id: new-extraction-id }
      { asteroid-id: asteroid-id, claim-id: claim-id, resource-type: resource-type, amount: amount, timestamp: block-height }
    )
    (var-set last-extraction-id new-extraction-id)
    (ok new-extraction-id)
  )
)

;; Record a resource transport
(define-public (record-transport (extraction-id uint) (destination (string-utf8 64)) (amount uint))
  (let
    ((new-transport-id (+ (var-get last-transport-id) u1))
     (extraction (unwrap! (map-get? resource-extractions { extraction-id: extraction-id }) err-invalid-extraction)))
    (map-set resource-transports
      { transport-id: new-transport-id }
      { extraction-id: extraction-id, destination: destination, amount: amount, timestamp: block-height }
    )
    (var-set last-transport-id new-transport-id)
    (ok new-transport-id)
  )
)

;; Get extraction details
(define-read-only (get-extraction (extraction-id uint))
  (map-get? resource-extractions { extraction-id: extraction-id })
)

;; Get transport details
(define-read-only (get-transport (transport-id uint))
  (map-get? resource-transports { transport-id: transport-id })
)

;; Change contract owner
(define-public (set-contract-owner (new-owner principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) err-unauthorized)
    (ok (var-set contract-owner new-owner))
  )
)

