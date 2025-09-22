# FreelanceSecure

FreelanceSecure is a secure escrow system smart contract for freelancer project payments built on the Stacks blockchain using Clarity. The contract provides a trustless payment escrow service that protects both clients and freelancers through milestone-based payments and automated fund management.

## Features

- **Escrow Protection**: Funds are held securely in the smart contract until project completion
- **Milestone-Based Payments**: Support for breaking projects into multiple milestones with individual payments
- **Automated Fund Release**: Payments are automatically released when milestones are approved
- **Deadline Management**: Projects include deadline tracking for accountability
- **Cancellation Protection**: Refund mechanisms for expired or mutually cancelled projects
- **Role-Based Access**: Clear separation between client and freelancer permissions
- **Transparent State Management**: All project states are publicly verifiable on-chain

## Technical Specifications

- **Blockchain**: Stacks
- **Language**: Clarity 2.0
- **Epoch**: 2.5
- **Contract Version**: 1.0.0
- **Token Standard**: STX (native Stacks token)

## Project States

- **active**: Project is ongoing and accepting milestone updates
- **completed**: Project has been successfully completed and funds released
- **cancelled**: Project has been cancelled and funds refunded to client

## Installation

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) - Clarity development environment
- [Node.js](https://nodejs.org/) (v16 or higher) - For running tests
- [Stacks CLI](https://docs.stacks.co/understand-stacks/command-line-interface) - For deployment

### Setup

1. Clone the repository:
```bash
git clone <repository-url>
cd FreelanceSecure
```

2. Install dependencies:
```bash
cd FreelanceSecure_contract
npm install
```

3. Run tests:
```bash
npm test
```

4. Check contract syntax:
```bash
clarinet check
```

## Usage Examples

### Creating a New Project

```clarity
;; Client creates a project with 1000000 microSTX (1 STX)
(contract-call? .FreelanceSecure create-project
  'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7  ;; freelancer address
  u1000000                                        ;; amount in microSTX
  "Website development project"                   ;; description
  u1050400)                                       ;; deadline (block height)
```

### Adding Milestones

```clarity
;; Client adds a milestone worth 300000 microSTX (0.3 STX)
(contract-call? .FreelanceSecure add-milestone
  u1                           ;; project-id
  "Homepage design complete"   ;; milestone description
  u300000)                     ;; milestone amount
```

### Completing and Approving Milestones

```clarity
;; Freelancer marks milestone as completed
(contract-call? .FreelanceSecure complete-milestone u1 u0)

;; Client approves milestone and releases payment
(contract-call? .FreelanceSecure approve-milestone u1 u0)
```

### Releasing Full Payment

```clarity
;; Client releases full payment for projects without milestones
(contract-call? .FreelanceSecure release-payment u1)
```

## Contract Functions

### Public Functions

#### `create-project`
Creates a new escrow project and transfers funds to the contract.

**Parameters:**
- `freelancer` (principal): Address of the freelancer
- `amount` (uint): Total project amount in microSTX
- `description` (string-ascii 500): Project description
- `deadline` (uint): Project deadline as block height

**Returns:** `(response uint uint)` - Project ID on success

#### `add-milestone`
Adds a milestone to an existing project (client only).

**Parameters:**
- `project-id` (uint): Target project ID
- `milestone-description` (string-ascii 200): Milestone description
- `milestone-amount` (uint): Payment amount for this milestone

**Returns:** `(response uint uint)` - Milestone ID on success

#### `complete-milestone`
Marks a milestone as completed (freelancer only).

**Parameters:**
- `project-id` (uint): Target project ID
- `milestone-id` (uint): Target milestone ID

**Returns:** `(response bool uint)`

#### `approve-milestone`
Approves a completed milestone and releases payment (client only).

**Parameters:**
- `project-id` (uint): Target project ID
- `milestone-id` (uint): Target milestone ID

**Returns:** `(response bool uint)`

#### `release-payment`
Releases the full project payment (client only).

**Parameters:**
- `project-id` (uint): Target project ID

**Returns:** `(response bool uint)`

#### `cancel-project`
Cancels a project and refunds the client.

**Parameters:**
- `project-id` (uint): Target project ID

**Returns:** `(response bool uint)`

### Read-Only Functions

#### `get-project`
Retrieves project details.

**Parameters:**
- `project-id` (uint): Target project ID

**Returns:** Project information or none

#### `get-milestone`
Retrieves milestone details.

**Parameters:**
- `project-id` (uint): Target project ID
- `milestone-id` (uint): Target milestone ID

**Returns:** Milestone information or none

#### `get-milestone-count`
Gets the number of milestones for a project.

**Parameters:**
- `project-id` (uint): Target project ID

**Returns:** `{ count: uint }`

#### `get-next-project-id`
Returns the next available project ID.

**Returns:** `uint`

#### `is-client`
Checks if a user is the client of a project.

**Parameters:**
- `project-id` (uint): Target project ID
- `user` (principal): User address to check

**Returns:** `bool`

#### `is-freelancer`
Checks if a user is the freelancer of a project.

**Parameters:**
- `project-id` (uint): Target project ID
- `user` (principal): User address to check

**Returns:** `bool`

## Deployment Guide

### Local Testing (Clarinet)

1. Start the development environment:
```bash
clarinet console
```

2. Deploy the contract:
```clarity
::deploy_contracts
```

3. Test contract functions:
```clarity
(contract-call? .FreelanceSecure get-next-project-id)
```

### Testnet Deployment

1. Configure testnet settings in `settings/Testnet.toml`

2. Deploy to testnet:
```bash
clarinet deployments apply --network testnet
```

### Mainnet Deployment

1. Configure mainnet settings in `settings/Mainnet.toml`

2. Deploy to mainnet:
```bash
clarinet deployments apply --network mainnet
```

## Security Notes

### Access Control
- Only clients can create projects, add milestones, and approve payments
- Only freelancers can mark milestones as completed
- Both parties can initiate project cancellation under specific conditions

### Fund Safety
- All funds are held securely in the contract until release conditions are met
- Payments can only be released to the designated freelancer
- Refunds can only be issued to the original client
- The contract cannot hold funds indefinitely due to deadline mechanisms

### State Validation
- All state transitions are validated to prevent invalid operations
- Milestones must be completed before approval
- Projects must be in "active" state for most operations
- Deadline validation prevents creation of expired projects

### Error Handling
The contract includes comprehensive error codes:
- `u100`: Owner-only operation attempted by non-owner
- `u101`: Requested resource not found
- `u102`: Unauthorized operation attempted
- `u103`: Invalid state for requested operation
- `u104`: Insufficient funds provided
- `u105`: Resource already exists

### Best Practices
- Always verify project and milestone details before approval
- Set realistic deadlines to avoid premature cancellations
- Use milestones for larger projects to reduce risk
- Monitor deadline expiration to prevent unexpected cancellations

## Testing

The project includes comprehensive unit tests written in TypeScript using Vitest:

```bash
# Run all tests
npm test

# Run tests with coverage report
npm run test:report

# Watch mode for development
npm run test:watch
```

## License

ISC License

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Ensure all tests pass
6. Submit a pull request

## Support

For questions, issues, or feature requests, please open an issue in the project repository.