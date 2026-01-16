#!/bin/bash

# TestFlight Release Readiness Script
# Runs all TestFlight-related tests and reports results
# Created on 1/16/26

set -e

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║   TestFlight Release Readiness Validation                     ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCHEME="Reczipes2"
DESTINATION="platform=iOS Simulator,name=iPhone 15"
DERIVED_DATA_PATH="./DerivedData"

# Test suites
TEST_SUITES=(
    "TestFlightReleaseTests"
    "TestFlightProductionReadinessTests"
    "TestFlightTesterExperienceTests"
    "TestFlightEmergencyScenarioTests"
)

# Track results
TOTAL_SUITES=0
PASSED_SUITES=0
FAILED_SUITES=0

echo "${BLUE}Cleaning build directory...${NC}"
rm -rf "$DERIVED_DATA_PATH"
echo ""

# Function to run a test suite
run_test_suite() {
    local suite_name=$1
    TOTAL_SUITES=$((TOTAL_SUITES + 1))
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "${BLUE}Running: ${suite_name}${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    if xcodebuild test \
        -scheme "$SCHEME" \
        -destination "$DESTINATION" \
        -only-testing:"Reczipes2Tests/$suite_name" \
        -derivedDataPath "$DERIVED_DATA_PATH" \
        -quiet 2>&1 | tee test_output.log; then
        
        echo "${GREEN}✅ PASSED: ${suite_name}${NC}"
        PASSED_SUITES=$((PASSED_SUITES + 1))
        return 0
    else
        echo "${RED}❌ FAILED: ${suite_name}${NC}"
        FAILED_SUITES=$((FAILED_SUITES + 1))
        
        # Show failure details
        echo ""
        echo "${YELLOW}Failure Details:${NC}"
        grep -A 5 "error:" test_output.log || true
        echo ""
        
        return 1
    fi
}

# Run all test suites
echo "${BLUE}Starting test execution...${NC}"
echo ""

for suite in "${TEST_SUITES[@]}"; do
    run_test_suite "$suite"
    echo ""
done

# Clean up
rm -f test_output.log

# Summary
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                      TEST SUMMARY                              ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "Total Test Suites:   $TOTAL_SUITES"
echo "${GREEN}Passed:             $PASSED_SUITES${NC}"
if [ $FAILED_SUITES -gt 0 ]; then
    echo "${RED}Failed:             $FAILED_SUITES${NC}"
else
    echo "Failed:             0"
fi
echo ""

# Calculate percentage
if [ $TOTAL_SUITES -gt 0 ]; then
    PERCENTAGE=$((PASSED_SUITES * 100 / TOTAL_SUITES))
    echo "Success Rate:       ${PERCENTAGE}%"
    echo ""
fi

# Readiness assessment
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ $FAILED_SUITES -eq 0 ]; then
    echo "${GREEN}🎉 ALL TESTS PASSED!${NC}"
    echo ""
    echo "TestFlight Readiness: ${GREEN}✅ READY${NC}"
    echo ""
    echo "Next Steps:"
    echo "  1. ✅ Archive your app"
    echo "  2. ✅ Upload to TestFlight"
    echo "  3. ✅ Configure build notes"
    echo "  4. ✅ Invite testers"
    echo ""
else
    echo "${RED}⚠️  SOME TESTS FAILED${NC}"
    echo ""
    echo "TestFlight Readiness: ${RED}❌ NOT READY${NC}"
    echo ""
    echo "Action Required:"
    echo "  1. Review failed tests above"
    echo "  2. Fix issues"
    echo "  3. Re-run this script"
    echo "  4. Do not upload to TestFlight until all tests pass"
    echo ""
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Additional checks
echo "${BLUE}Additional Pre-Flight Checks:${NC}"
echo ""

# Check 1: CloudKit Dashboard
echo -n "☁️  CloudKit Dashboard access: "
echo "${YELLOW}MANUAL CHECK REQUIRED${NC}"
echo "   → Visit: https://icloud.developer.apple.com/dashboard/"
echo "   → Verify: Container 'iCloud.com.headydiscy.reczipes' exists"
echo ""

# Check 2: Schema Deployment
echo -n "📋 Schema deployed to Production: "
echo "${YELLOW}MANUAL CHECK REQUIRED${NC}"
echo "   → CloudKit Dashboard → Schema → Production"
echo "   → Verify: SharedRecipe and SharedRecipeBook types exist"
echo ""

# Check 3: Build Configuration
echo -n "🔨 Build configuration: "
if grep -q "DEBUG" .build/debug 2>/dev/null; then
    echo "${RED}WARNING - Debug build detected${NC}"
    echo "   → For TestFlight, create Archive build"
else
    echo "${GREEN}OK${NC}"
fi
echo ""

# Check 4: Entitlements
echo -n "🔐 Entitlements file: "
if [ -f "Reczipes2/Reczipes2.entitlements" ]; then
    echo "${GREEN}Found${NC}"
    if grep -q "iCloud.com.headydiscy.reczipes" "Reczipes2/Reczipes2.entitlements" 2>/dev/null; then
        echo "   → Container identifier: ${GREEN}✅ Correct${NC}"
    else
        echo "   → Container identifier: ${YELLOW}⚠️  Verify manually${NC}"
    fi
else
    echo "${YELLOW}⚠️  File not found at expected location${NC}"
    echo "   → Verify entitlements in Xcode: Signing & Capabilities"
fi
echo ""

# Final recommendation
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                   FINAL RECOMMENDATION                         ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

if [ $FAILED_SUITES -eq 0 ]; then
    echo "Based on automated tests: ${GREEN}APPROVED for TestFlight${NC}"
    echo ""
    echo "Complete the manual checks above, then:"
    echo "  • Archive the app (Product → Archive in Xcode)"
    echo "  • Distribute to TestFlight"
    echo "  • Add release notes from TESTFLIGHT_RELEASE_CHECKLIST.md"
    echo ""
else
    echo "Based on automated tests: ${RED}NOT APPROVED for TestFlight${NC}"
    echo ""
    echo "Fix the issues identified above before proceeding."
    echo ""
fi

# Exit with appropriate code
if [ $FAILED_SUITES -eq 0 ]; then
    exit 0
else
    exit 1
fi
