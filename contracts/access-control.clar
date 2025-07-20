;; Access Control Contract
;; Manages keycard entry to fenced dog areas

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u200))
(define-constant ERR-ACCESS-DENIED (err u201))
(define-constant ERR-INVALID-AREA (err u202))
(define-constant ERR-INVALID-INPUT (err u203))
(define-constant ERR-ALREADY-INSIDE (err u204))
(define-constant ERR-NOT-INSIDE (err u205))

;; Data Variables
(define-data-var park-open bool true)
(define-data-var opening-hour uint u6)
(define-data-var closing-hour uint u22)

;; Data Maps
(define-map access-cards
  { card-id: uint }
  {
    owner: principal,
    is-active: bool,
    access-level: uint,
    issued-date: uint
  }
)

(define-map area-access
  { area-id: uint }
  {
    name: (string-ascii 50),
    required-level: uint,
    capacity: uint,
    current-occupancy: uint,
    is-open: bool
  }
)

(define-map current-visitors
  { visitor: principal }
  {
    area-id: uint,
    entry-time: uint,
    card-id: uint
  }
)

(define-map access-logs
  { log-id: uint }
  {
    visitor: principal,
    area-id: uint,
    entry-time: uint,
    exit-time: (optional uint),
    card-id: uint
  }
)

(define-map admins
  { admin: principal }
  { is-admin: bool }
)

(define-data-var next-card-id uint u1)
(define-data-var next-log-id uint u1)

;; Initialize contract owner as admin and setup default areas
(map-set admins { admin: CONTRACT-OWNER } { is-admin: true })

;; Initialize default areas
(map-set area-access { area-id: u1 } { name: "Small Dog Area", required-level: u1, capacity: u20, current-occupancy: u0, is-open: true })
(map-set area-access { area-id: u2 } { name: "Large Dog Area", required-level: u1, capacity: u30, current-occupancy: u0, is-open: true })
(map-set area-access { area-id: u3 } { name: "Training Area", required-level: u2, capacity: u15, current-occupancy: u0, is-open: true })

;; Private Functions
(define-private (is-admin (user principal))
  (default-to false (get is-admin (map-get? admins { admin: user })))
)

(define-private (is-park-hours)
  (let
    (
      (current-hour (mod (/ block-height u144) u24))
    )
    (and
      (>= current-hour (var-get opening-hour))
      (< current-hour (var-get closing-hour))
    )
  )
)

(define-private (has-area-capacity (area-id uint))
  (match (map-get? area-access { area-id: area-id })
    area-data
    (< (get current-occupancy area-data) (get capacity area-data))
    false
  )
)

;; Public Functions

;; Add admin (only contract owner)
(define-public (add-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (ok (map-set admins { admin: new-admin } { is-admin: true }))
  )
)

;; Issue access card (admin only)
(define-public (issue-card (owner principal) (access-level uint))
  (let
    (
      (card-id (var-get next-card-id))
    )
    (asserts! (is-admin tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (and (>= access-level u1) (<= access-level u3)) ERR-INVALID-INPUT)

    (map-set access-cards
      { card-id: card-id }
      {
        owner: owner,
        is-active: true,
        access-level: access-level,
        issued-date: block-height
      }
    )

    (var-set next-card-id (+ card-id u1))
    (ok card-id)
  )
)

;; Deactivate access card (admin only)
(define-public (deactivate-card (card-id uint))
  (let
    (
      (card-data (unwrap! (map-get? access-cards { card-id: card-id }) ERR-INVALID-INPUT))
    )
    (asserts! (is-admin tx-sender) ERR-NOT-AUTHORIZED)

    (ok (map-set access-cards
      { card-id: card-id }
      (merge card-data { is-active: false })
    ))
  )
)

;; Enter area
(define-public (enter-area (card-id uint) (area-id uint))
  (let
    (
      (card-data (unwrap! (map-get? access-cards { card-id: card-id }) ERR-ACCESS-DENIED))
      (area-data (unwrap! (map-get? area-access { area-id: area-id }) ERR-INVALID-AREA))
      (log-id (var-get next-log-id))
    )
    (asserts! (is-eq tx-sender (get owner card-data)) ERR-NOT-AUTHORIZED)
    (asserts! (get is-active card-data) ERR-ACCESS-DENIED)
    (asserts! (get is-open area-data) ERR-ACCESS-DENIED)
    (asserts! (>= (get access-level card-data) (get required-level area-data)) ERR-ACCESS-DENIED)
    (asserts! (var-get park-open) ERR-ACCESS-DENIED)
    (asserts! (is-park-hours) ERR-ACCESS-DENIED)
    (asserts! (has-area-capacity area-id) ERR-ACCESS-DENIED)
    (asserts! (is-none (map-get? current-visitors { visitor: tx-sender })) ERR-ALREADY-INSIDE)

    ;; Record entry
    (map-set current-visitors
      { visitor: tx-sender }
      {
        area-id: area-id,
        entry-time: block-height,
        card-id: card-id
      }
    )

    ;; Update area occupancy
    (map-set area-access
      { area-id: area-id }
      (merge area-data { current-occupancy: (+ (get current-occupancy area-data) u1) })
    )

    ;; Log entry
    (map-set access-logs
      { log-id: log-id }
      {
        visitor: tx-sender,
        area-id: area-id,
        entry-time: block-height,
        exit-time: none,
        card-id: card-id
      }
    )

    (var-set next-log-id (+ log-id u1))
    (ok true)
  )
)

;; Exit area
(define-public (exit-area)
  (let
    (
      (visitor-data (unwrap! (map-get? current-visitors { visitor: tx-sender }) ERR-NOT-INSIDE))
      (area-id (get area-id visitor-data))
      (area-data (unwrap! (map-get? area-access { area-id: area-id }) ERR-INVALID-AREA))
    )
    ;; Remove from current visitors
    (map-delete current-visitors { visitor: tx-sender })

    ;; Update area occupancy
    (map-set area-access
      { area-id: area-id }
      (merge area-data { current-occupancy: (- (get current-occupancy area-data) u1) })
    )

    (ok true)
  )
)

;; Emergency exit all (admin only)
(define-public (emergency-exit-all (area-id uint))
  (let
    (
      (area-data (unwrap! (map-get? area-access { area-id: area-id }) ERR-INVALID-AREA))
    )
    (asserts! (is-admin tx-sender) ERR-NOT-AUTHORIZED)

    (ok (map-set area-access
      { area-id: area-id }
      (merge area-data { current-occupancy: u0, is-open: false })
    ))
  )
)

;; Set park hours (admin only)
(define-public (set-park-hours (opening uint) (closing uint))
  (begin
    (asserts! (is-admin tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (and (< opening u24) (< closing u24) (< opening closing)) ERR-INVALID-INPUT)

    (var-set opening-hour opening)
    (var-set closing-hour closing)
    (ok true)
  )
)

;; Read-only Functions

;; Get card information
(define-read-only (get-card-info (card-id uint))
  (map-get? access-cards { card-id: card-id })
)

;; Get area information
(define-read-only (get-area-info (area-id uint))
  (map-get? area-access { area-id: area-id })
)

;; Check if visitor is currently inside
(define-read-only (get-visitor-status (visitor principal))
  (map-get? current-visitors { visitor: visitor })
)

;; Get access log
(define-read-only (get-access-log (log-id uint))
  (map-get? access-logs { log-id: log-id })
)

;; Check if park is open
(define-read-only (is-park-currently-open)
  (and (var-get park-open) (is-park-hours))
)
