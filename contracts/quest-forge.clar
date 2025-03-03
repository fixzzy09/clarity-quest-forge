;; QuestForge Main Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-invalid-quest (err u101))
(define-constant err-quest-not-found (err u102))
(define-constant err-already-completed (err u103))
(define-constant err-invalid-difficulty (err u104))
(define-constant err-invalid-title-length (err u105))
(define-constant err-quest-token-failed (err u106))
(define-constant err-title-too-long (err u107))
(define-constant max-title-length u64)

;; Data Variables
(define-data-var completing-quest bool false)
(define-data-var last-event-id uint u0)

(define-map Events uint {
  event-type: (string-utf8 32),
  quest-id: uint,
  user: principal,
  timestamp: uint
})

(define-map Users principal 
  {
    level: uint,
    experience: uint,
    quests-completed: uint
  }
)

(define-map Quests uint 
  {
    creator: principal,
    title: (string-utf8 64),
    difficulty: uint,
    xp-reward: uint,
    completed: bool,
    completed-by: (optional principal),
    created-at: uint
  }
)

(define-data-var quest-counter uint u0)

;; Private Functions
(define-private (emit-event (event-type (string-utf8 32)) (quest-id uint))
  (let ((event-id (var-get last-event-id)))
    (map-set Events event-id {
      event-type: event-type,
      quest-id: quest-id,
      user: tx-sender,
      timestamp: block-height
    })
    (var-set last-event-id (+ event-id u1))
    true)
)

(define-private (calculate-level (xp uint))
  (let ((base-xp u100))
    (if (> xp u1000000) 
      u1000
      (+ (/ xp base-xp) (/ (mod xp base-xp) base-xp)))
  )
)

;; Public Functions
(define-public (create-quest (title (string-utf8 64)) (difficulty uint))
  (begin
    (asserts! (and (>= difficulty u1) (<= difficulty u5)) (err err-invalid-difficulty))
    (asserts! (and (>= (len title) u1) (<= (len title) max-title-length)) 
      (err err-invalid-title-length))
    (let ((quest-id (var-get quest-counter)))
      (map-set Quests quest-id {
        creator: tx-sender,
        title: title,
        difficulty: difficulty,
        xp-reward: (* difficulty u10),
        completed: false,
        completed-by: none,
        created-at: block-height
      })
      (var-set quest-counter (+ quest-id u1))
      (emit-event "quest-created" quest-id)
      (ok quest-id)))
)

(define-public (complete-quest (quest-id uint))
  (begin
    (asserts! (not (var-get completing-quest)) (err err-already-completed))
    (var-set completing-quest true)
    (let ((quest (unwrap! (map-get? Quests quest-id) (err err-quest-not-found)))
          (user (default-to {level: u1, experience: u0, quests-completed: u0} 
              (map-get? Users tx-sender))))
      (asserts! (not (get completed quest)) (err err-already-completed))
      (try! (map-set Users tx-sender {
        level: (calculate-level (+ (get experience user) (get xp-reward quest))),
        experience: (+ (get experience user) (get xp-reward quest)),
        quests-completed: (+ (get quests-completed user) u1)
      }))
      (map-set Quests quest-id (merge quest {
        completed: true,
        completed-by: (some tx-sender)
      }))
      (emit-event "quest-completed" quest-id)
      (var-set completing-quest false)
      (unwrap! (contract-call? .quest-token mint (get xp-reward quest) tx-sender)
        err-quest-token-failed)
      (ok true)))
)

;; Read Only Functions
(define-read-only (get-user-stats (user principal))
  (ok (default-to {level: u1, experience: u0, quests-completed: u0} 
    (map-get? Users user)))
)

(define-read-only (get-quest (quest-id uint))
  (ok (map-get? Quests quest-id))
)

(define-read-only (get-events (from uint) (to uint))
  (ok (map get-event (list from to)))
)

(define-private (get-event (id uint))
  (map-get? Events id)
)
