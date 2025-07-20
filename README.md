# Digital Dog Park Administration System

A comprehensive blockchain-based system for managing digital dog park operations, built on the Stacks blockchain using Clarity smart contracts.

## System Overview

The Digital Dog Park Administration system consists of five interconnected smart contracts that handle different aspects of dog park management:

### 1. Registration Verification Contract (`pet-registration.clar`)
- Validates pet vaccinations and licenses
- Maintains registry of approved pets
- Tracks vaccination expiration dates
- Manages pet owner information

### 2. Access Control Contract (`access-control.clar`)
- Manages keycard entry to fenced dog areas
- Controls access permissions based on registration status
- Tracks entry/exit logs
- Handles temporary access grants

### 3. Maintenance Scheduling Contract (`maintenance-scheduler.clar`)
- Coordinates waste cleanup schedules
- Manages facility repair requests
- Tracks maintenance completion
- Assigns maintenance tasks to staff

### 4. Event Planning Contract (`event-planner.clar`)
- Organizes dog training classes
- Manages adoption events
- Handles event registration and capacity
- Tracks event attendance

### 5. Incident Reporting Contract (`incident-reporter.clar`)
- Records dog bite incidents
- Documents safety concerns
- Maintains incident history
- Generates safety reports

## Features

### Pet Registration System
- **Vaccination Tracking**: Monitor vaccination status and expiration dates
- **License Verification**: Validate city/county pet licenses
- **Owner Management**: Maintain pet owner contact information
- **Registration Status**: Track active/inactive registrations

### Access Management
- **Keycard System**: Digital keycard management for park access
- **Area Restrictions**: Control access to specific fenced areas
- **Time-based Access**: Implement operating hours and restrictions
- **Emergency Override**: Admin access for emergency situations

### Maintenance Operations
- **Scheduled Cleaning**: Automated waste cleanup scheduling
- **Repair Tracking**: Monitor facility repair needs and completion
- **Staff Assignment**: Assign maintenance tasks to appropriate personnel
- **Resource Management**: Track maintenance supplies and equipment

### Event Coordination
- **Class Scheduling**: Organize dog training sessions
- **Adoption Events**: Coordinate pet adoption activities
- **Capacity Management**: Control event attendance limits
- **Registration System**: Handle event sign-ups and waitlists

### Safety & Incident Management
- **Incident Documentation**: Record and categorize safety incidents
- **Bite Reports**: Specialized handling of dog bite incidents
- **Safety Analytics**: Generate reports on park safety trends
- **Follow-up Tracking**: Monitor incident resolution progress

## Technical Architecture

### Smart Contract Design
- **Modular Architecture**: Each contract handles a specific domain
- **Data Integrity**: Comprehensive input validation and error handling
- **Access Control**: Role-based permissions for different user types
- **Event Logging**: Comprehensive audit trail for all operations

### Data Types
- **Pet Records**: Comprehensive pet information with vaccination data
- **User Roles**: Admin, staff, pet owner, and visitor permissions
- **Timestamps**: Blockchain-based timestamping for all records
- **Status Tracking**: Real-time status updates for all system components

## Getting Started

### Prerequisites
- Clarinet CLI installed
- Node.js and npm for testing
- Stacks wallet for deployment

### Installation
1. Clone the repository
2. Install dependencies: `npm install`
3. Run tests: `npm test`
4. Deploy contracts: `clarinet deploy`

### Usage Examples

#### Register a Pet
```clarity
(contract-call? .pet-registration register-pet 
  "Buddy" 
  "Golden Retriever" 
  u1234567890 
  u1735689600)
