# ALS Tavern - Test Suite

This directory contains automated tests for the ALS Tavern game using the GUT (Godot Unit Test) framework.

## 📁 Directory Structure

```
tests/
├── unit/                      # Unit tests for individual components
│   ├── test_party_manager.gd # Tests for champion progression & party management
│   └── test_damage_calculations.gd # Tests for damage formulas and combat math
└── integration/               # Integration tests for full systems
    └── (coming soon)
```

## 🚀 Running Tests

### Method 1: Using Godot Editor (Recommended)

1. **Open the project in Godot Editor**
2. **Open the GUT panel:**
   - Click on "GUT" tab at the bottom of the editor (next to Output, Debugger, etc.)
   - If you don't see it, go to: **Project → Tools → Gut**
3. **Run all tests:**
   - Click the "Run All" button in the GUT panel
4. **Run specific test file:**
   - Select the test file from the dropdown
   - Click "Run" button

### Method 2: Using Command Line

```bash
# Run all tests
godot --path /home/user/als-tavern -s addons/gut/gut_cmdln.gd

# Run specific test directory
godot --path /home/user/als-tavern -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit

# Run with increased verbosity
godot --path /home/user/als-tavern -s addons/gut/gut_cmdln.gd -glog=2
```

### Method 3: Using GUT Scene

1. Open `res://addons/gut/GutScene.tscn`
2. Press F5 or click "Run Current Scene"
3. Tests will run automatically

## 📊 Current Test Coverage

| Component | Test File | Test Count | Coverage |
|-----------|-----------|------------|----------|
| PartyManager | `test_party_manager.gd` | 27 tests | ~95% |
| Champion (Damage) | `test_damage_calculations.gd` | 24 tests | ~90% |
| **TOTAL** | **2 files** | **51 tests** | **~45% project** |

## ✅ Test Categories

### PartyManager Tests (27 tests)
- ✅ Party composition validation (4 tests)
- ✅ Deck building constraints (4 tests)
- ✅ XP and leveling system (7 tests)
- ✅ HP management (6 tests)
- ✅ Card unlocking (2 tests)

### Damage Calculation Tests (24 tests)
- ✅ Basic damage mechanics (3 tests)
- ✅ Defense reduction formula (4 tests)
- ✅ Block absorption (4 tests)
- ✅ Healing mechanics (3 tests)
- ✅ Block management (3 tests)
- ✅ Edge cases and complex scenarios (7 tests)

## 📝 Writing New Tests

### Test File Template

```gdscript
extends GutTest
## Unit tests for [ComponentName] - [Description]

var component: Node


func before_each():
	"""Setup before each test"""
	component = ComponentClass.new()
	# Initialize component


func after_each():
	"""Cleanup after each test"""
	component.queue_free()
	component = null


func test_something_works():
	"""Test that something works as expected"""
	# Arrange
	var expected = 42

	# Act
	var result = component.do_something()

	# Assert
	assert_eq(result, expected, "Should return 42")
```

### Common Assertions

```gdscript
assert_eq(a, b, "message")           # Assert equal
assert_ne(a, b, "message")           # Assert not equal
assert_gt(a, b, "message")           # Assert greater than
assert_lt(a, b, "message")           # Assert less than
assert_true(value, "message")        # Assert true
assert_false(value, "message")       # Assert false
assert_null(value, "message")        # Assert null
assert_not_null(value, "message")    # Assert not null
assert_has(array, value, "message")  # Assert array contains value
```

### Best Practices

1. **One assertion per test** (when possible)
2. **Use descriptive test names** that explain what is being tested
3. **Follow AAA pattern**: Arrange → Act → Assert
4. **Clean up resources** in `after_each()`
5. **Test edge cases** (null, zero, negative, max values)
6. **Test error conditions** (invalid input, boundary cases)
7. **Keep tests independent** (don't rely on other tests)

## 🎯 Next Tests to Write

### High Priority
- [ ] **BattleManager** - Card drawing, shuffling, turn management
- [ ] **Card Effects** - All 14 effect types
- [ ] **MapGenerator** - Procedural generation, connectivity

### Medium Priority
- [ ] **SaveManager** - Serialization round-trip tests
- [ ] **Enemy AI** - Attack pattern selection
- [ ] **CardDatabase** - Data loading and queries

### Integration Tests
- [ ] Full battle flow (start → play cards → victory)
- [ ] Save/load complete game state
- [ ] Party progression through multiple battles

## 🐛 Debugging Failed Tests

### View Detailed Output
In GUT panel, increase "Log Level" to see more details:
- 0 = Errors only
- 1 = Normal (default)
- 2 = Verbose (shows all assertions)

### Common Issues

**Issue:** `assert_eq` shows wrong values
**Solution:** Check that you're testing the right property

**Issue:** Test passes but should fail
**Solution:** Verify your assertion logic - maybe use `assert_ne` instead

**Issue:** Tests interfere with each other
**Solution:** Ensure `before_each()` and `after_each()` properly reset state

**Issue:** Autoload dependencies cause errors
**Solution:** Tests run with full autoloads loaded. Use `reset_party()` or similar to clean state.

## 📚 Resources

- **GUT Documentation:** https://github.com/bitwes/Gut/wiki
- **GUT API Reference:** https://github.com/bitwes/Gut/wiki/Asserts-and-Methods
- **Godot Testing Guide:** https://docs.godotengine.org/en/stable/contributing/development/testing.html

## 🏆 Testing Goals

- **Week 4:** 40% coverage (core systems)
- **Week 8:** 70% coverage (all critical paths)
- **Week 12:** 85% coverage (edge cases and integration)

---

**Remember:** Tests are documentation that proves your code works! Write tests as you develop new features.
