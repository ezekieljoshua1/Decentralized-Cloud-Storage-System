# Decentralized Cloud Storage System

A comprehensive blockchain-based cloud storage solution built on Stacks using Clarity smart contracts.

## Overview

This system provides secure, decentralized file storage with encryption, access control, redundancy, and bandwidth optimization. Files are distributed across multiple nodes with cryptographic security and economic incentives.

## Architecture

### Core Contracts

1. **File Storage Contract** (`file-storage.clar`)
    - Handles file encryption and storage metadata
    - Manages file uploads, downloads, and deletion
    - Tracks file ownership and storage locations

2. **Access Control Contract** (`access-control.clar`)
    - Manages file sharing permissions
    - Controls read/write access rights
    - Handles permission delegation and revocation

3. **Fee Calculator Contract** (`fee-calculator.clar`)
    - Calculates storage costs based on file size and duration
    - Manages pricing tiers and discounts
    - Handles payment processing and refunds

4. **Data Redundancy Contract** (`data-redundancy.clar`)
    - Ensures file backup across multiple nodes
    - Manages replication strategies
    - Handles node failure recovery

5. **Bandwidth Optimizer Contract** (`bandwidth-optimizer.clar`)
    - Optimizes data transfer routes
    - Manages caching and CDN-like functionality
    - Tracks bandwidth usage and costs

## Features

- **End-to-End Encryption**: Files are encrypted before storage
- **Decentralized Storage**: Data distributed across multiple nodes
- **Access Control**: Granular permission management
- **Economic Incentives**: Fair pricing and node rewards
- **High Availability**: Automatic backup and recovery
- **Bandwidth Optimization**: Efficient data transfer

## Getting Started

### Prerequisites

- Clarinet CLI
- Node.js 18+
- Stacks wallet

### Installation

\`\`\`bash
git clone <repository-url>
cd decentralized-cloud-storage
npm install
clarinet check
\`\`\`

### Testing

\`\`\`bash
npm test
\`\`\`

### Deployment

\`\`\`bash
clarinet deploy --testnet
\`\`\`

## Usage

### Storing a File

\`\`\`clarity
(contract-call? .file-storage store-file
"file-hash"
u1024
"encrypted-metadata")
\`\`\`

### Setting Permissions

\`\`\`clarity
(contract-call? .access-control grant-access
"file-id"
'SP1234...
"read")
\`\`\`

### Calculating Storage Fees

\`\`\`clarity
(contract-call? .fee-calculator calculate-storage-fee
u1024
u30)
\`\`\`

## Security Considerations

- All files are encrypted client-side before upload
- Private keys never leave the user's device
- Smart contracts handle only metadata and access control
- Regular security audits recommended

## Contributing

1. Fork the repository
2. Create a feature branch
3. Write tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## License

MIT License - see LICENSE file for details
