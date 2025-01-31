;; Achievement Token Contract
(define-fungible-token quest-token)

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))

;; Public Functions
(define-public (mint (amount uint) (recipient principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (ft-mint? quest-token amount recipient))
)

(define-public (transfer (amount uint) (sender principal) (recipient principal))
  (ft-transfer? quest-token amount sender recipient)
)

;; Read Only Functions
(define-read-only (get-balance (account principal))
  (ok (ft-get-balance quest-token account))
)
