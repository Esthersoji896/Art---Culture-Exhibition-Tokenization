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
(define-map token-royalties
    uint
    {
        artist: principal,
        percentage: uint,
    }
)

(define-constant max-royalty-percentage u1000)

(define-public (set-token-royalty
        (token-id uint)
        (artist principal)
        (percentage uint)
    )
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (is-some (map-get? token-metadata token-id)) err-invalid-token)
        (asserts! (<= percentage max-royalty-percentage) (err u107))
        (map-set token-royalties token-id {
            artist: artist,
            percentage: percentage,
        })
        (ok true)
    )
)

(define-read-only (get-token-royalty (token-id uint))
    (ok (map-get? token-royalties token-id))
)

(define-public (buy-token-with-royalty (token-id uint))
    (let (
            (listing (unwrap! (map-get? market-listings token-id) err-listing-not-found))
            (price (get price listing))
            (seller (get seller listing))
            (royalty-info (map-get? token-royalties token-id))
        )
        (match royalty-info
            royalty-data (let (
                    (artist (get artist royalty-data))
                    (royalty-amount (/ (* price (get percentage royalty-data)) u10000))
                    (seller-amount (- price royalty-amount))
                )
                (try! (stx-transfer? royalty-amount tx-sender artist))
                (try! (stx-transfer? seller-amount tx-sender seller))
                (try! (nft-transfer? art-token token-id seller tx-sender))
                (map-delete market-listings token-id)
                (ok true)
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
(define-map exhibitions
    uint
    {
        name: (string-ascii 100),
        description: (string-ascii 500),
        curator: principal,
        start-date: uint,
        end-date: uint,
        is-active: bool,
    }
)

(define-map exhibition-tokens
    {
        exhibition-id: uint,
        token-id: uint,
    }
    bool
)

(define-map curator-permissions
    principal
    bool
)

(define-data-var last-exhibition-id uint u0)

(define-public (add-curator (curator principal))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (map-set curator-permissions curator true)
        (ok true)
    )
)

(define-public (remove-curator (curator principal))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (map-delete curator-permissions curator)
        (ok true)
    )
)

(define-read-only (is-curator (user principal))
    (default-to false (map-get? curator-permissions user))
)

(define-public (create-exhibition
        (name (string-ascii 100))
        (description (string-ascii 500))
        (start-date uint)
        (end-date uint)
    )
    (let ((exhibition-id (+ (var-get last-exhibition-id) u1)))
        (asserts! (is-curator tx-sender) (err u108))
        (asserts! (> end-date start-date) (err u109))
        (map-set exhibitions exhibition-id {
            name: name,
            description: description,
            curator: tx-sender,
            start-date: start-date,
            end-date: end-date,
            is-active: true,
        })
        (var-set last-exhibition-id exhibition-id)
        (ok exhibition-id)
    )
)

(define-public (add-token-to-exhibition
        (exhibition-id uint)
        (token-id uint)
    )
    (let ((exhibition (unwrap! (map-get? exhibitions exhibition-id) (err u110))))
        (asserts! (is-eq tx-sender (get curator exhibition)) (err u111))
        (asserts! (get is-active exhibition) (err u112))
        (asserts! (is-some (map-get? token-metadata token-id)) err-invalid-token)
        (map-set exhibition-tokens {
            exhibition-id: exhibition-id,
            token-id: token-id,
        }
            true
        )
        (ok true)
    )
)

(define-public (remove-token-from-exhibition
        (exhibition-id uint)
        (token-id uint)
    )
    (let ((exhibition (unwrap! (map-get? exhibitions exhibition-id) (err u110))))
        (asserts! (is-eq tx-sender (get curator exhibition)) (err u111))
        (map-delete exhibition-tokens {
            exhibition-id: exhibition-id,
            token-id: token-id,
        })
        (ok true)
    )
)

(define-public (close-exhibition (exhibition-id uint))
    (let ((exhibition (unwrap! (map-get? exhibitions exhibition-id) (err u110))))
        (asserts! (is-eq tx-sender (get curator exhibition)) (err u111))
        (map-set exhibitions exhibition-id
            (merge exhibition { is-active: false })
        )
        (ok true)
    )
)

(define-read-only (get-exhibition (exhibition-id uint))
    (ok (map-get? exhibitions exhibition-id))
)

(define-read-only (is-token-in-exhibition
        (exhibition-id uint)
        (token-id uint)
    )
    (ok (default-to false
        (map-get? exhibition-tokens {
            exhibition-id: exhibition-id,
            token-id: token-id,
        })
    ))
)

(define-read-only (get-last-exhibition-id)
    (ok (var-get last-exhibition-id))
)

(define-map token-auctions
    uint
    {
        seller: principal,
        starting-price: uint,
        current-bid: uint,
        highest-bidder: (optional principal),
        end-block: uint,
        reserve-price: uint,
    }
)

(define-public (create-auction
        (token-id uint)
        (starting-price uint)
        (duration-blocks uint)
        (reserve-price uint)
    )
    (begin
        (asserts! (is-eq (some tx-sender) (nft-get-owner? art-token token-id))
            err-not-token-owner
        )
        (asserts! (is-none (map-get? token-auctions token-id)) err-auction-exists)
        (asserts! (is-none (map-get? market-listings token-id))
            err-listing-exists
        )
        (asserts! (> starting-price u0) err-price-too-low)
        (asserts! (> duration-blocks u0) err-invalid-date-range)
        (map-set token-auctions token-id {
            seller: tx-sender,
            starting-price: starting-price,
            current-bid: starting-price,
            highest-bidder: none,
            end-block: (+ stacks-block-height duration-blocks),
            reserve-price: reserve-price,
        })
        (ok true)
    )
)

(define-public (place-bid
        (token-id uint)
        (bid-amount uint)
    )
    (let (
            (auction (unwrap! (map-get? token-auctions token-id) err-auction-not-found))
            (current-bid (get current-bid auction))
            (end-block (get end-block auction))
            (highest-bidder (get highest-bidder auction))
        )
        (asserts! (< stacks-block-height end-block) err-auction-ended)
        (asserts! (> bid-amount current-bid) err-bid-too-low)
        (match highest-bidder
            previous-bidder (try! (stx-transfer? current-bid tx-sender previous-bidder))
            true
        )
        (try! (stx-transfer? bid-amount tx-sender (as-contract tx-sender)))
        (map-set token-auctions token-id
            (merge auction {
                current-bid: bid-amount,
                highest-bidder: (some tx-sender),
            })
        )
        (ok true)
    )
)

(define-public (finalize-auction (token-id uint))
    (let (
            (auction (unwrap! (map-get? token-auctions token-id) err-auction-not-found))
            (seller (get seller auction))
            (current-bid (get current-bid auction))
            (highest-bidder (get highest-bidder auction))
            (end-block (get end-block auction))
            (reserve-price (get reserve-price auction))
        )
        (asserts! (< end-block stacks-block-height) err-auction-not-ended)
        (match highest-bidder
            winning-bidder (begin
                (asserts! (>= current-bid reserve-price) err-bid-too-low)
                (try! (as-contract (stx-transfer? current-bid tx-sender seller)))
                (try! (nft-transfer? art-token token-id seller winning-bidder))
                (map-delete token-auctions token-id)
                (ok true)
            )
            (begin
                (map-delete token-auctions token-id)
                (ok false)
            )
        )
    )
)

(define-public (cancel-auction (token-id uint))
    (let (
            (auction (unwrap! (map-get? token-auctions token-id) err-auction-not-found))
            (seller (get seller auction))
            (highest-bidder (get highest-bidder auction))
            (current-bid (get current-bid auction))
        )
        (asserts! (is-eq tx-sender seller) err-not-token-owner)
        (asserts! (is-none highest-bidder) err-auction-active)
        (map-delete token-auctions token-id)
        (ok true)
    )
)

(define-read-only (get-auction (token-id uint))
    (ok (map-get? token-auctions token-id))
)

(define-read-only (get-auction-time-remaining (token-id uint))
    (let ((auction (unwrap! (map-get? token-auctions token-id) err-auction-not-found)))
        (let ((end-block (get end-block auction)))
            (ok (if (> end-block stacks-block-height)
                (- end-block stacks-block-height)
                u0
            ))
        )
    )
)

(define-map token-fractional-info
    uint
    {
        total-shares: uint,
        is-fractionalized: bool,
    }
)

(define-map fractional-ownership
    {
        token-id: uint,
        owner: principal,
    }
    uint
)

(define-map sale-proposals
    uint
    {
        token-id: uint,
        proposer: principal,
        sale-price: uint,
        votes-for: uint,
        votes-against: uint,
        end-block: uint,
        executed: bool,
    }
)

(define-map proposal-votes
    {
        proposal-id: uint,
        voter: principal,
    }
    bool
)

(define-data-var last-proposal-id uint u0)

(define-public (fractionalize-token
        (token-id uint)
        (total-shares uint)
    )
    (begin
        (asserts! (is-eq (some tx-sender) (nft-get-owner? art-token token-id))
            err-not-token-owner
        )
        (asserts! (is-none (map-get? token-fractional-info token-id))
            err-token-already-fractionalized
        )
        (asserts! (> total-shares u1) err-price-too-low)
        (map-set token-fractional-info token-id {
            total-shares: total-shares,
            is-fractionalized: true,
        })
        (map-set fractional-ownership {
            token-id: token-id,
            owner: tx-sender,
        }
            total-shares
        )
        (ok true)
    )
)

(define-public (transfer-fractional-shares
        (token-id uint)
        (recipient principal)
        (shares uint)
    )
    (let (
            (fractional-info (unwrap! (map-get? token-fractional-info token-id)
                err-token-not-fractionalized
            ))
            (sender-shares (default-to u0
                (map-get? fractional-ownership {
                    token-id: token-id,
                    owner: tx-sender,
                })
            ))
        )
        (asserts! (>= sender-shares shares) err-insufficient-shares)
        (asserts! (> shares u0) err-price-too-low)
        (map-set fractional-ownership {
            token-id: token-id,
            owner: tx-sender,
        }
            (- sender-shares shares)
        )
        (map-set fractional-ownership {
            token-id: token-id,
            owner: recipient,
        }
            (+
                (default-to u0
                    (map-get? fractional-ownership {
                        token-id: token-id,
                        owner: recipient,
                    })
                )
                shares
            ))
        (ok true)
    )
)

(define-public (propose-sale
        (token-id uint)
        (sale-price uint)
        (voting-duration uint)
    )
    (let (
            (proposal-id (+ (var-get last-proposal-id) u1))
            (fractional-info (unwrap! (map-get? token-fractional-info token-id)
                err-token-not-fractionalized
            ))
            (proposer-shares (default-to u0
                (map-get? fractional-ownership {
                    token-id: token-id,
                    owner: tx-sender,
                })
            ))
        )
        (asserts! (> proposer-shares u0) err-insufficient-shares)
        (asserts! (> sale-price u0) err-price-too-low)
        (map-set sale-proposals proposal-id {
            token-id: token-id,
            proposer: tx-sender,
            sale-price: sale-price,
            votes-for: u0,
            votes-against: u0,
            end-block: (+ stacks-block-height voting-duration),
            executed: false,
        })
        (var-set last-proposal-id proposal-id)
        (ok proposal-id)
    )
)

(define-public (vote-on-proposal
        (proposal-id uint)
        (vote-for bool)
    )
    (let (
            (proposal (unwrap! (map-get? sale-proposals proposal-id) err-proposal-not-found))
            (token-id (get token-id proposal))
            (voter-shares (default-to u0
                (map-get? fractional-ownership {
                    token-id: token-id,
                    owner: tx-sender,
                })
            ))
        )
        (asserts! (> voter-shares u0) err-insufficient-shares)
        (asserts! (< stacks-block-height (get end-block proposal))
            err-proposal-ended
        )
        (asserts!
            (is-none (map-get? proposal-votes {
                proposal-id: proposal-id,
                voter: tx-sender,
            }))
            err-already-voted
        )
        (map-set proposal-votes {
            proposal-id: proposal-id,
            voter: tx-sender,
        }
            true
        )
        (if vote-for
            (map-set sale-proposals proposal-id
                (merge proposal { votes-for: (+ (get votes-for proposal) voter-shares) })
            )
            (map-set sale-proposals proposal-id
                (merge proposal { votes-against: (+ (get votes-against proposal) voter-shares) })
            )
        )
        (ok true)
    )
)

(define-public (execute-sale-proposal (proposal-id uint))
    (let (
            (proposal (unwrap! (map-get? sale-proposals proposal-id) err-proposal-not-found))
            (token-id (get token-id proposal))
            (fractional-info (unwrap! (map-get? token-fractional-info token-id)
                err-token-not-fractionalized
            ))
            (total-shares (get total-shares fractional-info))
            (majority-threshold (/ total-shares u2))
        )
        (asserts! (> stacks-block-height (get end-block proposal))
            err-proposal-ended
        )
        (asserts! (not (get executed proposal)) err-proposal-not-found)
        (asserts! (> (get votes-for proposal) majority-threshold)
            err-proposal-not-approved
        )
        (try! (nft-transfer? art-token token-id (as-contract tx-sender) tx-sender))
        (map-set sale-proposals proposal-id (merge proposal { executed: true }))
        (ok true)
    )
)

(define-read-only (get-fractional-info (token-id uint))
    (ok (map-get? token-fractional-info token-id))
)

(define-read-only (get-fractional-ownership
        (token-id uint)
        (owner principal)
    )
    (ok (map-get? fractional-ownership {
        token-id: token-id,
        owner: owner,
    }))
)

(define-read-only (get-sale-proposal (proposal-id uint))
    (ok (map-get? sale-proposals proposal-id))
)

(define-read-only (get-ownership-percentage
        (token-id uint)
        (owner principal)
    )
    (let (
            (fractional-info (unwrap! (map-get? token-fractional-info token-id)
                err-token-not-fractionalized
            ))
            (owner-shares (default-to u0
                (map-get? fractional-ownership {
                    token-id: token-id,
                    owner: owner,
                })
            ))
        )
        (ok (* (/ owner-shares (get total-shares fractional-info)) u10000))
    )
)
