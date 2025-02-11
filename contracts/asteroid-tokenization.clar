;; Asteroid Tokenization Contract

;; Define the fungible token
(define-fungible-token asteroid-token)

;; Define data structures
(define-map asteroids
  { asteroid-id: uint }
  { name: (string-utf8 64), size: uint, composition: (string-utf8 256), owner: principal }
)

(define-data-var last-asteroid-id uint u0)

;; Error codes
(define-constant err-unauthorized (err u100))
(define-constant err-invalid-asteroid (err u101))
(define-constant err-insufficient-tokens (err u102))

;; Define the contract owner
(define-data-var contract-owner principal tx-sender)

;; Mint new asteroid tokens
(define-public (mint-tokens (amount uint) (recipient principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) err-unauthorized)
    (ft-mint? asteroid-token amount recipient)
  )
)

;; Register a new asteroid
(define-public (register-asteroid (name (string-utf8 64)) (size uint) (composition (string-utf8 256)))
  (let
    ((new-asteroid-id (+ (var-get last-asteroid-id) u1)))
    (map-set asteroids
      { asteroid-id: new-asteroid-id }
      { name: name, size: size, composition: composition, owner: tx-sender }
    )
    (var-set last-asteroid-id new-asteroid-id)
    (ok new-asteroid-id)
  )
)

;; Transfer asteroid ownership
(define-public (transfer-asteroid (asteroid-id uint) (new-owner principal))
  (let
    ((asteroid (unwrap! (map-get? asteroids { asteroid-id: asteroid-id }) err-invalid-asteroid)))
    (asserts! (is-eq tx-sender (get owner asteroid)) err-unauthorized)
    (ok (map-set asteroids
      { asteroid-id: asteroid-id }
      (merge asteroid { owner: new-owner })))
  )
)

;; Get asteroid details
(define-read-only (get-asteroid (asteroid-id uint))
  (map-get? asteroids { asteroid-id: asteroid-id })
)

;; Get token balance
(define-read-only (get-balance (account principal))
  (ft-get-balance asteroid-token account)
)

;; Change contract owner
(define-public (set-contract-owner (new-owner principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) err-unauthorized)
    (ok (var-set contract-owner new-owner))
  )
)

