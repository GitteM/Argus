# Argus: IoT Device Management iOS App

A modern, iOS application demonstrating real-time IoT device monitoring and control using Clean Architecture, MVVM pattern, and modular design with Swift Package Manager.

![Swift](https://img.shields.io/badge/Swift-6.1-orange.svg)
![iOS](https://img.shields.io/badge/iOS-17.0%2B-blue.svg)
![Architecture](https://img.shields.io/badge/Architecture-Clean%20+%20MVVM-green.svg)
![SPM](https://img.shields.io/badge/SPM-Modular-red.svg)
![License](https://img.shields.io/badge/License-MIT-yellow.svg)

## Overview

This project showcases a comprehensive IoT device management solution for iOS, featuring real-time device monitoring, control interfaces, and alert management. Built with enterprise-grade architecture patterns and best practices, it demonstrates proficiency in modern iOS development.

### Key Features

- **Real-time Dashboard** - Live device grid with MQTT-powered status updates
- **Device Control** - Custom SwiftUI components for intuitive device management
- **Alert System** - Real-time notifications with severity-based prioritization
- **Advanced Settings** - WebView integration for complex configuration
- **Demo Mode** - Fully functional offline mode with simulated data
- **Offline Support** - Seamless operation with data persistence and sync

### Technical Highlights

- **Clean Architecture** with clear separation of concerns
- **MVVM Pattern** for reactive UI with Combine
- **Modular Design** using Swift Package Manager
- **Real-time Communication** via MQTT and WebSocket
- **Comprehensive Testing** with unit, integration, and UI tests
- **Dependency Injection** using Factory pattern
- **Coordinator Pattern** for navigation
- **Async/Await** for modern concurrency

## Architecture

The application follows Clean Architecture principles with four distinct layers:

```
┌───────────────────────────────────────────────┐
│          Presentation Layer (MVVM)            │
│    SwiftUI Views • ViewModels • Coordinators  │
├───────────────────────────────────────────────┤
│           Domain Layer (Business Logic)       │
│    Use Cases • Entities • Repository Protocols│
├───────────────────────────────────────────────┤
│        Data Layer (Repository Impl)           │
│    Repositories • Network • Persistence • MQTT│
├───────────────────────────────────────────────┤
│     Infrastructure & Cross-Cutting            │
│    DI • Navigation • Logging • Analytics      │
└───────────────────────────────────────────────┘
```

### Package Structure

```
Argus/
├── Argus/                   # Main iOS application
├── Packages/
│   ├── Domain/               # Business logic (no dependencies)
│   ├── Data/                 # Repository implementations
│   ├── Presentation/         # UI modules (Dashboard, Settings, etc.)
│   └── Infrastructure/       # Core services and utilities
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
# Select your target device/simulator
# Press Cmd+R or click the Run button
```

## Features in Detail

### Dashboard Module
- Grid layout with real-time device status
- Live MQTT updates with visual indicators
- Search and filter capabilities
- Pull-to-refresh functionality
- Device status badges (online/offline/warning)

### Device Detail Module
- Custom control components (sliders, toggles, gauges)
- Real-time metrics visualization
- Command sending with confirmation
- Historical data charts
- Device information panel

### Settings Module
- Native settings interface
- WebView for advanced configuration
- JavaScript bridge for web integration
- Theme selection (light/dark/auto)
- Notification preferences

### Alerts Module
- Real-time alert streaming
- Severity-based categorization
- Alert acknowledgment system
- Push notification integration
- Alert history with filtering


## UI/UX Design

- **Design System**: Consistent color palette, typography, and spacing
- **Dark Mode**: Full support with semantic colors
- **Accessibility**: VoiceOver, Dynamic Type, and reduced motion support
- **Animations**: Smooth transitions and micro-interactions
- **Responsive**: Adaptive layouts for all iOS devices

## Build Configurations

- **Debug**: Development environment with verbose logging
- **Release**: Production build with optimizations

## Testing

### MQTT Test Environment

This iOS app can be tested against a local MQTT broker using our containerized test environment:

**Repository**: [mqtt-test-environment](https://github.com/GitteM/mqtt-test-environment)

**Quick Setup:**
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

iOS App Configuration:
- MQTT Broker: localhost:1883 (or your Mac's IP for device testing)
- Discovery Topic: homeassistant/+/+/config
- Test Devices: Living Room Light, Kitchen Temperature Sensor

For Device Testing:
Replace localhost with your Mac's IP address (found in System Preferences > Network) when testing on physical iOS devices.

See the https://github.com/GitteM/mqtt-test-environment/blob/main/README.md for complete documentation and troubleshooting.

## Performance

- **App Launch**: -
- **Memory Usage**: -
- **Frame Rate**: -
- **Network Efficiency**: -
- **Battery Impact**: -

## Documentation

- [Project Documentation](https://app.clickup.com/90151482241/v/dc/2kyq4ww1-695)

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
- [Factory](https://github.com/hmlongco/Factory) - Dependency injection
- [SwiftLint](https://github.com/realm/SwiftLint) - Code linting

## Purpose

This demonstration project was created to showcase:

- **Architecture Design**: Implementation of Clean Architecture with MVVM
- **Modern iOS Development**: SwiftUI, Combine, async/await
- **Real-time Systems**: MQTT and WebSocket integration
- **Modular Design**: Swift Package Manager organization
- **Testing Practices**: Comprehensive test coverage
- **Production Readiness**: Error handling, logging, and monitoring

**Note**: This is a demonstration project. Mock data and simulated services are used where actual IoT infrastructure would normally be required.
