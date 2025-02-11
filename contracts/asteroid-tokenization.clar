;; Mining Rights Contract

;; Define data structures
(define-map mining-claims
  { asteroid-id: uint, claim-id: uint }
  { owner: principal, start-time: uint, end-time: uint, status: (string-utf8 20) }
)

(define-map asteroid-claim-count
  { asteroid-id: uint }
  { count: uint }
)

;; Error codes
(define-constant err-unauthorized (err u100))
(define-constant err-invalid-claim (err u101))
(define-constant err-claim-exists (err u102))

;; Define the contract owner
(define-data-var contract-owner principal tx-sender)

;; Stake tokens to create a mining claim
(define-public (create-claim (asteroid-id uint) (duration uint))
  (let
    ((claim-count (default-to { count: u0 } (map-get? asteroid-claim-count { asteroid-id: asteroid-id })))
     (new-claim-id (+ (get count claim-count) u1))
     (start-time block-height)
     (end-time (+ block-height duration)))
    (asserts! (is-none (map-get? mining-claims { asteroid-id: asteroid-id, claim-id: new-claim-id })) err-claim-exists)
    (try! (contract-call? .asteroid-tokenization transfer-asteroid asteroid-id (as-contract tx-sender)))
    (map-set mining-claims
      { asteroid-id: asteroid-id, claim-id: new-claim-id }
      { owner: tx-sender, start-time: start-time, end-time: end-time, status: "active" }
    )
    (map-set asteroid-claim-count
      { asteroid-id: asteroid-id }
      { count: new-claim-id }
    )
    (ok new-claim-id)
  )
)

;; Transfer a mining claim
(define-public (transfer-claim (asteroid-id uint) (claim-id uint) (new-owner principal))
  (let
    ((claim (unwrap! (map-get? mining-claims { asteroid-id: asteroid-id, claim-id: claim-id }) err-invalid-claim)))
    (asserts! (is-eq tx-sender (get owner claim)) err-unauthorized)
    (ok (map-set mining-claims
      { asteroid-id: asteroid-id, claim-id: claim-id }
      (merge claim { owner: new-owner })))
  )
)

;; End a mining claim
(define-public (end-claim (asteroid-id uint) (claim-id uint))
  (let
    ((claim (unwrap! (map-get? mining-claims { asteroid-id: asteroid-id, claim-id: claim-id }) err-invalid-claim)))
    (asserts! (or (is-eq tx-sender (get owner claim)) (is-eq tx-sender (var-get contract-owner))) err-unauthorized)
    (try! (as-contract (contract-call? .asteroid-tokenization transfer-asteroid asteroid-id (get owner claim))))
    (ok (map-set mining-claims
      { asteroid-id: asteroid-id, claim-id: claim-id }
      (merge claim { status: "ended" })))
  )
)

;; Get claim details
(define-read-only (get-claim (asteroid-id uint) (claim-id uint))
  (map-get? mining-claims { asteroid-id: asteroid-id, claim-id: claim-id })
)

;; Change contract owner
(define-public (set-contract-owner (new-owner principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) err-unauthorized)
    (ok (var-set contract-owner new-owner))
  )
)

