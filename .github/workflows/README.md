# GitHub Actions CI/CD

This directory contains GitHub Actions workflows for the Argus project.

## Workflows

### 1. `ci.yml` - Main CI Pipeline
- **Triggers**: Push to `main` branch, Pull Requests to `main`
- **Purpose**: Comprehensive testing and validation
- **Features**:
  - Builds the project
  - Runs all unit tests (excluding UI tests)
  - Caches dependencies for faster builds
  - Uploads test results as artifacts

### 2. `pr-checks.yml` - Pull Request Checks
- **Triggers**: Pull Request events (opened, updated, etc.)
- **Purpose**: Automated PR validation with feedback
- **Features**:
  - Skips draft PRs
  - Provides formatted test output
  - Comments on PR with results
  - Cancels previous runs when new commits are pushed

## Requirements

- **Runner**: macOS (latest)
- **Xcode**: 16.0 (automatically selected)
- **iOS Simulator**: iPhone 16 with latest iOS

## Test Configuration

- **Unit Tests**: All test targets except `ArgusUITests`
- **Configuration**: Debug
- **Destination**: iOS Simulator

## Caching

Both workflows cache:
- Swift Package Manager dependencies
- Xcode DerivedData
- Package.resolved files

This significantly reduces build times for subsequent runs.

## Usage

1. **Automatic**: Workflows run automatically on PR creation/updates
2. **Manual**: Can be triggered manually from GitHub Actions tab
3. **Status**: Check status in PR checks or Actions tab

## Troubleshooting

- **Build failures**: Check Xcode version compatibility
- **Test failures**: Review test logs in workflow output
- **Cache issues**: Clear cache by updating workflow file
- **Simulator issues**: May need to adjust iOS version in workflow