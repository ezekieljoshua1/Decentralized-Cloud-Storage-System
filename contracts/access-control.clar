;; Access Control Contract
;; Manages file sharing permissions and access rights

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u200))
(define-constant ERR-PERMISSION-NOT-FOUND (err u201))
(define-constant ERR-INVALID-PERMISSION (err u202))
(define-constant ERR-PERMISSION-EXISTS (err u203))

;; Permission Types
(define-constant PERMISSION-READ "read")
(define-constant PERMISSION-WRITE "write")
(define-constant PERMISSION-ADMIN "admin")

;; Data Maps
(define-map file-permissions
  { file-id: (string-ascii 64), user: principal }
  {
    permission-type: (string-ascii 10),
    granted-by: principal,
    granted-at: uint,
    expires-at: (optional uint),
    is-active: bool
  }
)

(define-map permission-delegations
  { delegator: principal, delegatee: principal, file-id: (string-ascii 64) }
  {
    permission-type: (string-ascii 10),
    created-at: uint,
    expires-at: (optional uint),
    is-active: bool
  }
)

(define-map user-permissions-count
  { user: principal }
  { granted: uint, received: uint }
)

;; Private Functions
(define-private (is-valid-permission (permission (string-ascii 10)))
  (or (is-eq permission PERMISSION-READ)
      (or (is-eq permission PERMISSION-WRITE)
          (is-eq permission PERMISSION-ADMIN)))
)

(define-private (has-admin-permission (file-id (string-ascii 64)) (user principal))
  (match (map-get? file-permissions { file-id: file-id, user: user })
    permission-data (and (get is-active permission-data)
                        (is-eq (get permission-type permission-data) PERMISSION-ADMIN))
    false
  )
)

(define-private (update-permission-count (granter principal) (grantee principal) (increment bool))
  (let ((granter-stats (default-to { granted: u0, received: u0 }
                                  (map-get? user-permissions-count { user: granter })))
        (grantee-stats (default-to { granted: u0, received: u0 }
                                  (map-get? user-permissions-count { user: grantee }))))
    (if increment
      (begin
        (map-set user-permissions-count
          { user: granter }
          (merge granter-stats { granted: (+ (get granted granter-stats) u1) }))
        (map-set user-permissions-count
          { user: grantee }
          (merge grantee-stats { received: (+ (get received grantee-stats) u1) })))
      (begin
        (map-set user-permissions-count
          { user: granter }
          (merge granter-stats { granted: (- (get granted granter-stats) u1) }))
        (map-set user-permissions-count
          { user: grantee }
          (merge grantee-stats { received: (- (get received grantee-stats) u1) }))))
  )
)

;; Public Functions
(define-public (grant-access (file-id (string-ascii 64))
                            (user principal)
                            (permission-type (string-ascii 10))
                            (expires-at (optional uint)))
  (begin
    (asserts! (is-valid-permission permission-type) ERR-INVALID-PERMISSION)
    (asserts! (is-none (map-get? file-permissions { file-id: file-id, user: user })) ERR-PERMISSION-EXISTS)

    (map-set file-permissions
      { file-id: file-id, user: user }
      {
        permission-type: permission-type,
        granted-by: tx-sender,
        granted-at: block-height,
        expires-at: expires-at,
        is-active: true
      }
    )

    (update-permission-count tx-sender user true)
    (ok true)
  )
)

(define-public (revoke-access (file-id (string-ascii 64)) (user principal))
  (let ((permission-data (unwrap! (map-get? file-permissions { file-id: file-id, user: user })
                                 ERR-PERMISSION-NOT-FOUND)))
    (asserts! (or (is-eq (get granted-by permission-data) tx-sender)
                 (has-admin-permission file-id tx-sender)) ERR-NOT-AUTHORIZED)

    (map-set file-permissions
      { file-id: file-id, user: user }
      (merge permission-data { is-active: false })
    )

    (update-permission-count (get granted-by permission-data) user false)
    (ok true)
  )
)

(define-public (delegate-permission (delegatee principal)
                                   (file-id (string-ascii 64))
                                   (permission-type (string-ascii 10))
                                   (expires-at (optional uint)))
  (begin
    (asserts! (is-valid-permission permission-type) ERR-INVALID-PERMISSION)
    (asserts! (has-permission file-id tx-sender permission-type) ERR-NOT-AUTHORIZED)

    (map-set permission-delegations
      { delegator: tx-sender, delegatee: delegatee, file-id: file-id }
      {
        permission-type: permission-type,
        created-at: block-height,
        expires-at: expires-at,
        is-active: true
      }
    )

    (ok true)
  )
)

(define-public (revoke-delegation (delegatee principal) (file-id (string-ascii 64)))
  (let ((delegation-data (unwrap! (map-get? permission-delegations
                                           { delegator: tx-sender, delegatee: delegatee, file-id: file-id })
                                 ERR-PERMISSION-NOT-FOUND)))
    (map-set permission-delegations
      { delegator: tx-sender, delegatee: delegatee, file-id: file-id }
      (merge delegation-data { is-active: false })
    )
    (ok true)
  )
)

;; Read-only Functions
(define-read-only (has-permission (file-id (string-ascii 64))
                                 (user principal)
                                 (permission-type (string-ascii 10)))
  (match (map-get? file-permissions { file-id: file-id, user: user })
    permission-data
      (and (get is-active permission-data)
           (or (is-eq (get permission-type permission-data) permission-type)
               (is-eq (get permission-type permission-data) PERMISSION-ADMIN))
           (match (get expires-at permission-data)
             expiry (> expiry block-height)
             true))
    false
  )
)

(define-read-only (get-file-permissions (file-id (string-ascii 64)) (user principal))
  (map-get? file-permissions { file-id: file-id, user: user })
)

(define-read-only (get-delegation (delegator principal) (delegatee principal) (file-id (string-ascii 64)))
  (map-get? permission-delegations { delegator: delegator, delegatee: delegatee, file-id: file-id })
)

(define-read-only (get-user-permission-stats (user principal))
  (map-get? user-permissions-count { user: user })
)

(define-read-only (check-access (file-id (string-ascii 64))
                               (user principal)
                               (required-permission (string-ascii 10)))
  (has-permission file-id user required-permission)
)
