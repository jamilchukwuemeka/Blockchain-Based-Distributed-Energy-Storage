;; Capacity Aggregation Contract
;; Combines distributed storage capacity into virtual power plants

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u200))
(define-constant ERR_POOL_NOT_FOUND (err u201))
(define-constant ERR_FACILITY_NOT_VERIFIED (err u202))
(define-constant ERR_INSUFFICIENT_CAPACITY (err u203))

;; Storage pools for aggregated capacity
(define-map capacity-pools
  { pool-id: uint }
  {
    name: (string-ascii 50),
    total-capacity: uint,
    available-capacity: uint,
    participant-count: uint,
    created-at: uint,
    active: bool
  }
)

;; Pool participation tracking
(define-map pool-participants
  { pool-id: uint, facility-id: uint }
  {
    capacity-contributed: uint,
    join-date: uint,
    active: bool
  }
)

(define-data-var pool-counter uint u0)

;; Create a new capacity pool
(define-public (create-pool (name (string-ascii 50)))
  (let ((pool-id (+ (var-get pool-counter) u1)))
    (map-set capacity-pools
      { pool-id: pool-id }
      {
        name: name,
        total-capacity: u0,
        available-capacity: u0,
        participant-count: u0,
        created-at: block-height,
        active: true
      }
    )
    (var-set pool-counter pool-id)
    (ok pool-id)
  )
)

;; Join a capacity pool
(define-public (join-pool (pool-id uint) (facility-id uint) (capacity-kwh uint))
  (match (map-get? capacity-pools { pool-id: pool-id })
    pool-data
    (begin
      (asserts! (get active pool-data) ERR_POOL_NOT_FOUND)
      (asserts! (> capacity-kwh u0) ERR_INSUFFICIENT_CAPACITY)

      ;; Add participant to pool
      (map-set pool-participants
        { pool-id: pool-id, facility-id: facility-id }
        {
          capacity-contributed: capacity-kwh,
          join-date: block-height,
          active: true
        }
      )

      ;; Update pool totals
      (map-set capacity-pools
        { pool-id: pool-id }
        (merge pool-data {
          total-capacity: (+ (get total-capacity pool-data) capacity-kwh),
          available-capacity: (+ (get available-capacity pool-data) capacity-kwh),
          participant-count: (+ (get participant-count pool-data) u1)
        })
      )
      (ok true)
    )
    ERR_POOL_NOT_FOUND
  )
)

;; Get pool information
(define-read-only (get-pool (pool-id uint))
  (map-get? capacity-pools { pool-id: pool-id })
)

;; Get participant information
(define-read-only (get-participant (pool-id uint) (facility-id uint))
  (map-get? pool-participants { pool-id: pool-id, facility-id: facility-id })
)
