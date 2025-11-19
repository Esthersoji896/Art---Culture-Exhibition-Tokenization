# Art & Culture Exhibition Tokenization

A comprehensive decentralized platform for tokenizing museum entries and gallery pieces as NFTs with historical metadata and advanced collection management capabilities.

## 🌟 Features

### Core NFT Functionality
- Mint NFTs with detailed artwork metadata
- Secure ownership transfer and validation
- Authenticity verification system with hash validation
- Comprehensive metadata storage (title, artist, year, medium, description, origin)

### Collection Management System (New!)
- Create themed art collections with customizable metadata
- Add/remove artworks to/from collections
- Public/private collection visibility settings
- Collection ownership and permission controls
- Update collection information dynamically

### Marketplace & Trading
- List artworks for sale with price validation
- Secure buying and selling mechanisms
- STX token integration for payments
- Listing management (list/unlist tokens)

## 🛠 Technical Stack

- **Smart Contracts**: Clarity v3 on Stacks Blockchain
- **NFT Standard**: SIP-009 compliant
- **Testing**: Clarinet SDK with Vitest
- **TypeScript**: Full type safety for tests
- **Development**: Hot-reload testing environment

## 🚀 Getting Started

### Prerequisites
- [Clarinet](https://github.com/hirosystems/clarinet) installed
- Node.js 16+ for testing
- Git for version control

### Installation

1. Clone the repository
```bash
git clone https://github.com/Esthersoji896/Art---Culture-Exhibition-Tokenization.git
cd Art---Culture-Exhibition-Tokenization
```

2. Install dependencies
```bash
npm install
```

3. Validate smart contracts
```bash
clarinet check
```

4. Run tests
```bash
npm test
```

## 📋 Smart Contract Functions

### Collection Management System

#### Public Functions
- `create-collection`: Create a new art collection with theme and visibility settings
- `add-token-to-collection`: Add an artwork NFT to a specific collection
- `remove-token-from-collection`: Remove artwork from collection
- `update-collection-metadata`: Modify collection name, description, and theme
- `set-collection-visibility`: Toggle public/private collection status

#### Read-Only Functions
- `get-collection-details`: Retrieve complete collection information
- `is-token-in-collection`: Check if a specific token belongs to a collection
- `get-last-collection-id`: Get the total number of collections created

### NFT Core Functions
- `mint`: Create new artwork NFTs (owner-only)
- `transfer`: Secure token transfers between users
- `get-token-metadata`: Retrieve artwork details
- `get-owner`: Check token ownership
- `validate-authenticity`: Verify artwork authenticity using hash

### Marketplace Functions
- `list-token`: Put artwork up for sale
- `unlist-token`: Remove artwork from marketplace
- `buy-token`: Purchase listed artwork with STX

## 🔒 Security Features

- **Owner-only minting**: Only contract owner can mint new NFTs
- **Collection ownership**: Only collection creators can modify their collections
- **Transfer validation**: Strict ownership checks for all transfers
- **Input validation**: Comprehensive data validation for all functions
- **Error handling**: Clear error codes for all failure scenarios

## 🧪 Testing

The project includes comprehensive test coverage:

- ✅ NFT minting and metadata retrieval
- ✅ Collection creation and management
- ✅ Token-to-collection relationships
- ✅ Marketplace functionality
- ✅ Error handling and edge cases
- ✅ Permission and ownership controls

Run tests with detailed output:
```bash
npm run test:report
```

## 📊 Error Codes

| Code | Error | Description |
|------|-------|-------------|
| u100 | err-owner-only | Only contract owner can perform this action |
| u101 | err-not-token-owner | User doesn't own the specified token |
| u103 | err-invalid-token | Token doesn't exist |
| u105 | err-listing-not-found | Marketplace listing not found |
| u106 | err-price-too-low | Price must be greater than zero |
| u126 | err-collection-not-found | Collection doesn't exist |
| u127 | err-not-collection-owner | User doesn't own the collection |
| u128 | err-token-already-in-collection | Token is already in the collection |
| u129 | err-invalid-collection-data | Collection data validation failed |

## 🎨 Use Cases

### For Museums & Galleries
- Tokenize artwork collections with detailed provenance
- Create themed exhibitions as on-chain collections
- Enable secure digital ownership transfers
- Maintain authenticity verification records

### For Collectors
- Organize personal art collections digitally
- Trade artworks in a secure marketplace
- Verify artwork authenticity before purchase
- Create public or private collection showcases

### For Artists
- Mint original works with comprehensive metadata
- Organize works into themed collections
- Control distribution and ownership records
- Enable secondary market royalties (extensible)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙋‍♀️ Support

For questions and support:
- Create an issue in this repository
- Contact: Esthersoji896@gmail.com

---

Built with ❤️ for the art and culture community using Stacks blockchain technology.

