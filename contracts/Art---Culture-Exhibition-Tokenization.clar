;; Art & Culture Exhibition Tokenization Smart Contract
;; A comprehensive platform for tokenizing museum entries and gallery pieces as NFTs

;; Error Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-token-owner (err u101))
(define-constant err-token-exists (err u102))
(define-constant err-invalid-token (err u103))
(define-constant err-listing-exists (err u104))
(define-constant err-listing-not-found (err u105))
(define-constant err-price-too-low (err u106))
(define-constant err-invalid-royalty-percentage (err u107))
(define-constant err-not-curator (err u108))
(define-constant err-invalid-date-range (err u109))
(define-constant err-exhibition-not-found (err u110))
(define-constant err-not-exhibition-curator (err u111))
(define-constant err-exhibition-not-active (err u112))
(define-constant err-auction-exists (err u113))
(define-constant err-auction-not-found (err u114))
(define-constant err-auction-ended (err u115))
(define-constant err-auction-not-ended (err u116))
(define-constant err-bid-too-low (err u117))
(define-constant err-auction-active (err u118))
(define-constant err-token-already-fractionalized (err u119))
(define-constant err-token-not-fractionalized (err u120))
(define-constant err-insufficient-shares (err u121))
(define-constant err-proposal-not-found (err u122))
(define-constant err-proposal-ended (err u123))
(define-constant err-already-voted (err u124))
(define-constant err-proposal-not-approved (err u125))
;; Collection Management System Error Constants
(define-constant err-collection-not-found (err u126))
(define-constant err-not-collection-owner (err u127))
(define-constant err-token-already-in-collection (err u128))
(define-constant err-invalid-collection-data (err u129))
(define-constant err-invalid-royalty-bps (err u130))

;; NFT Definition
(define-non-fungible-token art-token uint)

;; Core Data Maps
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

(define-map token-royalties
    uint
    {
        recipient: principal,
        bps: uint,
    }
)

;; Collection Management System Data Maps
(define-map collections
    uint
    {
        name: (string-ascii 100),
        description: (string-ascii 500),
        theme: (string-ascii 50),
        creator: principal,
        is-public: bool,
        created-at: uint,
    }
)

(define-map collection-tokens
    {
        collection-id: uint,
        token-id: uint,
    }
    bool
)

;; Data Variables
(define-data-var last-token-id uint u0)
(define-data-var last-collection-id uint u0)

;; Core NFT Functions
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

(define-read-only (get-royalty (token-id uint))
    (ok (map-get? token-royalties token-id))
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

;; Marketplace Functions
(define-public (set-royalty
        (token-id uint)
        (recipient principal)
        (bps uint)
    )
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (is-some (nft-get-owner? art-token token-id)) err-invalid-token)
        (asserts! (and (>= bps u0) (<= bps u10000)) err-invalid-royalty-bps)
        (map-set token-royalties token-id {
            recipient: recipient,
            bps: bps,
        })
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
            (royalty (map-get? token-royalties token-id))
        )
        (if (is-some royalty)
            (let (
                    (royalty-data (unwrap-panic royalty))
                    (bps (get bps royalty-data))
                    (recipient (get recipient royalty-data))
                    (royalty-amount (/ (* price bps) u10000))
                    (seller-amount (- price royalty-amount))
                )
                (begin
                    (if (> royalty-amount u0)
                        (begin
                            (try! (stx-transfer? royalty-amount tx-sender recipient))
                            true
                        )
                        true
                    )
                    (try! (stx-transfer? seller-amount tx-sender seller))
                    (try! (nft-transfer? art-token token-id seller tx-sender))
                    (map-delete market-listings token-id)
                    (ok true)
                )
            )
            (begin
                (try! (stx-transfer? price tx-sender seller))
                (try! (nft-transfer? art-token token-id seller tx-sender))
                (map-delete market-listings token-id)
                (ok true)
            )
        )
    )
)

;; Collection Management System Functions

;; Create a new art collection
(define-public (create-collection
        (name (string-ascii 100))
        (description (string-ascii 500))
        (theme (string-ascii 50))
        (is-public bool)
    )
    (let ((collection-id (+ (var-get last-collection-id) u1)))
        (asserts! (> (len name) u0) err-invalid-collection-data)
        (asserts! (> (len description) u0) err-invalid-collection-data)
        (map-set collections collection-id {
            name: name,
            description: description,
            theme: theme,
            creator: tx-sender,
            is-public: is-public,
            created-at: stacks-block-height,
        })
        (var-set last-collection-id collection-id)
        (ok collection-id)
    )
)

;; Add a token to a collection
(define-public (add-token-to-collection
        (collection-id uint)
        (token-id uint)
    )
    (let ((collection (unwrap! (map-get? collections collection-id) err-collection-not-found)))
        (asserts! (is-eq tx-sender (get creator collection))
            err-not-collection-owner
        )
        (asserts! (is-some (map-get? token-metadata token-id)) err-invalid-token)
        (asserts!
            (is-none (map-get? collection-tokens {
                collection-id: collection-id,
                token-id: token-id,
            }))
            err-token-already-in-collection
        )
        (map-set collection-tokens {
            collection-id: collection-id,
            token-id: token-id,
        }
            true
        )
        (ok true)
    )
)

;; Remove a token from a collection
(define-public (remove-token-from-collection
        (collection-id uint)
        (token-id uint)
    )
    (let ((collection (unwrap! (map-get? collections collection-id) err-collection-not-found)))
        (asserts! (is-eq tx-sender (get creator collection))
            err-not-collection-owner
        )
        (map-delete collection-tokens {
            collection-id: collection-id,
            token-id: token-id,
        })
        (ok true)
    )
)

;; Update collection metadata
(define-public (update-collection-metadata
        (collection-id uint)
        (name (string-ascii 100))
        (description (string-ascii 500))
        (theme (string-ascii 50))
    )
    (let ((collection (unwrap! (map-get? collections collection-id) err-collection-not-found)))
        (asserts! (is-eq tx-sender (get creator collection))
            err-not-collection-owner
        )
        (asserts! (> (len name) u0) err-invalid-collection-data)
        (asserts! (> (len description) u0) err-invalid-collection-data)
        (map-set collections collection-id
            (merge collection {
                name: name,
                description: description,
                theme: theme,
            })
        )
        (ok true)
    )
)

;; Set collection visibility (public/private)
(define-public (set-collection-visibility
        (collection-id uint)
        (is-public bool)
    )
    (let ((collection (unwrap! (map-get? collections collection-id) err-collection-not-found)))
        (asserts! (is-eq tx-sender (get creator collection))
            err-not-collection-owner
        )
        (map-set collections collection-id
            (merge collection { is-public: is-public })
        )
        (ok true)
    )
)

;; Collection Management Read-Only Functions

;; Get collection details
(define-read-only (get-collection-details (collection-id uint))
    (ok (map-get? collections collection-id))
)

;; Check if a token is in a collection
(define-read-only (is-token-in-collection
        (collection-id uint)
        (token-id uint)
    )
    (ok (default-to false
        (map-get? collection-tokens {
            collection-id: collection-id,
            token-id: token-id,
        })
    ))
)

;; Get the last collection ID
(define-read-only (get-last-collection-id)
    (ok (var-get last-collection-id))
)

;; Authenticity Verification
(define-read-only (validate-authenticity
        (token-id uint)
        (hash-to-verify (buff 32))
    )
    (let ((metadata (unwrap! (map-get? token-metadata token-id) err-invalid-token)))
        (ok (is-eq (get authenticity-hash metadata) hash-to-verify))
    )
)

;; Utility Functions
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
