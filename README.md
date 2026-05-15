# ZipProperty - Property Management System

A comprehensive property management system that allows rental property owners to manage residents, handle rental payments, track maintenance requests, and delegate management to agents.

**Built for the Kenyan market with M-Pesa integration.**

## Architecture

- **Frontend**: Flutter (Web & Mobile)
- **Backend**: Rust with Axum web framework
- **Database**: PostgreSQL
- **Authentication**: JWT tokens
- **Payments**: M-Pesa integration for mobile payments

## Project Structure

```
ZipProperty/
├── frontend/          # Flutter application (web & mobile)
├── backend/           # Rust API server
├── docs/              # Documentation
└── README.md
```

## Features

### For Property Owners
- Manage multiple properties
- Track rental payments
- Handle maintenance requests
- Delegate management to agents
- Generate reports and analytics
- Tenant management

### For Agents
- Manage assigned properties
- Process rental payments
- Handle maintenance requests
- Communicate with tenants
- Generate reports for owners

### For Tenants
- Submit rental payments (Cash, Bank Transfer, M-Pesa)
- Request maintenance
- View payment history
- Communicate with property manager
- Access lease documents

## Getting Started

### Prerequisites
- Flutter SDK (latest stable)
- Rust (latest stable)
- PostgreSQL

### Backend Setup
```bash
cd backend
cargo run
```

### Frontend Setup
```bash
cd frontend
flutter pub get
flutter run -d web  # For web
flutter run         # For mobile
```

## API Documentation

The API documentation will be available at `http://localhost:8080/api/docs` when the backend is running.



## License

This project is licensed under the MIT License.
