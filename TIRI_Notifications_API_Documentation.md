# TIRI Notifications API Documentation

## Base URL
```
http://localhost:8000/api/notifications/
```

## Authentication
All endpoints require JWT Bearer token authentication:
```
Authorization: Bearer <access_token>
```

---

## Table of Contents
1. [List Notifications](#1-list-notifications)
2. [Get Notification Details](#2-get-notification-details)
3. [Mark Notification as Read](#3-mark-notification-as-read)
4. [Mark Notification as Unread](#4-mark-notification-as-unread)
5. [Delete Individual Notification](#5-delete-individual-notification)
6. [Get Unread Count](#6-get-unread-count)
7. [Get Notification Statistics](#7-get-notification-statistics)
8. [Bulk Actions](#8-bulk-actions)
9. [Notification Preferences](#9-notification-preferences)
10. [Device Token Management](#10-device-token-management)
11. [Error Codes Reference](#11-error-codes-reference)
12. [Notification Types Reference](#12-notification-types-reference)

---

## 1. List Notifications

### Endpoint
```
GET /api/notifications/notifications/
```

### Description
Retrieve paginated list of user's notifications with filtering options.

### Query Parameters
| Parameter | Type | Required | Description | Example |
|-----------|------|----------|-------------|---------|
| `page` | integer | No | Page number (default: 1) | `?page=2` |
| `page_size` | integer | No | Items per page (max: 100, default: 20) | `?page_size=50` |
| `is_read` | boolean | No | Filter by read status | `?is_read=false` |
| `type` | string | No | Filter by notification type | `?type=request_accepted` |
| `priority` | string | No | Filter by priority | `?priority=urgent` |
| `delivery_method` | string | No | Filter by delivery method | `?delivery_method=push` |
| `date_from` | date | No | Filter from date (YYYY-MM-DD) | `?date_from=2025-01-01` |
| `date_to` | date | No | Filter to date (YYYY-MM-DD) | `?date_to=2025-01-31` |
| `search` | string | No | Search in title and message | `?search=request+accepted` |

### Request Examples
```bash
# Get all notifications
curl -H "Authorization: Bearer <token>" \
  "http://localhost:8000/api/notifications/notifications/"

# Get unread notifications only
curl -H "Authorization: Bearer <token>" \
  "http://localhost:8000/api/notifications/notifications/?is_read=false"

# Get urgent notifications
curl -H "Authorization: Bearer <token>" \
  "http://localhost:8000/api/notifications/notifications/?priority=urgent"

# Get notifications with pagination
curl -H "Authorization: Bearer <token>" \
  "http://localhost:8000/api/notifications/notifications/?page=2&page_size=50"

# Search notifications
curl -H "Authorization: Bearer <token>" \
  "http://localhost:8000/api/notifications/notifications/?search=request+accepted"

# Filter by date range
curl -H "Authorization: Bearer <token>" \
  "http://localhost:8000/api/notifications/notifications/?date_from=2025-01-01&date_to=2025-01-31"
```

### Success Response (200 OK)
```json
{
  "count": 58,
  "next": "http://localhost:8000/api/notifications/notifications/?page=2",
  "previous": null,
  "results": [
    {
      "id": "7cdaca1b-3fab-49cd-a59f-c3a7c2a2084c",
      "recipient": "a05a3a4a-9750-4057-afe6-e6b289c42014",
      "recipient_name": "photofishai@gmail.com",
      "notification_type": "request_accepted",
      "notification_type_display": "Request Accepted",
      "title": "Your request was accepted",
      "message": "John Doe accepted your request for 'Help moving furniture'",
      "delivery_method": "push",
      "delivery_method_display": "Push Notification",
      "priority": "normal",
      "priority_display": "Normal Priority",
      "is_read": false,
      "read_at": null,
      "is_expired": false,
      "is_scheduled": false,
      "scheduled_for": null,
      "expires_at": null,
      "created_at": "2025-09-22T10:07:38.733977Z",
      "created_by": "b1fc3d10-8244-4607-8194-d7908e1d71e9",
      "created_by_name": "John Doe",
      "time_since_created": "2 hours ago"
    }
  ]
}
```

### Error Responses
```json
// 401 Unauthorized
{
  "detail": "Authentication credentials were not provided."
}

// 401 Invalid Token
{
  "detail": "Given token not valid for any token type",
  "code": "token_not_valid",
  "messages": [
    {
      "token_class": "AccessToken",
      "token_type": "access",
      "message": "Token is invalid or expired"
    }
  ]
}

// 400 Bad Request (invalid parameters)
{
  "detail": "Invalid query parameters",
  "errors": {
    "page_size": ["Ensure this value is less than or equal to 100."],
    "priority": ["Select a valid choice. invalid is not one of the available choices."]
  }
}
```

---

## 2. Get Notification Details

### Endpoint
```
GET /api/notifications/notifications/{id}/
```

### Description
Retrieve detailed information about a specific notification.

### Path Parameters
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `id` | UUID | Yes | Notification ID |

### Request Example
```bash
curl -H "Authorization: Bearer <token>" \
  "http://localhost:8000/api/notifications/notifications/7cdaca1b-3fab-49cd-a59f-c3a7c2a2084c/"
```

### Success Response (200 OK)
```json
{
  "id": "7cdaca1b-3fab-49cd-a59f-c3a7c2a2084c",
  "recipient": "a05a3a4a-9750-4057-afe6-e6b289c42014",
  "recipient_name": "photofishai@gmail.com",
  "notification_type": "request_accepted",
  "notification_type_display": "Request Accepted",
  "title": "Your request was accepted",
  "message": "John Doe accepted your request for 'Help moving furniture'",
  "delivery_method": "push",
  "delivery_method_display": "Push Notification",
  "priority": "normal",
  "priority_display": "Normal Priority",
  "is_read": false,
  "read_at": null,
  "is_expired": false,
  "is_scheduled": false,
  "scheduled_for": null,
  "expires_at": null,
  "created_at": "2025-09-22T10:07:38.733977Z",
  "updated_at": "2025-09-22T10:07:38.733977Z",
  "created_by": "b1fc3d10-8244-4607-8194-d7908e1d71e9",
  "created_by_name": "John Doe",
  "time_since_created": "2 hours ago",
  "extra_data": {
    "request_id": "req_123",
    "volunteer_name": "John Doe"
  }
}
```

### Error Responses
```json
// 404 Not Found
{
  "detail": "No Notification matches the given query."
}

// 401 Unauthorized
{
  "detail": "Authentication credentials were not provided."
}
```

---

## 3. Mark Notification as Read

### Endpoint
```
POST /api/notifications/notifications/{id}/mark_as_read/
```

### Description
Mark a specific notification as read.

### Path Parameters
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `id` | UUID | Yes | Notification ID |

### Request Example
```bash
curl -X POST \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  "http://localhost:8000/api/notifications/notifications/7cdaca1b-3fab-49cd-a59f-c3a7c2a2084c/mark_as_read/"
```

### Success Response (200 OK)
```json
{
  "message": "Notification marked as read",
  "notification_id": "7cdaca1b-3fab-49cd-a59f-c3a7c2a2084c",
  "read_at": "2025-09-22T12:30:45.123456Z"
}
```

### Error Responses
```json
// 404 Not Found
{
  "detail": "No Notification matches the given query."
}

// 400 Bad Request (already read)
{
  "detail": "Notification is already marked as read"
}
```

---

## 4. Mark Notification as Unread

### Endpoint
```
POST /api/notifications/notifications/{id}/mark_as_unread/
```

### Description
Mark a specific notification as unread.

### Request Example
```bash
curl -X POST \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  "http://localhost:8000/api/notifications/notifications/7cdaca1b-3fab-49cd-a59f-c3a7c2a2084c/mark_as_unread/"
```

### Success Response (200 OK)
```json
{
  "message": "Notification marked as unread",
  "notification_id": "7cdaca1b-3fab-49cd-a59f-c3a7c2a2084c"
}
```

### Error Responses
```json
// 400 Bad Request (already unread)
{
  "detail": "Notification is already unread"
}
```

---

## 5. Delete Individual Notification

### Endpoint
```
DELETE /api/notifications/notifications/{id}/
```

### Description
Permanently delete a specific notification. This action cannot be undone.

### Path Parameters
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `id` | UUID | Yes | Notification ID |

### Request Example
```bash
curl -X DELETE \
  -H "Authorization: Bearer <token>" \
  "http://localhost:8000/api/notifications/notifications/7cdaca1b-3fab-49cd-a59f-c3a7c2a2084c/"
```

### Success Response (204 No Content)
```
No response body - notification deleted successfully
```

### Error Responses
```json
// 404 Not Found
{
  "detail": "No Notification matches the given query."
}

// 401 Unauthorized
{
  "detail": "Authentication credentials were not provided."
}
```

---

## 6. Get Unread Count

### Endpoint
```
GET /api/notifications/notifications/unread_count/
```

### Description
Get the count of unread notifications with breakdown by type and priority.

### Request Example
```bash
curl -H "Authorization: Bearer <token>" \
  "http://localhost:8000/api/notifications/notifications/unread_count/"
```

### Success Response (200 OK)
```json
{
  "unread_count": 58,
  "unread_by_type": {
    "approval_request": 28,
    "test": 6,
    "approval_completed": 1,
    "chat_room_created": 6,
    "new_nearby_request": 2,
    "feedback_requested": 2,
    "email_verification": 1,
    "new_message": 9,
    "account_verified": 1,
    "referral_approved": 1,
    "welcome_email": 1
  },
  "unread_by_priority": {
    "normal": 28,
    "high": 30,
    "urgent": 0,
    "low": 0
  },
  "has_urgent": false
}
```

### Error Responses
```json
// 401 Unauthorized
{
  "detail": "Authentication credentials were not provided."
}
```

---

## 7. Get Notification Statistics

### Endpoint
```
GET /api/notifications/notifications/stats/
```

### Description
Get comprehensive statistics about user's notifications.

### Request Example
```bash
curl -H "Authorization: Bearer <token>" \
  "http://localhost:8000/api/notifications/notifications/stats/"
```

### Success Response (200 OK)
```json
{
  "total_notifications": 58,
  "unread_count": 58,
  "read_count": 0,
  "by_type": {
    "approval_request": 28,
    "test": 6,
    "chat_room_created": 6,
    "new_message": 9,
    "new_nearby_request": 2,
    "feedback_requested": 2,
    "approval_completed": 1,
    "email_verification": 1,
    "account_verified": 1,
    "referral_approved": 1,
    "welcome_email": 1
  },
  "by_priority": {
    "normal": 28,
    "high": 30,
    "urgent": 0,
    "low": 0
  },
  "by_delivery_method": {
    "push": 50,
    "email": 5,
    "both": 3
  },
  "recent_activity": {
    "last_24_hours": 15,
    "last_7_days": 45,
    "last_30_days": 58
  }
}
```

---

## 8. Bulk Actions

### Endpoint
```
POST /api/notifications/notifications/bulk_actions/
```

### Description
Perform bulk operations on notifications.

### Request Body
```json
{
  "action": "mark_all_read|delete_read|delete_expired",
  "notification_ids": ["uuid1", "uuid2"] // optional - if not provided, applies to all qualifying notifications
}
```

### Available Actions

#### 8.1 Mark All as Read
```bash
curl -X POST \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"action": "mark_all_read"}' \
  "http://localhost:8000/api/notifications/notifications/bulk_actions/"
```

**Success Response (200 OK):**
```json
{
  "message": "25 notifications marked as read",
  "affected_count": 25
}
```

#### 8.2 Delete All Read Notifications
```bash
curl -X POST \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"action": "delete_read"}' \
  "http://localhost:8000/api/notifications/notifications/bulk_actions/"
```

**Success Response (200 OK):**
```json
{
  "message": "15 read notifications deleted",
  "affected_count": 15
}
```

#### 8.3 Delete Expired Notifications
```bash
curl -X POST \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"action": "delete_expired"}' \
  "http://localhost:8000/api/notifications/notifications/bulk_actions/"
```

**Success Response (200 OK):**
```json
{
  "message": "3 expired notifications deleted",
  "affected_count": 3
}
```

#### 8.4 Bulk Action on Specific Notifications
```bash
curl -X POST \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "action": "delete_read",
    "notification_ids": [
      "7cdaca1b-3fab-49cd-a59f-c3a7c2a2084c",
      "b88934b6-c0e8-4d5c-b47d-f3373dfb73df"
    ]
  }' \
  "http://localhost:8000/api/notifications/notifications/bulk_actions/"
```

### Error Responses
```json
// 400 Bad Request (invalid action)
{
  "error": "Invalid action"
}

// 400 Bad Request (missing action)
{
  "action": ["This field is required."]
}

// 400 Bad Request (invalid notification IDs)
{
  "detail": "Invalid notification IDs provided",
  "invalid_ids": ["invalid-uuid-1", "invalid-uuid-2"]
}
```

---

## 9. Notification Preferences

### 9.1 Get User Preferences

#### Endpoint
```
GET /api/notifications/preferences/
```

#### Request Example
```bash
curl -H "Authorization: Bearer <token>" \
  "http://localhost:8000/api/notifications/preferences/"
```

#### Success Response (200 OK)
```json
{
  "id": "pref_123",
  "user": "a05a3a4a-9750-4057-afe6-e6b289c42014",
  "push_notifications_enabled": true,
  "email_notifications_enabled": true,
  "in_app_notifications_enabled": true,
  "quiet_hours_enabled": false,
  "quiet_hours_start": null,
  "quiet_hours_end": null,
  "email_digest_frequency": "immediate",
  "created_at": "2025-08-30T06:11:01.162814Z",
  "updated_at": "2025-09-22T10:07:38.733977Z"
}
```

### 9.2 Update User Preferences

#### Endpoint
```
PUT /api/notifications/preferences/
PATCH /api/notifications/preferences/
```

#### Request Example
```bash
curl -X PATCH \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "push_notifications_enabled": true,
    "email_notifications_enabled": false,
    "quiet_hours_enabled": true,
    "quiet_hours_start": "22:00:00",
    "quiet_hours_end": "08:00:00",
    "email_digest_frequency": "daily"
  }' \
  "http://localhost:8000/api/notifications/preferences/"
```

#### Success Response (200 OK)
```json
{
  "id": "pref_123",
  "user": "a05a3a4a-9750-4057-afe6-e6b289c42014",
  "push_notifications_enabled": true,
  "email_notifications_enabled": false,
  "in_app_notifications_enabled": true,
  "quiet_hours_enabled": true,
  "quiet_hours_start": "22:00:00",
  "quiet_hours_end": "08:00:00",
  "email_digest_frequency": "daily",
  "updated_at": "2025-09-22T12:30:45.123456Z"
}
```

---

## 10. Device Token Management

### 10.1 Register Device Token

#### Endpoint
```
POST /api/notifications/device-tokens/register/
```

#### Description
Register a device token for push notifications (FCM for Android, APNs for iOS).

#### Request Body
```json
{
  "token": "fcm_or_apns_token_string",
  "device_type": "android|ios|web",
  "device_name": "John's iPhone 13", // optional
  "app_version": "1.2.3", // optional
  "device_id": "unique_device_identifier" // optional
}
```

#### Request Example
```bash
curl -X POST \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "token": "dGhpcyBpcyBhIGZha2UgRkNNIHRva2Vu...",
    "device_type": "android",
    "device_name": "Samsung Galaxy S21",
    "app_version": "1.2.3",
    "device_id": "android_device_123"
  }' \
  "http://localhost:8000/api/notifications/device-tokens/register/"
```

#### Success Response (201 Created)
```json
{
  "message": "Device token registered successfully",
  "token_id": "token_456",
  "device_type": "android",
  "device_name": "Samsung Galaxy S21",
  "is_active": true,
  "created_at": "2025-09-22T12:30:45.123456Z"
}
```

#### Error Responses
```json
// 400 Bad Request (invalid device type)
{
  "device_type": ["Select a valid choice. invalid is not one of the available choices."]
}

// 400 Bad Request (token already exists)
{
  "detail": "Device token already registered for this user"
}
```

### 10.2 Remove Device Token

#### Endpoint
```
POST /api/notifications/device-tokens/remove/
```

#### Request Body
```json
{
  "token": "token_to_remove"
}
```

#### Request Example
```bash
curl -X POST \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"token": "dGhpcyBpcyBhIGZha2UgRkNNIHRva2Vu..."}' \
  "http://localhost:8000/api/notifications/device-tokens/remove/"
```

#### Success Response (200 OK)
```json
{
  "message": "1 device token(s) removed successfully",
  "removed_count": 1
}
```

### 10.3 List Device Tokens

#### Endpoint
```
GET /api/notifications/device-tokens/list/
```

#### Request Example
```bash
curl -H "Authorization: Bearer <token>" \
  "http://localhost:8000/api/notifications/device-tokens/list/"
```

#### Success Response (200 OK)
```json
{
  "device_tokens": [
    {
      "id": "token_456",
      "device_type": "android",
      "device_name": "Samsung Galaxy S21",
      "is_active": true,
      "app_version": "1.2.3",
      "created_at": "2025-09-22T12:30:45.123456Z",
      "last_used": "2025-09-22T14:15:30.789012Z"
    },
    {
      "id": "token_789",
      "device_type": "ios",
      "device_name": "John's iPhone 13",
      "is_active": true,
      "app_version": "1.2.2",
      "created_at": "2025-09-20T10:20:30.456789Z",
      "last_used": "2025-09-22T13:45:20.123456Z"
    }
  ],
  "total_active_devices": 2
}
```

### 10.4 Test Push Notification

#### Endpoint
```
POST /api/notifications/device-tokens/test/
```

#### Description
Send a test push notification to verify device tokens are working.

#### Request Body
```json
{
  "device_token_id": "token_456", // optional - if not provided, sends to all user's devices
  "test_message": "Custom test message" // optional
}
```

#### Request Example
```bash
curl -X POST \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "device_token_id": "token_456",
    "test_message": "Hello from TIRI! This is a test notification."
  }' \
  "http://localhost:8000/api/notifications/device-tokens/test/"
```

#### Success Response (200 OK)
```json
{
  "message": "Test notification sent successfully",
  "sent_to_devices": 1,
  "notification_id": "test_notif_123"
}
```

---

## 11. Error Codes Reference

### HTTP Status Codes

| Code | Description | Common Causes |
|------|-------------|---------------|
| 200 | OK | Request successful |
| 201 | Created | Resource created successfully |
| 204 | No Content | Resource deleted successfully |
| 400 | Bad Request | Invalid request data, validation errors |
| 401 | Unauthorized | Missing or invalid authentication token |
| 403 | Forbidden | User doesn't have permission |
| 404 | Not Found | Resource not found |
| 429 | Too Many Requests | Rate limit exceeded |
| 500 | Internal Server Error | Server error |

### Common Error Response Format
```json
{
  "detail": "Error description",
  "code": "error_code", // optional
  "errors": { // optional, for validation errors
    "field_name": ["Error message for this field"]
  }
}
```

### Authentication Errors
```json
// Missing token
{
  "detail": "Authentication credentials were not provided."
}

// Invalid token
{
  "detail": "Given token not valid for any token type",
  "code": "token_not_valid"
}

// Expired token
{
  "detail": "Token is invalid or expired"
}
```

### Validation Errors
```json
// Field validation errors
{
  "detail": "Validation failed",
  "errors": {
    "notification_type": ["This field is required."],
    "priority": ["Select a valid choice. invalid_priority is not one of the available choices."],
    "page_size": ["Ensure this value is less than or equal to 100."]
  }
}
```

---

## 12. Notification Types Reference

### Authentication & Account Management
| Type | Display Name | When Triggered | Priority |
|------|--------------|----------------|----------|
| `welcome_email` | Welcome Email | After registration | Normal |
| `email_verification` | Email Verification | Email verification sent | Normal |
| `referral_approved` | Referral Code Approved | Referrer approves user | Normal |
| `account_verified` | Account Verified | Account verification complete | Normal |
| `password_reset_request` | Password Reset Request | Password reset requested | High |
| `password_reset_confirmation` | Password Reset Confirmation | Password reset successful | Normal |
| `referral_code_used` | Referral Code Used | Someone uses your referral code | Normal |
| `your_referral_approved` | Your Referral Approved | You approved someone's referral | Normal |

### Service Requests - For Requesters
| Type | Display Name | When Triggered | Priority |
|------|--------------|----------------|----------|
| `request_accepted` | Request Accepted | Volunteer accepts request | High |
| `volunteer_cancelled` | Volunteer Cancelled | Volunteer cancels | High |
| `volunteer_checked_in` | Volunteer Checked In | Volunteer arrives | Normal |
| `volunteer_completed` | Volunteer Completed | Volunteer marks complete | Normal |
| `request_fully_staffed` | Request Fully Staffed | All slots filled | Normal |
| `request_reminder` | Request Reminder | Upcoming request reminder | Normal |

### Service Requests - For Volunteers
| Type | Display Name | When Triggered | Priority |
|------|--------------|----------------|----------|
| `new_nearby_request` | New Nearby Request | New request in area | Normal |
| `volunteer_request_reminder` | Volunteer Request Reminder | Upcoming volunteer reminder | Normal |
| `check_in_reminder` | Check-in Reminder | Time to check in | High |
| `other_volunteers_joined` | Other Volunteers Joined | Other volunteers join | Normal |
| `request_completion_confirmed` | Request Completion Confirmed | Requester confirms complete | Normal |
| `request_details_changed` | Request Details Changed | Request updated | Normal |

### General Service Requests
| Type | Display Name | When Triggered | Priority |
|------|--------------|----------------|----------|
| `request_updated` | Request Updated | Request details changed | Normal |
| `request_cancelled` | Request Cancelled | Request cancelled | High |

### Chat & Messaging
| Type | Display Name | When Triggered | Priority |
|------|--------------|----------------|----------|
| `new_message` | New Message | New chat message | Normal |
| `chat_room_created` | Chat Room Created | Added to chat room | Normal |
| `file_shared` | File/Image Shared | File shared in chat | Normal |
| `group_message` | Group Message | Group chat message | Normal |

### Feedback & Reputation
| Type | Display Name | When Triggered | Priority |
|------|--------------|----------------|----------|
| `new_feedback` | New Feedback Received | Feedback received | Normal |
| `rating_received` | Rating Received | Star rating received | Normal |
| `hours_added` | Hours Added | Hours added to reputation | Normal |
| `feedback_requested` | Feedback Requested | Asked to provide feedback | Normal |
| `feedback_deadline` | Feedback Deadline | Feedback deadline reminder | High |

### Priority Levels
- **`low`** - General updates, non-urgent information
- **`normal`** - Standard notifications (default)
- **`high`** - Important actions needed, time-sensitive
- **`urgent`** - Critical notifications requiring immediate attention

### Delivery Methods
- **`push`** - FCM/APNs push notification
- **`email`** - SMTP email notification
- **`in_app`** - In-app notification list only

---

## Rate Limits

- **General API calls**: 100 requests per minute per user
- **Bulk operations**: 10 requests per minute per user
- **Device token registration**: 20 requests per minute per user

## Testing

Use the test account credentials for API testing:
```
Email: photofishai@gmail.com
Password: Photofish123@
```

Get access token:
```bash
curl -X POST http://localhost:8000/api/auth/login/ \
  -H "Content-Type: application/json" \
  -d '{"email": "photofishai@gmail.com", "password": "Photofish123@"}'
```

---

*This documentation covers all notification API endpoints available in TIRI. For additional support, contact the backend development team.*