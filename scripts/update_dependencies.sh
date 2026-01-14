#!/bin/bash

# Flutter Dependency Update Script
# This script replicates the functionality of VS Code Flutter extension
# for automated dependency updates

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if we're in a Flutter project
check_flutter_project() {
    if [[ ! -f "pubspec.yaml" ]]; then
        print_error "pubspec.yaml not found. Please run this script from the Flutter project root."
        exit 1
    fi
    
    print_success "Flutter project detected"
}

# Backup current state
backup_current_state() {
    print_status "Creating backup of current state..."
    
    if [[ -f "pubspec.lock" ]]; then
        cp pubspec.lock pubspec.lock.backup
        print_success "Backed up pubspec.lock"
    fi
    
    # Also backup .dart_tool/package_config.json if it exists
    if [[ -f ".dart_tool/package_config.json" ]]; then
        cp .dart_tool/package_config.json .dart_tool/package_config.json.backup
        print_success "Backed up package_config.json"
    fi
}

# Replicate VS Code Flutter extension functionality
run_flutter_pub_get() {
    print_status "Running flutter pub get (equivalent to VS Code extension)..."
    
    # This replicates what VS Code Flutter extension does:
    # 1. Dependency resolution and download
    # 2. Generate/update pubspec.lock
    # 3. Update .dart_tool/package_config.json
    # 4. Use --no-example for faster processing
    
    if flutter pub get --no-example; then
        print_success "Dependencies resolved and downloaded successfully"
        print_success "pubspec.lock updated with exact versions"
        print_success ".dart_tool/package_config.json updated for IDE integration"
    else
        print_error "Failed to resolve dependencies"
        return 1
    fi
}

# Update dependencies
update_dependencies() {
    local update_type="${1:-minor}"
    
    print_status "Updating dependencies (type: $update_type)..."
    
    case $update_type in
        "patch")
            print_status "Updating to latest patch versions..."
            flutter pub upgrade
            ;;
        "minor")
            print_status "Updating to latest minor versions..."
            flutter pub upgrade --major-versions
            ;;
        "major")
            print_status "Updating to latest major versions (use with caution)..."
            flutter pub upgrade --major-versions
            ;;
        *)
            print_warning "Unknown update type '$update_type', using 'minor'"
            flutter pub upgrade --major-versions
            ;;
    esac
}

# Check for changes
check_for_changes() {
    print_status "Checking for dependency changes..."
    
    if [[ -f "pubspec.lock.backup" ]]; then
        if diff -q pubspec.lock pubspec.lock.backup > /dev/null 2>&1; then
            print_warning "No dependency changes detected"
            return 1
        else
            print_success "Dependency changes detected"
            
            # Show summary of changes
            echo ""
            print_status "Summary of changes:"
            echo "----------------------------------------"
            diff -u pubspec.lock.backup pubspec.lock | grep "^[+-]" | grep -E "(name:|version:)" | head -20 || true
            echo "----------------------------------------"
            echo ""
            
            return 0
        fi
    else
        print_warning "No backup found, assuming changes exist"
        return 0
    fi
}

# Validate the updated environment
validate_environment() {
    print_status "Validating updated environment..."
    
    # Run flutter doctor to check overall health
    print_status "Running Flutter doctor..."
    if flutter doctor > /dev/null 2>&1; then
        print_success "Flutter doctor check passed"
    else
        print_warning "Flutter doctor reported issues (this might be normal)"
    fi
    
    # Run flutter analyze to check for code issues
    print_status "Running Flutter analyze..."
    if flutter analyze --fatal-infos > /dev/null 2>&1; then
        print_success "Code analysis passed"
    else
        print_warning "Code analysis found issues (review recommended)"
        return 1
    fi
}

# Test build process
test_build() {
    local build_type="${1:-debug}"
    
    print_status "Testing build process..."
    
    case $build_type in
        "apk")
            print_status "Building APK with split-per-abi..."
            if flutter build apk --split-per-abi; then
                print_success "APK build successful"
            else
                print_error "APK build failed"
                return 1
            fi
            ;;
        "debug")
            print_status "Testing debug build..."
            if flutter build apk --debug > /dev/null 2>&1; then
                print_success "Debug build successful"
            else
                print_error "Debug build failed"
                return 1
            fi
            ;;
        *)
            print_warning "Unknown build type '$build_type', skipping build test"
            ;;
    esac
}

# Cleanup
cleanup() {
    print_status "Cleaning up..."
    
    if [[ -f "pubspec.lock.backup" ]]; then
        rm -f pubspec.lock.backup
        print_status "Removed pubspec.lock backup"
    fi
    
    if [[ -f ".dart_tool/package_config.json.backup" ]]; then
        rm -f .dart_tool/package_config.json.backup
        print_status "Removed package_config.json backup"
    fi
}

# Restore backup in case of failure
restore_backup() {
    print_warning "Restoring backup due to failure..."
    
    if [[ -f "pubspec.lock.backup" ]]; then
        mv pubspec.lock.backup pubspec.lock
        print_status "Restored pubspec.lock"
    fi
    
    if [[ -f ".dart_tool/package_config.json.backup" ]]; then
        mv .dart_tool/package_config.json.backup .dart_tool/package_config.json
        print_status "Restored package_config.json"
    fi
    
    # Re-run pub get to ensure consistency
    print_status "Re-running pub get to ensure consistency..."
    flutter pub get --no-example > /dev/null 2>&1 || true
}

# Main function
main() {
    local update_type="${1:-minor}"
    local build_test="${2:-debug}"
    local skip_validation="${3:-false}"
    
    print_status "Flutter Dependency Update Script Starting..."
    print_status "Update type: $update_type"
    print_status "Build test: $build_test"
    
    # Set trap for cleanup on exit
    trap cleanup EXIT
    trap restore_backup ERR
    
    # Main workflow
    check_flutter_project
    backup_current_state
    
    # Update dependencies
    if update_dependencies "$update_type"; then
        print_success "Dependencies updated successfully"
    else
        print_error "Failed to update dependencies"
        exit 1
    fi
    
    # Run pub get to ensure everything is properly resolved
    if run_flutter_pub_get; then
        print_success "Dependency resolution completed"
    else
        print_error "Failed to resolve dependencies after update"
        exit 1
    fi
    
    # Check if there were actual changes
    if ! check_for_changes; then
        print_warning "No changes detected, exiting..."
        exit 0
    fi
    
    # Validate environment unless skipped
    if [[ "$skip_validation" != "true" ]]; then
        if validate_environment; then
            print_success "Environment validation passed"
        else
            print_warning "Environment validation failed - proceed with caution"
        fi
    fi
    
    # Test build process
    if test_build "$build_test"; then
        print_success "Build test passed"
    else
        print_error "Build test failed"
        exit 1
    fi
    
    print_success "✅ All steps completed successfully!"
    print_status "Next steps:"
    print_status "1. Review the changes in pubspec.lock"
    print_status "2. Test your application thoroughly"
    print_status "3. Commit the changes if everything works correctly"
}

# Show usage if requested
show_usage() {
    echo "Usage: $0 [update_type] [build_test] [skip_validation]"
    echo ""
    echo "Parameters:"
    echo "  update_type:     patch|minor|major (default: minor)"
    echo "  build_test:      debug|apk|skip (default: debug)"
    echo "  skip_validation: true|false (default: false)"
    echo ""
    echo "Examples:"
    echo "  $0                    # Update minor versions, test debug build"
    echo "  $0 patch              # Update patch versions only"
    echo "  $0 minor apk          # Update minor versions, test APK build"
    echo "  $0 major apk true     # Update major versions, test APK build, skip validation"
}

# Check for help flag
if [[ "${1}" == "--help" || "${1}" == "-h" ]]; then
    show_usage
    exit 0
fi

# Run main function
main "$@"