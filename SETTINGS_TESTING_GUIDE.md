# Settings Tab - Testing Guide

## How to Test the Fixed Features

### 1. Testing Navigation Change
**Location**: Bottom navigation bar

**Steps**:
1. Launch the app
2. Look at the bottom navigation bar
3. Verify the last tab shows "Settings" with a settings icon (not "Profile")
4. Tap on Settings to navigate to the settings screen

**Expected Result**: ✓ Settings tab opens successfully

---

### 2. Testing Backup Feature
**Location**: Settings tab → Data Management section

**Steps**:
1. Navigate to Settings tab
2. Find "Data Management" card
3. Click "Backup Data" button
4. Verify the loading dialog appears
5. Verify the share dialog appears with backup file
6. Select sharing method or cancel

**Expected Results**:
- ✓ Loading dialog shows "Backing up..." with spinner
- ✓ Share sheet appears with backup file named like: `expense_tracker_backup_2025-01-29T12-34-56.db`
- ✓ Success message appears: "✓ Database backup created and shared!"

---

### 3. Testing Restore Feature (Main Fix)
**Location**: Settings tab → Data Management section

**Steps**:
1. Navigate to Settings tab
2. Click "Restore Data" button
3. Verify confirmation dialog appears with professional styling
4. Click "Yes, Restore"
5. Verify file picker opens
6. Select a valid backup .db file
7. Verify loading dialog appears
8. Wait for restore to complete
9. Verify success message

**Expected Results**:
- ✓ Dialog has dark theme (black background with white text)
- ✓ Dialog title says "Restore Database" (not "Warning!")
- ✓ Dialog message is professional (explains data will be replaced)
- ✓ File picker opens and allows selection of .db files only
- ✓ Loading dialog shows "Restoring database..." with helpful message
- ✓ Success message: "✓ Database restored successfully!\nPlease restart the app to apply changes."

**Error Cases**:
- Select empty file → Error: "✗ Backup file is empty"
- Select wrong file type → Error: "✗ Restored database does not contain transactions table"
- Cancel restore → Dialog closes, no changes

---

### 4. Testing Authentication Features
**Location**: Settings tab → Security Settings section

**Steps**:

#### 4.1 Test Biometric Authentication
1. Tap "Test Authentication" button
2. Verify authentication dialog appears
3. Use fingerprint (or face depending on device)
4. Verify success message: "✓ Authentication successful"
5. Verify "Last Authenticated" time updates

**Expected Results**:
- ✓ Biometric dialog appears with message "Please authenticate to access your expense tracker"
- ✓ On success: Green snackbar with checkmark
- ✓ On cancel: Orange snackbar saying "✗ Authentication failed or cancelled"
- ✓ "Last Authenticated" field shows updated time

#### 4.2 Test Toggle Biometric Lock
1. Toggle "Enable Biometric Lock" switch
2. Verify snackbar shows: "Biometric lock enabled/disabled"
3. Toggle back to restore

**Expected Results**:
- ✓ Switch toggles smoothly
- ✓ Appropriate confirmation message appears

#### 4.3 Test Retry Limit Slider
1. Adjust the retry limit slider
2. Verify the count updates in real-time (3-10 attempts)
3. Verify the database saves the setting

**Expected Results**:
- ✓ Slider moves smoothly
- ✓ Text updates showing current attempt count
- ✓ Setting persists after app restart

---

### 5. Testing Export Authentication
**Location**: Settings tab → Security Settings

**Steps**:
1. Enable "Require Auth for Export"
2. Click "Backup Data" button
3. Verify biometric authentication dialog appears
4. Complete authentication
5. Proceed with backup

**Expected Results**:
- ✓ Biometric dialog appears before backup
- ✓ Backup only proceeds after successful authentication
- ✓ Snackbar shows: "Export auth enabled"

---

### 6. Testing Restore Authentication
**Location**: Settings tab → Security Settings

**Steps**:
1. Enable "Require Auth for Restore"
2. Click "Restore Data" button
3. Verify biometric authentication dialog appears
4. Complete authentication
5. Proceed with restore

**Expected Results**:
- ✓ Biometric dialog appears before restore process
- ✓ File picker only opens after successful authentication
- ✓ Snackbar shows: "Restore auth enabled"

---

### 7. Testing Information Box
**Location**: Settings tab → Data Management section (bottom)

**Steps**:
1. Scroll to Data Management section
2. Look below the buttons
3. Verify blue information box appears
4. Read the text about backup storage

**Expected Result**: ✓ Box displays: "Backups are saved as .db files. Keep them safe in cloud storage or external drives."

---

### 8. Testing Database Info
**Location**: Settings tab → Database Information card

**Steps**:
1. Navigate to Settings tab
2. Scroll to "Database Information" section
3. Verify transaction count displays
4. Verify database size displays
5. Add a new transaction and refresh
6. Verify numbers update

**Expected Results**:
- ✓ Shows correct transaction count
- ✓ Shows database size in KB/MB
- ✓ Numbers update after changes

---

### 9. Testing Error Scenarios

#### 9.1 Device Without Biometrics
1. Test on device without fingerprint/face recognition
2. Tap "Test Authentication"
3. Verify app shows success (graceful degradation)

**Expected Result**: ✓ Message: "✓ Authentication successful" (allowed through)

#### 9.2 Corrupted Backup File
1. Create a text file with .db extension
2. Try to restore it
3. Verify error message appears

**Expected Result**: ✓ Error: "Restored database does not contain transactions table"

#### 9.3 Empty Backup File
1. Create an empty .db file
2. Try to restore it
3. Verify error message appears

**Expected Result**: ✓ Error: "Backup file is empty"

#### 9.4 Lock Out Scenario (Multiple Failed Attempts)
1. Attempt authentication multiple times
2. Fail intentionally each time
3. After threshold, verify lock out

**Expected Result**: ✓ Device handles lock out gracefully

---

### 10. Testing UI Consistency

**Check These Elements**:
1. ✓ All buttons use consistent colors (Teal: #4ECDC4, Red: #E74C3C, Purple: #7C4DFF)
2. ✓ All dialogs have dark theme (Background: #1A1B23)
3. ✓ All text is readable with good contrast
4. ✓ All icons are properly aligned and sized
5. ✓ All sections have proper spacing
6. ✓ Gradients match app design system

---

### 11. Testing After App Restart

**Steps**:
1. Restore a database
2. See success message saying "Please restart the app"
3. Completely close the app
4. Relaunch the app
5. Verify data from restored backup is loaded

**Expected Results**:
- ✓ Settings are persisted
- ✓ Transactions from backup are visible
- ✓ Database info shows restored transaction count

---

## Quick Checklist

- [ ] Navigation shows "Settings" (not "Profile")
- [ ] Backup dialog is styled with dark theme
- [ ] Restore dialog is clear and professional
- [ ] File picker works and shows only .db files
- [ ] Loading dialogs show helpful progress messages
- [ ] Success messages are visible and clear
- [ ] Error messages explain what went wrong
- [ ] Authentication works on supported devices
- [ ] Authentication gracefully degrades on unsupported devices
- [ ] Database info updates correctly
- [ ] Information box is visible in Data Management section
- [ ] All icons are correct and properly aligned
- [ ] All colors match the app design system
- [ ] No crashes or unexpected behaviors

---

## Device Testing Recommendations

### Minimum Testing Devices:
1. **Android with Fingerprint** - Test full biometric flow
2. **Android without Biometric** - Test graceful degradation
3. **iOS with Face ID** - Test alternative authentication
4. **Physical Device** - File picker works better on real devices

### Edge Cases to Test:
- Low storage space (when creating backups)
- Network conditions (for file sharing)
- Multiple rapid clicks on buttons
- Background/foreground transitions during restore
- Screen orientation changes during dialogs

