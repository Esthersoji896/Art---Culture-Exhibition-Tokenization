(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-token-owner (err u101))
(define-constant err-token-exists (err u102))
(define-constant err-invalid-token (err u103))
(define-constant err-listing-exists (err u104))
(define-constant err-listing-not-found (err u105))
(define-constant err-price-too-low (err u106))

(define-non-fungible-token art-token uint)

(define-map token-metadata
    uint
    {
        title: (string-ascii 100),
        artist: (string-ascii 100),
        year: uint,
        medium: (string-ascii 50),
        description: (string-ascii 500),
        origin: (string-ascii 100),
        authenticity-hash: (buff 32),
    }
)

(define-map token-uris
    uint
    (string-ascii 256)
)

(define-map market-listings
    uint
    {
        price: uint,
        seller: principal,
    }
)

(define-data-var last-token-id uint u0)

(define-read-only (get-last-token-id)
    (ok (var-get last-token-id))
)

(define-read-only (get-token-uri (token-id uint))
    (ok (map-get? token-uris token-id))
)

(define-read-only (get-owner (token-id uint))
    (ok (nft-get-owner? art-token token-id))
)

(define-read-only (get-token-metadata (token-id uint))
    (ok (map-get? token-metadata token-id))
)

(define-read-only (get-listing (token-id uint))
    (ok (map-get? market-listings token-id))
)

(define-public (mint
        (title (string-ascii 100))
        (artist (string-ascii 100))
        (year uint)
        (medium (string-ascii 50))
        (description (string-ascii 500))
        (origin (string-ascii 100))
        (authenticity-hash (buff 32))
        (uri (string-ascii 256))
    )
    (let ((token-id (+ (var-get last-token-id) u1)))
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (try! (nft-mint? art-token token-id tx-sender))
        (map-set token-metadata token-id {
            title: title,
            artist: artist,
            year: year,
            medium: medium,
            description: description,
            origin: origin,
            authenticity-hash: authenticity-hash,
        })
        (map-set token-uris token-id uri)
        (var-set last-token-id token-id)
        (ok token-id)
    )
)

(define-public (transfer
        (token-id uint)
        (sender principal)
        (recipient principal)
    )
    (begin
        (asserts! (is-eq tx-sender sender) err-not-token-owner)
        (asserts! (is-some (nft-get-owner? art-token token-id)) err-invalid-token)
        (try! (nft-transfer? art-token token-id sender recipient))
        (ok true)
    )
)

(define-public (list-token
        (token-id uint)
        (price uint)
    )
    (begin
        (asserts! (is-eq (some tx-sender) (nft-get-owner? art-token token-id))
            err-not-token-owner
        )
        (asserts! (> price u0) err-price-too-low)
        (map-set market-listings token-id {
            price: price,
            seller: tx-sender,
        })
        (ok true)
    )
)

(define-public (unlist-token (token-id uint))
    (begin
        (asserts! (is-eq (some tx-sender) (nft-get-owner? art-token token-id))
            err-not-token-owner
        )
        (map-delete market-listings token-id)
        (ok true)
    )
)

(define-public (buy-token (token-id uint))
    (let (
            (listing (unwrap! (map-get? market-listings token-id) err-listing-not-found))
            (price (get price listing))
            (seller (get seller listing))
        )
        (try! (stx-transfer? price tx-sender seller))
        (try! (nft-transfer? art-token token-id seller tx-sender))
        (map-delete market-listings token-id)
        (ok true)
    )
)

(define-public (update-token-metadata
        (token-id uint)
        (title (string-ascii 100))
        (artist (string-ascii 100))
        (year uint)
        (medium (string-ascii 50))
        (description (string-ascii 500))
        (origin (string-ascii 100))
        (authenticity-hash (buff 32))
    )
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (is-some (map-get? token-metadata token-id)) err-invalid-token)
        (map-set token-metadata token-id {
            title: title,
            artist: artist,
            year: year,
            medium: medium,
            description: description,
            origin: origin,
            authenticity-hash: authenticity-hash,
        })
        (ok true)
    )
)

(define-read-only (validate-authenticity
        (token-id uint)
        (hash-to-verify (buff 32))
    )
    (let ((metadata (unwrap! (map-get? token-metadata token-id) err-invalid-token)))
        (ok (is-eq (get authenticity-hash metadata) hash-to-verify))
    )
)
