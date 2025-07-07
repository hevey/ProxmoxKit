# Documentation

ProxmoxKit includes comprehensive DocC documentation.

## Building Documentation

To build the documentation locally:

```bash
# Using Xcode
xcodebuild docbuild -scheme ProxmoxKit -destination 'generic/platform=macOS'

# Using Swift Package Manager with Xcode
swift package generate-documentation --target ProxmoxKit
```

## Viewing Documentation

The documentation is generated as a `.doccarchive` file that can be opened with:

```bash
open .build/Build/Products/Debug/ProxmoxKit.doccarchive
```

## Documentation Structure

- **Getting Started**: Authentication and configuration guides
- **Services**: Node, VM, Container, and Cluster management
- **Models**: Data structures for Proxmox resources
- **Error Handling**: Comprehensive error types

## Features

- Comprehensive API documentation
- Code examples and usage guides
- Type-safe Swift interfaces
- Modern async/await patterns
- Detailed parameter descriptions
