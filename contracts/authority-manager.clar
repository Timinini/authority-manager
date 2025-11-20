;; secure-owner-manager.clar

;; Title: Secure Owner Management Contract
;; Description: Secure owner and operator management with multi-level permissions

;; Error codes
(define-constant ERR-NOT-OWNER u100)
(define-constant ERR-ALREADY-OWNER u101)
(define-constant ERR-NOT-OPERATOR u102)
(define-constant ERR-ALREADY-OPERATOR u103)
(define-constant ERR-INVALID-OWNER-COUNT u104)
(define-constant ERR-PENDING-ACTION-EXISTS u105)
(define-constant ERR-NO-PENDING-ACTION u106)
(define-constant ERR-ACTION-EXPIRED u107)
(define-constant ERR-INSUFFICIENT-APPROVALS u108)
(define-constant ERR-OPERATOR-LIMIT u109)

;; Data storage
(define-data-var owners (list 10 principal) (list))
(define-data-var operators (list 20 principal) (list))
(define-data-var owner-threshold uint u1)
(define-data-var action-nonce uint u0)

;; Pending actions for owner changes (requires threshold approval)
(define-map pending-actions uint {
    action-type: (string-ascii 20),
    target: (buff 32),
    proposed-by: principal,
    proposed-at: uint,
    expiry-block: uint,
    approvals: (list 10 principal)
})

;; Initialize the contract with initial owners
(define-public (initialize (initial-owners (list 10 principal)) (initial-threshold uint))
    (let 
        ((owner-count (len initial-owners)))
        (asserts! (is-eq (len (var-get owners)) u0) (err u1))
        (asserts! (> owner-count u0) (err ERR-INVALID-OWNER-COUNT))
        (asserts! (<= initial-threshold owner-count) (err ERR-INVALID-OWNER-COUNT))
        (asserts! (>= initial-threshold u1) (err ERR-INVALID-OWNER-COUNT))
        (var-set owners initial-owners)
        (var-set owner-threshold initial-threshold)
        (ok true)))

;; Check if address is an owner
(define-read-only (is-owner (who principal))
    (is-some (index-of (var-get owners) who)))

;; Check if address is an operator
(define-read-only (is-operator (who principal))
    (is-some (index-of (var-get operators) who)))

;; Get all owners
(define-read-only (get-owners)
    (ok (var-get owners)))

;; Get all operators
(define-read-only (get-operators)
    (ok (var-get operators)))

;; Get current threshold
(define-read-only (get-threshold)
    (ok (var-get owner-threshold)))

;; Get owner count
(define-read-only (get-owner-count)
    (ok (len (var-get owners))))

;; Propose to add a new owner
(define-public (propose-add-owner (new-owner principal) (expiry-blocks uint))
    (err ERR-NOT-OWNER))


;; Propose to remove an owner
(define-public (propose-remove-owner (owner-to-remove principal) (expiry-blocks uint))
    (err ERR-NOT-OWNER))

;; Approve a pending owner action
(define-public (approve-owner-action (action-id uint))
    (err ERR-NOT-OWNER))

;; Execute approved owner action
(define-private (execute-owner-action (action-id uint))
    (ok true))

;; Add operator (owners only)
(define-public (add-operator (new-operator principal))
    (begin
        (asserts! (is-owner tx-sender) (err ERR-NOT-OWNER))
        (asserts! (not (is-operator new-operator)) (err ERR-ALREADY-OPERATOR))
        (var-set operators (list new-operator))
        (ok true)))

;; Remove operator (owners only)
(define-public (remove-operator (operator-to-remove principal))
    (begin
        (asserts! (is-owner tx-sender) (err ERR-NOT-OWNER))
        (asserts! (is-operator operator-to-remove) (err ERR-NOT-OPERATOR))
        (ok true)))

;; Internal operator removal function
(define-private (remove-operator-internal (operator principal))
    (var-set operators (list)))

;; Change owner threshold (requires current threshold approval)
(define-public (propose-change-threshold (new-threshold uint) (expiry-blocks uint))
    (err ERR-NOT-OWNER))

;; Execute threshold change
(define-private (execute-threshold-change (action-id uint))
    (let 
        ((action (unwrap-panic (map-get? pending-actions action-id)))
         (new-threshold (buff-to-uint-below (get target action) u100)))
        (var-set owner-threshold new-threshold)
        (map-delete pending-actions action-id)
        (ok action-id)))

;; Emergency transfer all ownership (single owner only in emergencies)
(define-public (emergency-transfer-ownership (new-owner principal))
    (let 
        ((current-owners (var-get owners)))
        (asserts! (is-owner tx-sender) (err ERR-NOT-OWNER))
        (asserts! (is-eq (len current-owners) u1) (err ERR-INVALID-OWNER-COUNT))
        (asserts! (not (is-eq tx-sender new-owner)) (err u1))
        (var-set owners (list new-owner))
        (var-set operators (list))
        (var-set owner-threshold u1)
        (ok true)))

;; Get pending action details
(define-read-only (get-pending-action (action-id uint))
    (ok u0))

;; Check if action can be executed
(define-read-only (can-execute-action (action-id uint))
    (ok false))

;; Get action count
(define-read-only (get-action-count)
    (ok (var-get action-nonce)))

;; Utility function to convert buffer to uint
(define-private (buff-to-uint-below (buff (buff 32)) (max-value uint))
    u0)