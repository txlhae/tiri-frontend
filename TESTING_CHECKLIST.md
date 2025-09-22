# 🧪 TIRI Authentication Flow - Testing Checklist

## 📋 Testing Progress Tracker
Use this checklist to systematically test all authentication scenarios. Check off each item as you complete it.

---

## 🔥 **PHASE 1: Foundation Testing (Test First)**

### **1.1 App Startup & Route Determination**

#### ✅ Cold App Start - No Stored Tokens
- [ ] **Test Steps:**
  1. Fresh install app OR clear app data
  2. Launch app
- [ ] **Expected Result:** App routes to login page
- [ ] **Status:**✅ Passed
- [ ] **Notes:** ___________________________________________

#### ✅ Warm App Start - Valid Stored Tokens
- [ ] **Test Steps:**
  1. Login successfully once
  2. Force close app completely
  3. Reopen app
- [ ] **Expected Result:** App routes to home page directly
- [ ] **Status:** ✅ Passed
- [ ] **Notes:** ___________________________________________

#### ✅ Expired Token Start - Invalid/Expired Tokens
- [ ] **Test Steps:**
  1. Login successfully
  2. Wait for token expiry OR manually corrupt tokens
  3. Restart app
- [ ] **Expected Result:** App clears tokens and routes to login
- [ ] **Status:** ✅ Passed
- [ ] **Notes:** ___________________________________________

### **1.2 Basic Registration Flow**

#### ✅ New User Registration with Valid Data
- [ ] **Test Steps:**
  1. Go to registration screen
  2. Enter: Valid name, email, phone, country, referral code, password
  3. Submit registration
- [ ] **Expected Result:** Route to email verification screen
- [ ] **Backend Response Expected:** `next_step: "verify_email"`
- [ ] **Status:** ❌ Not Started | ⏳ In Progress | ✅ Passed | ❌ Failed
- [ ] **Notes:** ___________________________________________

#### ✅ Registration with Invalid Referral Code
- [ ] **Test Steps:**
  1. Go to registration screen
  2. Enter invalid/non-existent referral code
  3. Submit registration
- [ ] **Expected Result:** Show error message, stay on registration
- [ ] **Backend Response Expected:** 400 error
- [ ] **Status:** ❌ Not Started | ⏳ In Progress | ✅ Passed | ❌ Failed
- [ ] **Notes:** ___________________________________________

### **1.3 Basic Login Flow**

#### ✅ Valid Login Credentials
- [ ] **Test Steps:**
  1. Go to login screen
  2. Enter correct email and password
  3. Submit login
- [ ] **Expected Result:** Route based on user's account status
- [ ] **Status:** ❌ Not Started | ⏳ In Progress | ✅ Passed | ❌ Failed
- [ ] **Notes:** ___________________________________________

#### ✅ Invalid Login Credentials
- [ ] **Test Steps:**
  1. Enter wrong email or password
  2. Submit login
- [ ] **Expected Result:** Show "Invalid credentials" error message
- [ ] **Status:** ❌ Not Started | ⏳ In Progress | ✅ Passed | ❌ Failed
- [ ] **Notes:** ___________________________________________

---

## 🔥 **PHASE 2: Core Authentication Flows**

### **2.1 Login with Different User States**

#### ✅ Unverified User Login
- [ ] **Test Data:** User with unverified email
- [ ] **Test Steps:**
  1. Login with unverified user credentials
- [ ] **Expected Result:** Route to email verification screen
- [ ] **Backend Response Expected:** `next_step: "verify_email"`
- [ ] **Status:** ❌ Not Started | ⏳ In Progress | ✅ Passed | ❌ Failed
- [ ] **Notes:** ___________________________________________

#### ✅ Verified but Pending Approval Login
- [ ] **Test Data:** User with verified email but pending referrer approval
- [ ] **Test Steps:**
  1. Login with pending approval user credentials
- [ ] **Expected Result:** Route to pending approval screen
- [ ] **Backend Response Expected:** `next_step: "waiting_for_approval"`
- [ ] **Status:** ❌ Not Started | ⏳ In Progress | ✅ Passed | ❌ Failed
- [ ] **Notes:** ___________________________________________

#### ✅ Rejected User Login
- [ ] **Test Data:** User rejected by referrer
- [ ] **Test Steps:**
  1. Login with rejected user credentials
- [ ] **Expected Result:** Route to rejection screen
- [ ] **Backend Response Expected:** `next_step: "approval_rejected"`
- [ ] **Status:** ❌ Not Started | ⏳ In Progress | ✅ Passed | ❌ Failed
- [ ] **Notes:** ___________________________________________

#### ✅ Fully Approved User Login
- [ ] **Test Data:** User that is verified and approved
- [ ] **Test Steps:**
  1. Login with fully approved user credentials
- [ ] **Expected Result:** Route to home screen
- [ ] **Backend Response Expected:** `next_step: "ready"`
- [ ] **Status:** ❌ Not Started | ⏳ In Progress | ✅ Passed | ❌ Failed
- [ ] **Notes:** ___________________________________________

### **2.2 Email Verification Process**

#### ✅ Email Verification Link (Mobile Deep Link)
- [ ] **Test Steps:**
  1. Register new user
  2. Receive verification email
  3. Click verification link from mobile device
- [ ] **Expected Result:** App opens, auto-verifies, routes based on approval status
- [ ] **Status:** ❌ Not Started | ⏳ In Progress | ✅ Passed | ❌ Failed
- [ ] **Notes:** ___________________________________________

#### ✅ Email Verification Link (Web Browser)
- [ ] **Test Steps:**
  1. Register new user
  2. Click verification link from desktop/web browser
- [ ] **Expected Result:** Web page shows success or redirects to app
- [ ] **Status:** ❌ Not Started | ⏳ In Progress | ✅ Passed | ❌ Failed
- [ ] **Notes:** ___________________________________________

#### ✅ Manual Token Entry
- [ ] **Test Steps:**
  1. Register new user
  2. Get verification token from email
  3. Enter token manually in app
- [ ] **Expected Result:** Verify email, route to appropriate next screen
- [ ] **Status:** ❌ Not Started | ⏳ In Progress | ✅ Passed | ❌ Failed
- [ ] **Notes:** ___________________________________________

#### ✅ Invalid/Expired Verification Token
- [ ] **Test Steps:**
  1. Try to verify with old or invalid token
- [ ] **Expected Result:** Show error message, stay on verification screen
- [ ] **Status:** ❌ Not Started | ⏳ In Progress | ✅ Passed | ❌ Failed
- [ ] **Notes:** ___________________________________________

### **2.3 Post-Verification Routing**

#### ✅ Email Verified → Still Needs Approval
- [ ] **Test Steps:**
  1. Verify email for user who used referral code
- [ ] **Expected Result:** Auto-route to pending approval screen
- [ ] **Message Expected:** "Email verified! Waiting for approval..."
- [ ] **Status:** ❌ Not Started | ⏳ In Progress | ✅ Passed | ❌ Failed
- [ ] **Notes:** ___________________________________________

#### ✅ Email Verified → Already Pre-Approved
- [ ] **Test Steps:**
  1. Verify email for user who is already approved
- [ ] **Expected Result:** Auto-route to home screen
- [ ] **Message Expected:** "Welcome to TIRI!"
- [ ] **Status:** ❌ Not Started | ⏳ In Progress | ✅ Passed | ❌ Failed
- [ ] **Notes:** ___________________________________________

---

## 🔥 **PHASE 3: Approval System Testing**

### **3.1 Referrer Approval Actions**

#### ✅ View Pending Approvals List
- [ ] **Test Steps:**
  1. Login as referrer user (approved user who can approve others)
  2. Navigate to approvals section
- [ ] **Expected Result:** See list of users waiting for approval
- [ ] **Status:** ❌ Not Started | ⏳ In Progress | ✅ Passed | ❌ Failed
- [ ] **Notes:** ___________________________________________

#### ✅ Approve User Registration
- [ ] **Test Steps:**
  1. As referrer, approve a pending user
  2. Check that user receives notification
- [ ] **Expected Result:** User gets approval and can access app
- [ ] **Status:** ❌ Not Started | ⏳ In Progress | ✅ Passed | ❌ Failed
- [ ] **Notes:** ___________________________________________

#### ✅ Reject User Registration
- [ ] **Test Steps:**
  1. As referrer, reject a pending user with reason
  2. Check that user receives notification
- [ ] **Expected Result:** User is notified of rejection with reason
- [ ] **Status:** ❌ Not Started | ⏳ In Progress | ✅ Passed | ❌ Failed
- [ ] **Notes:** ___________________________________________

### **3.2 Real-time Approval Status Changes**

#### ✅ User Gets Approved While Waiting
- [ ] **Test Steps:**
  1. Have user on pending approval screen
  2. Have referrer approve the user
  3. Wait for real-time update (30 seconds max)
- [ ] **Expected Result:** Auto-redirect to home with success message
- [ ] **Status:** ❌ Not Started | ⏳ In Progress | ✅ Passed | ❌ Failed
- [ ] **Notes:** ___________________________________________

#### ✅ User Gets Rejected While Waiting
- [ ] **Test Steps:**
  1. Have user on pending approval screen
  2. Have referrer reject the user
  3. Wait for real-time update (30 seconds max)
- [ ] **Expected Result:** Auto-redirect to rejection screen
- [ ] **Status:** ❌ Not Started | ⏳ In Progress | ✅ Passed | ❌ Failed
- [ ] **Notes:** ___________________________________________

#### ✅ Approval Request Expires (7 days)
- [ ] **Test Steps:**
  1. Simulate or wait for approval period expiry
  2. Try to login with expired user
- [ ] **Expected Result:** Clear session, route to login with expiry message
- [ ] **Status:** ❌ Not Started | ⏳ In Progress | ✅ Passed | ❌ Failed
- [ ] **Notes:** ___________________________________________

---

## 🔥 **PHASE 4: Error Handling & Edge Cases**

### **4.1 Network & Server Errors**

#### ✅ Network Timeout During Login
- [ ] **Test Steps:**
  1. Start login process
  2. Disconnect internet during request
- [ ] **Expected Result:** Show network error message
- [ ] **Status:** ❌ Not Started | ⏳ In Progress | ✅ Passed | ❌ Failed
- [ ] **Notes:** ___________________________________________

#### ✅ Server Error (500)
- [ ] **Test Steps:**
  1. Trigger server error from backend
  2. Attempt login/registration
- [ ] **Expected Result:** Show user-friendly server error message
- [ ] **Status:** ❌ Not Started | ⏳ In Progress | ✅ Passed | ❌ Failed
- [ ] **Notes:** ___________________________________________

#### ✅ API Endpoint Not Found (404)
- [ ] **Test Steps:**
  1. Temporarily break an API endpoint
  2. Trigger that API call
- [ ] **Expected Result:** Show appropriate error message
- [ ] **Status:** ❌ Not Started | ⏳ In Progress | ✅ Passed | ❌ Failed
- [ ] **Notes:** ___________________________________________

### **4.2 Token Management**

#### ✅ Token Refresh Success
- [ ] **Test Steps:**
  1. Use expired access token with valid refresh token
  2. Make API call that requires authentication
- [ ] **Expected Result:** Auto-refresh token and continue operation
- [ ] **Status:** ❌ Not Started | ⏳ In Progress | ✅ Passed | ❌ Failed
- [ ] **Notes:** ___________________________________________

#### ✅ Token Refresh Failure - Both Tokens Expired
- [ ] **Test Steps:**
  1. Expire both access and refresh tokens
  2. Try to make authenticated API call
- [ ] **Expected Result:** Clear session and route to login
- [ ] **Status:** ❌ Not Started | ⏳ In Progress | ✅ Passed | ❌ Failed
- [ ] **Notes:** ___________________________________________

#### ✅ Corrupted Token Data
- [ ] **Test Steps:**
  1. Manually corrupt stored token data
  2. Restart app
- [ ] **Expected Result:** Clear session and route to login
- [ ] **Status:** ❌ Not Started | ⏳ In Progress | ✅ Passed | ❌ Failed
- [ ] **Notes:** ___________________________________________

### **4.3 Account Status Edge Cases**

#### ✅ Account Deleted (Expired Registration)
- [ ] **Test Steps:**
  1. Use account that backend deleted due to expiry
  2. Try to login
- [ ] **Expected Result:** Show "Account expired" dialog, route to register
- [ ] **Status:** ❌ Not Started | ⏳ In Progress | ✅ Passed | ❌ Failed
- [ ] **Notes:** ___________________________________________

#### ✅ Suspended Account
- [ ] **Test Steps:**
  1. Login with suspended account
- [ ] **Expected Result:** Show suspension message
- [ ] **Status:** ❌ Not Started | ⏳ In Progress | ✅ Passed | ❌ Failed
- [ ] **Notes:** ___________________________________________

#### ✅ Unknown Account Status Response
- [ ] **Test Steps:**
  1. Backend returns unexpected/unknown status
- [ ] **Expected Result:** Graceful fallback to appropriate screen
- [ ] **Status:** ❌ Not Started | ⏳ In Progress | ✅ Passed | ❌ Failed
- [ ] **Notes:** ___________________________________________

---

## 🔥 **PHASE 5: Background & Persistence Testing**

### **5.1 Status Monitoring**

#### ✅ Periodic Status Checks (30 seconds)
- [ ] **Test Steps:**
  1. Stay on pending approval screen for 2+ minutes
  2. Monitor logs for periodic API calls
- [ ] **Expected Result:** Should see status check calls every 30 seconds
- [ ] **Status:** ❌ Not Started | ⏳ In Progress | ✅ Passed | ❌ Failed
- [ ] **Notes:** ___________________________________________

#### ✅ Status Change Detection While App Open
- [ ] **Test Steps:**
  1. Keep app open on pending screen
  2. Change user status from backend
  3. Wait for detection (30 seconds max)
- [ ] **Expected Result:** Auto-redirect when status changes
- [ ] **Status:** ❌ Not Started | ⏳ In Progress | ✅ Passed | ❌ Failed
- [ ] **Notes:** ___________________________________________

#### ✅ App Background/Foreground Handling
- [ ] **Test Steps:**
  1. Login and navigate to any screen
  2. Send app to background for 1+ minutes
  3. Bring app back to foreground
- [ ] **Expected Result:** Maintain auth state, check for updates
- [ ] **Status:** ❌ Not Started | ⏳ In Progress | ✅ Passed | ❌ Failed
- [ ] **Notes:** ___________________________________________

### **5.2 Data Persistence**

#### ✅ App Force Close & Restart
- [ ] **Test Steps:**
  1. Login and navigate to specific screen
  2. Force close app completely
  3. Restart app
- [ ] **Expected Result:** Resume from correct screen based on stored state
- [ ] **Status:** ❌ Not Started | ⏳ In Progress | ✅ Passed | ❌ Failed
- [ ] **Notes:** ___________________________________________

#### ✅ Device Restart Persistence
- [ ] **Test Steps:**
  1. Login to app
  2. Restart entire device
  3. Open app after restart
- [ ] **Expected Result:** Auth state should persist, route correctly
- [ ] **Status:** ❌ Not Started | ⏳ In Progress | ✅ Passed | ❌ Failed
- [ ] **Notes:** ___________________________________________

---

## 🔥 **PHASE 6: Password & Account Management**

### **6.1 Password Reset Flow**

#### ✅ Request Password Reset
- [ ] **Test Steps:**
  1. Use "Forgot Password" feature
  2. Enter valid email address
- [ ] **Expected Result:** Receive password reset email
- [ ] **Status:** ❌ Not Started | ⏳ In Progress | ✅ Passed | ❌ Failed
- [ ] **Notes:** ___________________________________________

#### ✅ Complete Password Reset
- [ ] **Test Steps:**
  1. Click reset link from email
  2. Enter new password
  3. Login with new password
- [ ] **Expected Result:** Should be able to login with new password
- [ ] **Status:** ❌ Not Started | ⏳ In Progress | ✅ Passed | ❌ Failed
- [ ] **Notes:** ___________________________________________

#### ✅ Invalid Reset Token
- [ ] **Test Steps:**
  1. Use expired or invalid password reset token
- [ ] **Expected Result:** Show appropriate error message
- [ ] **Status:** ❌ Not Started | ⏳ In Progress | ✅ Passed | ❌ Failed
- [ ] **Notes:** ___________________________________________

### **6.2 Logout Scenarios**

#### ✅ Normal Logout
- [ ] **Test Steps:**
  1. Login successfully
  2. Use logout button/feature
- [ ] **Expected Result:** Clear all data, route to login screen
- [ ] **Status:** ❌ Not Started | ⏳ In Progress | ✅ Passed | ❌ Failed
- [ ] **Notes:** ___________________________________________

#### ✅ Logout with Network Error
- [ ] **Test Steps:**
  1. Login successfully
  2. Disconnect internet
  3. Try to logout
- [ ] **Expected Result:** Still clear local data and route to login
- [ ] **Status:** ❌ Not Started | ⏳ In Progress | ✅ Passed | ❌ Failed
- [ ] **Notes:** ___________________________________________

---

## 📋 **Testing Summary**

### **Overall Progress**
- **Phase 1 (Foundation):** ___/8 tests completed
- **Phase 2 (Core Flows):** ___/9 tests completed
- **Phase 3 (Approval System):** ___/6 tests completed
- **Phase 4 (Error Handling):** ___/9 tests completed
- **Phase 5 (Background/Persistence):** ___/5 tests completed
- **Phase 6 (Password/Account):** ___/5 tests completed

**Total Progress:** ___/42 tests completed

### **Critical Issues Found**
1. ________________________________________________
2. ________________________________________________
3. ________________________________________________

### **Notes & Observations**
_____________________________________________________
_____________________________________________________
_____________________________________________________

---

## 🚀 **Quick Testing Commands**

```bash
# Clear app data for fresh testing
flutter clean && flutter pub get

# Run in debug mode for detailed logs
flutter run --debug

# View real-time logs (look for these prefixes):
# 🚀 AppStartupHandler
# 🛤️ AuthRedirectHandler
# 📊 AuthController
# ✅ AuthStorage
```

## 🔧 **Test Data Setup Required**

### **Backend Test Users Needed:**
1. **Referrer:** `referrer@test.com` (approved, can approve others)
2. **Unverified:** `unverified@test.com` (registered, email not verified)
3. **Pending:** `pending@test.com` (verified, waiting approval)
4. **Rejected:** `rejected@test.com` (rejected by referrer)
5. **Expired:** `expired@test.com` (approval period expired)
6. **Approved:** `approved@test.com` (fully approved and active)

### **Required Backend Responses:**
Ensure your backend returns proper `next_step` values:
- `"verify_email"` for unverified users
- `"waiting_for_approval"` for pending users
- `"approval_rejected"` for rejected users
- `"ready"` for fully approved users

---

**Happy Testing! 🎉**