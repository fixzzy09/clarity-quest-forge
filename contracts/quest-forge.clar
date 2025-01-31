;; QuestForge Main Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-invalid-quest (err u101))
(define-constant err-quest-not-found (err u102))
(define-constant err-already-completed (err u103))

;; Data Variables
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
    completed: bool
  }
)

(define-data-var quest-counter uint u0)

;; Public Functions
(define-public (create-quest (title (string-utf8 64)) (difficulty uint))
  (let ((quest-id (var-get quest-counter)))
    (map-set Quests quest-id {
      creator: tx-sender,
      title: title,
      difficulty: difficulty,
      xp-reward: (* difficulty u10),
      completed: false
    })
    (var-set quest-counter (+ quest-id u1))
    (ok quest-id))
)

(define-public (complete-quest (quest-id uint))
  (let ((quest (unwrap! (map-get? Quests quest-id) (err err-quest-not-found)))
        (user (default-to {level: u1, experience: u0, quests-completed: u0} 
                (map-get? Users tx-sender))))
    (asserts! (not (get completed quest)) (err err-already-completed))
    (map-set Users tx-sender {
      level: (calculate-level (+ (get experience user) (get xp-reward quest))),
      experience: (+ (get experience user) (get xp-reward quest)),
      quests-completed: (+ (get quests-completed user) u1)
    })
    (map-set Quests quest-id (merge quest {completed: true}))
    (ok true))
)

;; Read Only Functions
(define-read-only (get-user-stats (user principal))
  (ok (default-to {level: u1, experience: u0, quests-completed: u0} 
    (map-get? Users user)))
)

(define-read-only (get-quest (quest-id uint))
  (ok (map-get? Quests quest-id))
)

;; Private Functions
(define-private (calculate-level (xp uint))
  (/ xp u100)
)
