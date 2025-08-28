# Argus: MQTT Integration Demo iOS App

A modern iOS application demonstrating MQTT integration with Clean Architecture and a modular design with Swift Package Manager.

![Swift](https://img.shields.io/badge/Swift-6.1-orange.svg)
![iOS](https://img.shields.io/badge/iOS-17.0%2B-blue.svg)
![Architecture](https://img.shields.io/badge/Architecture-Clean%20+%20MVVM-green.svg)
![SPM](https://img.shields.io/badge/SPM-Modular-red.svg)
![License](https://img.shields.io/badge/License-MIT-yellow.svg)

## Overview

A demonstration of basic MQTT integration for iOS featuring real-time device monitoring capabilities.

### Prerequisites

Before running the project on an iOS simulator, the MQTT test environment must be availble:

Check out the companion test server repository
Follow the setup instructions in that repository's README.md.
Ensure the Docker container and test server is running locally to provide test data to the iOS simulator

### Core Functionality

- **MQTT Connection Management** Connection and reconnection handling
- **Connection Status Indicator** Visual indicator that becomes tappable when disconnected to initiate reconnection
- **Device Discovery** Dashboard displaying list of available devices for subscription
- **Device Monitoring** Detail view showing basic device information and current state
- **Subscription Control** Ability to subscribe/unsubscribe from individual devices


### Technical Highlights

- **Clean Architecture** with clear separation of concerns
- **MV State Pattern** for reactive UI with Combine
- **Modular Design** using Swift Package Manager
- **Real-time Communication** via MQTT 
- **Dependency Injection** Composition Root with State/Store
- **Router Pattern** for navigation
- **Async/Await** for modern concurrency
- **Testing Practices** TestPlan includes DeviceStore

## Architecture

The application follows Clean Architecture principles:

```
┌───────────────────────────────────────────────┐
│           Presentation Layer                  │
│    SwiftUI Views • Stores • SharedUI          │
├───────────────────────────────────────────────┤
│           Domain Layer (Business Logic)       │
│    Use Cases • Entities • Repository Protocols│
├───────────────────────────────────────────────┤
│        Data Layer (Repository Impl)           │
│    Repositories • DataSource • Persistence    │
├───────────────────────────────────────────────┤
│     Infrastructure & Cross-Cutting            │
│         DI • Services • Utilites              │
├───────────────────────────────────────────────┤
│                  Navigation                   │
│         Router + Route+Extensions             │
└───────────────────────────────────────────────┘
```


**Notes**

The project employs a structured architecture that may be more complex than necessary for its current scope. This was intentionally designed as an experimentation platform for:

- Scalable application structure patterns
- Foundation for larger MQTT-based applications
- Testing architectural patterns in real-time data scenarios


### Package Structure

```
Argus/
├── Argus/                    # Main iOS application
├── Packages/
│   ├── Domain/               # Business logic (no dependencies)
│   ├── Data/                 # Repository implementations
│   ├── Presentation/         # UI modules 
│   ├── Infrastructure/       # Core services and utilities
│   └── Navigation/           # Routers and Route extensions
└── README.md
```

## Getting Started

### Prerequisites

- Xcode 16.0+
- iOS 17.0+ deployment target
- Swift 6.0+

### Installation

1. **Clone the repository**
```bash
git clone https://github.com/yourusername/iot-device-management-ios.git
cd iot-device-management-ios
```

2. **Open in Xcode**

Open Argus/Argus.xcworkspace

3. **Build and run**
```bash
# Select Argus Scheme and target simulator
# Press Cmd+R or click the Run button
```

## UI/UX Design

**Notes**

The current interface prioritizes functionality over polish. Potential improvements for future iterations:
- Enhanced visual design and user experience
- Improved connection status 

## Build Configurations

- **Debug** Development environment with verbose logging
- **Release** Production build with optimizations

## Testing

#### MQTT Test Environment

This iOS app can be tested against a local MQTT broker using a containerized test environment:

**Repository** [mqtt-test-environment](https://github.com/GitteM/mqtt-test-environment)

**Quick Setup**
```bash
# Clone the test environment
git clone git@github.com:GitteM/mqtt-test-environment.git
cd mqtt-test-environment
chmod +x setup.sh

# Start MQTT broker and simulators
./setup.sh start

# View live MQTT messages
./setup.sh logs
```

#### iOS App Configuration
- **MQTT Broker** localhost:1883 (or your Mac's IP for device testing)
- **Discovery Topic** homeassistant/+/+/config
- **Test Devices** Living Room Light, Kitchen Temperature Sensor

See the [README.md](https://github.com/GitteM/mqtt-test-environment/blob/main/README.md) for complete documentation and troubleshooting.

### Limitations & Future Enhancements
**Currently Not Implemented**
- Event history display
- Publishing capabilities to MQTT topics

### Known Issues
Subscription update delivery may stop when MQTT connection goes offline and recovers
Occasional missed updates during connection state transitions


## License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Author
**Brigitte Michau**

- Email: b.boardman@me.com
- LinkedIn: [linkedin.com/in/brigitte_michau](https://www.linkedin.com/in/brigitte-michau/)
- GitHub: [@GitteM](https://github.com/GitteM)

## Acknowledgments
This project uses the following open-source libraries:

- [CocoaMQTT](https://github.com/emqx/CocoaMQTT) - MQTT client
- [SwiftLint](https://github.com/realm/SwiftLint) - Code linting
- [SwiftFormat](https://github.com/nicklockwood/SwiftFormat) - Code formatting
