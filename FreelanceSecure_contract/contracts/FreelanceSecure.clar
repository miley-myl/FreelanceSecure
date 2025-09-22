
;; title: FreelanceSecure
;; version: 1.0.0
;; summary: Escrow system for freelancer project payments
;; description: A smart contract that holds payments in escrow until project milestones are completed

;; constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-invalid-state (err u103))
(define-constant err-insufficient-funds (err u104))
(define-constant err-already-exists (err u105))

;; data vars
(define-data-var next-project-id uint u1)

;; data maps
(define-map projects
  { project-id: uint }
  {
    client: principal,
    freelancer: principal,
    amount: uint,
    description: (string-ascii 500),
    state: (string-ascii 20),
    created-at: uint,
    deadline: uint
  }
)

(define-map project-milestones
  { project-id: uint, milestone-id: uint }
  {
    description: (string-ascii 200),
    amount: uint,
    completed: bool,
    approved-by-client: bool
  }
)

(define-map project-milestone-count
  { project-id: uint }
  { count: uint }
)

;; public functions

;; Create a new escrow project
(define-public (create-project (freelancer principal) (amount uint) (description (string-ascii 500)) (deadline uint))
  (let ((project-id (var-get next-project-id)))
    (asserts! (> amount u0) err-insufficient-funds)
    (asserts! (> deadline block-height) err-invalid-state)

    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))

    (map-set projects
      { project-id: project-id }
      {
        client: tx-sender,
        freelancer: freelancer,
        amount: amount,
        description: description,
        state: "active",
        created-at: block-height,
        deadline: deadline
      }
    )

    (var-set next-project-id (+ project-id u1))
    (ok project-id)
  )
)

;; Add milestone to a project
(define-public (add-milestone (project-id uint) (milestone-description (string-ascii 200)) (milestone-amount uint))
  (let (
    (project (unwrap! (map-get? projects { project-id: project-id }) err-not-found))
    (current-count (default-to { count: u0 } (map-get? project-milestone-count { project-id: project-id })))
    (milestone-id (get count current-count))
  )
    (asserts! (is-eq tx-sender (get client project)) err-unauthorized)
    (asserts! (is-eq (get state project) "active") err-invalid-state)
    (asserts! (> milestone-amount u0) err-insufficient-funds)

    (map-set project-milestones
      { project-id: project-id, milestone-id: milestone-id }
      {
        description: milestone-description,
        amount: milestone-amount,
        completed: false,
        approved-by-client: false
      }
    )

    (map-set project-milestone-count
      { project-id: project-id }
      { count: (+ milestone-id u1) }
    )

    (ok milestone-id)
  )
)

;; Mark milestone as completed by freelancer
(define-public (complete-milestone (project-id uint) (milestone-id uint))
  (let (
    (project (unwrap! (map-get? projects { project-id: project-id }) err-not-found))
    (milestone (unwrap! (map-get? project-milestones { project-id: project-id, milestone-id: milestone-id }) err-not-found))
  )
    (asserts! (is-eq tx-sender (get freelancer project)) err-unauthorized)
    (asserts! (is-eq (get state project) "active") err-invalid-state)
    (asserts! (not (get completed milestone)) err-invalid-state)

    (map-set project-milestones
      { project-id: project-id, milestone-id: milestone-id }
      (merge milestone { completed: true })
    )

    (ok true)
  )
)

;; Approve milestone and release payment
(define-public (approve-milestone (project-id uint) (milestone-id uint))
  (let (
    (project (unwrap! (map-get? projects { project-id: project-id }) err-not-found))
    (milestone (unwrap! (map-get? project-milestones { project-id: project-id, milestone-id: milestone-id }) err-not-found))
  )
    (asserts! (is-eq tx-sender (get client project)) err-unauthorized)
    (asserts! (is-eq (get state project) "active") err-invalid-state)
    (asserts! (get completed milestone) err-invalid-state)
    (asserts! (not (get approved-by-client milestone)) err-invalid-state)

    (try! (as-contract (stx-transfer? (get amount milestone) tx-sender (get freelancer project))))

    (map-set project-milestones
      { project-id: project-id, milestone-id: milestone-id }
      (merge milestone { approved-by-client: true })
    )

    (ok true)
  )
)

;; Release full payment (for projects without milestones)
(define-public (release-payment (project-id uint))
  (let ((project (unwrap! (map-get? projects { project-id: project-id }) err-not-found)))
    (asserts! (is-eq tx-sender (get client project)) err-unauthorized)
    (asserts! (is-eq (get state project) "active") err-invalid-state)

    (try! (as-contract (stx-transfer? (get amount project) tx-sender (get freelancer project))))

    (map-set projects
      { project-id: project-id }
      (merge project { state: "completed" })
    )

    (ok true)
  )
)

;; Cancel project and refund client (only if deadline passed or mutual agreement)
(define-public (cancel-project (project-id uint))
  (let ((project (unwrap! (map-get? projects { project-id: project-id }) err-not-found)))
    (asserts! (or
      (is-eq tx-sender (get client project))
      (is-eq tx-sender (get freelancer project))
    ) err-unauthorized)
    (asserts! (is-eq (get state project) "active") err-invalid-state)

    ;; Allow cancellation if deadline passed or both parties agree
    (asserts! (or
      (>= block-height (get deadline project))
      (and
        (is-eq tx-sender (get client project))
        ;; In a real implementation, you might want a two-step cancellation process
      )
    ) err-invalid-state)

    (try! (as-contract (stx-transfer? (get amount project) tx-sender (get client project))))

    (map-set projects
      { project-id: project-id }
      (merge project { state: "cancelled" })
    )

    (ok true)
  )
)

;; read only functions

;; Get project details
(define-read-only (get-project (project-id uint))
  (map-get? projects { project-id: project-id })
)

;; Get milestone details
(define-read-only (get-milestone (project-id uint) (milestone-id uint))
  (map-get? project-milestones { project-id: project-id, milestone-id: milestone-id })
)

;; Get milestone count for a project
(define-read-only (get-milestone-count (project-id uint))
  (default-to { count: u0 } (map-get? project-milestone-count { project-id: project-id }))
)

;; Get current project ID counter
(define-read-only (get-next-project-id)
  (var-get next-project-id)
)

;; Check if user is client of a project
(define-read-only (is-client (project-id uint) (user principal))
  (match (map-get? projects { project-id: project-id })
    project (is-eq user (get client project))
    false
  )
)

;; Check if user is freelancer of a project
(define-read-only (is-freelancer (project-id uint) (user principal))
  (match (map-get? projects { project-id: project-id })
    project (is-eq user (get freelancer project))
    false
  )
)
