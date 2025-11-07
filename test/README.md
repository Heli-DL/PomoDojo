# Testing Infrastructure

This directory contains the comprehensive testing suite for PomoDojo.

## Test Structure

```
test/
├── helpers/           # Test helper utilities
├── unit/              # Unit tests for business logic
├── widgets/           # Widget tests for UI components
└── integration_test/  # Integration tests for end-to-end flows
```

## Running Tests

### Run all tests
```bash
flutter test
```

### Run specific test file
```bash
flutter test test/unit/progression_model_test.dart
```

### Run tests with coverage
```bash
flutter test --coverage
```

### Run integration tests
```bash
flutter test integration_test/app_test.dart
```

## Test Categories

### Unit Tests (`test/unit/`)
- Pure business logic without Flutter dependencies
- Fast execution
- Examples:
  - `progression_model_test.dart` - Tests level/XP calculations
  - `martial_rank_test.dart` - Tests rank logic
  - `pomodoro_session_test.dart` - Tests session state management

### Widget Tests (`test/widgets/`)
- Tests individual Flutter widgets
- Uses `WidgetTester` to interact with widgets
- Examples:
  - `progression_header_test.dart` - Tests progression display
  - `circular_timer_test.dart` - Tests timer display

### Integration Tests (`integration_test/`)
- End-to-end tests for complete user flows
- Tests app as a whole
- May require test user setup or Firebase emulators

## Test Helpers

The `test/helpers/test_helpers.dart` file provides utilities:
- `createTestWidget()` - Wraps widget with ProviderScope
- `createThemedTestWidget()` - Wraps widget with theme




