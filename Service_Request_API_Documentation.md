# Service Request API Documentation

## Quick Reference

**Base URL:** `/api/requests/`

### Status Flow
```
pending → accepted → in_progress → completed
          ↓           ↑
       delayed → auto_cancelled
```

---

## 1. Request States & UI Actions

### 📍 PENDING (Status: `pending`)

#### Volunteer View
**What user sees:**
- Service request card in community feed
- "Join Request" button
- Requester profile link

**API Endpoints:**
```http
GET /api/requests/{id}/
POST /api/requests/{id}/accept/
GET /api/profile/{user_id}/
```

**Accept Request:**
```bash
POST /api/requests/{id}/accept/
Content-Type: application/json

{
  "message": "I'd love to help!",
  "estimated_arrival": "2025-09-25T14:00:00Z"  # optional
}

Response 200:
{
  "message": "Volunteer request sent successfully"
}
```

#### Requester View
**What user sees:**
- "Delete Request" button
- List of volunteer applications (if any)
- For each applicant:
  - Chat button
  - Approve button
  - Reject button
  - Profile link

**API Endpoints:**
```http
DELETE /api/requests/{id}/
GET /api/requests/{id}/volunteer-requests/
POST /api/requests/{id}/approve-volunteer/
POST /api/requests/{id}/reject-volunteer/
POST /api/chat/rooms/create/
```

**Get Volunteer Applications:**
```bash
GET /api/requests/{id}/volunteer-requests/

Response 200:
{
  "volunteer_requests": [
    {
      "id": 16,
      "volunteer": {
        "userId": "214f...",
        "username": "john_doe",
        "email": "john@example.com",
        "profilePicture": "https://...",
        "first_name": "John",
        "last_name": "Doe"
      },
      "message": "I'd love to help!",
      "applied_at": "2025-09-24T11:51:29Z",
      "status": "pending",
      "estimated_arrival": "2025-09-25T14:00:00Z"
    }
  ],
  "count": 1
}
```

**Approve Volunteer:**
```bash
POST /api/requests/{id}/approve-volunteer/
Content-Type: application/json

{
  "volunteer_id": "214f1153-6e37-416b-86a2-72e392b84881"
}

Response 200:
{
  "message": "Volunteer approved successfully"
}
```

**Reject Volunteer:**
```bash
POST /api/requests/{id}/reject-volunteer/
Content-Type: application/json

{
  "volunteer_id": "214f1153-6e37-416b-86a2-72e392b84881",
  "reason": "Looking for someone with more experience"  # optional
}

Response 200:
{
  "message": "Volunteer request rejected successfully"
}
```

---

### ✅ ACCEPTED (Status: `accepted`)

#### Volunteer View
**What user sees:**
- "Cancel Request" button
- Chat with requester button
- Request details

**API Endpoints:**
```http
POST /api/requests/{id}/cancel-acceptance/
GET /api/chat/rooms/?request_id={id}
```

**Cancel Acceptance:**
```bash
POST /api/requests/{id}/cancel-acceptance/
Content-Type: application/json

{
  "reason": "Schedule conflict"  # optional
}

Response 200:
{
  "message": "Acceptance cancelled successfully"
}
```

#### Requester View
**What user sees:**
- "Start Request" button (manual start)
- List of accepted volunteers
- Chat with each volunteer button
- Volunteer count: X/Y

**API Endpoints:**
```http
POST /api/requests/{id}/start-request/
GET /api/requests/{id}/
```

**Manual Start Request:**
```bash
POST /api/requests/{id}/start-request/

Response 200:
{
  "message": "Request started successfully",
  "request": {
    "id": "33e31386-5db1-4f9f-8060-bf2afc66c1e4",
    "title": "Help with moving",
    "status": "in_progress",
    "start_time": "2025-09-24T11:52:03Z",
    "volunteers_count": 2
  }
}

Error 400:
{
  "error": "Request cannot be started from {status} status"
}
OR
{
  "error": "Need at least 1 approved volunteer to start"
}
```

---

### ⏰ DELAYED (Status: `delayed`)

**Triggered when:** `date_needed` passes but not enough volunteers OR requester hasn't started

#### Requester View
**What user sees:**
- ⚠️ "Request Delayed" warning
- "Start Anyway" button (1-hour grace period)
- Auto-cancel countdown timer
- Approved volunteers list

**API Endpoints:**
```http
POST /api/requests/{id}/start-anyway/
```

**Start Anyway (Grace Period):**
```bash
POST /api/requests/{id}/start-anyway/

Response 200:
{
  "message": "Request started successfully with available volunteers",
  "request": {
    "id": "33e31386-5db1-4f9f-8060-bf2afc66c1e4",
    "title": "Help with moving",
    "status": "in_progress",
    "start_time": "2025-09-24T12:30:15Z",
    "volunteers_count": 1
  }
}

Error 400:
{
  "error": "This endpoint is only for delayed requests"
}
```

---

### 🚀 IN PROGRESS (Status: `in_progress`)

#### Volunteer View
**What user sees:**
- Chat buttons:
  - 1-on-1 chat with requester
  - Group chat (if multiple volunteers)
- Request details (read-only)
- **No cancel option** (locked in)

**API Endpoints:**
```http
GET /api/chat/rooms/?request_id={id}
GET /ws/chat/{room_id}/
```

#### Requester View
**What user sees:**
- Chat access (1-on-1 and group)
- "Complete Request" button
- Volunteers list with status

**API Endpoints:**
```http
POST /api/requests/{id}/complete/
```

**Complete Request:**
```bash
POST /api/requests/{id}/complete/
Content-Type: application/json

{
  "notes": "Great job everyone!"  # optional
}

Response 200:
{
  "message": "Request completed successfully",
  "request": {
    "id": "33e31386-5db1-4f9f-8060-bf2afc66c1e4",
    "title": "Help with moving",
    "status": "completed",
    "completed_at": "2025-09-24T16:30:00Z"
  },
  "volunteers": [
    {
      "id": "214f...",
      "username": "john_doe",
      "name": "John Doe"
    }
  ]
}

Error 400:
{
  "error": "You must provide feedback for all volunteers before completing the request",
  "missing_feedback_for": "john_doe"
}
```

**Important:** Must give feedback to ALL volunteers before completing (atomic operation)

---

### ✔️ COMPLETED (Status: `completed`)

#### Both Views
**What user sees:**
- Request marked as completed
- Feedback summary (for volunteers)
- All details read-only

**API Endpoints:**
```http
GET /api/feedback/?service_request={id}
```

---

### ❌ AUTO CANCELLED (Status: `auto_cancelled`)

**Triggered when:** Delayed request not started within 1 hour

#### Both Views
**What user sees:**
- "Request Auto-Cancelled" message
- Reason: "Not started within grace period"
- All details read-only

---

## 2. Core API Response Format

### Service Request Detail
```json
{
  "id": "33e31386-...",
  "title": "Help with moving",
  "description": "Need help moving furniture",
  "status": "in_progress",
  "priority": "normal",

  "requester": {
    "id": "a05a3a4a-...",
    "username": "jane_smith",
    "full_name": "Jane Smith",
    "profile_image_url": "https://...",
    "average_rating": 4.5,
    "total_hours_helped": 120
  },

  "category": {
    "id": 1,
    "name": "Moving",
    "icon": "fa-truck",
    "color": "#007bff"
  },

  "date_needed": "2025-09-25T14:00:00Z",
  "estimated_hours": 3,
  "volunteers_needed": 2,
  "address": "123 Main St",
  "city": "San Francisco",

  "volunteers_assigned": [
    {
      "id": 16,
      "volunteer": {
        "id": "214f...",
        "username": "john_doe",
        "full_name": "John Doe",
        "profile_image_url": "https://...",
        "average_rating": 4.8,
        "total_hours_helped": 85
      },
      "status": "approved",
      "applied_at": "2025-09-24T10:00:00Z",
      "approved_at": "2025-09-24T10:15:00Z",
      "message_to_requester": "I'd love to help!"
    }
  ],

  "user_request_status": {
    "has_volunteered": true,
    "request_status": "approved",
    "can_request": false,
    "can_cancel_request": false,
    "can_withdraw": false,
    "next_actions": []
  },

  "start_time": "2025-09-24T11:52:03Z",
  "completed_at": null,
  "created_at": "2025-09-24T09:00:00Z",
  "updated_at": "2025-09-24T11:52:03Z",
  "expires_at": "2025-09-26T14:00:00Z"
}
```

---

## 3. Screen-by-Screen UI Guide

### 🏠 Community Feed Screen
**Filter by:**
- `?view=community` - All available requests
- `?status=pending` - Only pending requests
- `?category=1` - Filter by category

**Request Card Shows:**
- Title, category icon, priority badge
- Volunteers: X/Y
- Distance (if location enabled)
- Time until needed
- "Join" button (if `status=pending` and not full)

### 📝 Request Detail Screen

**Dynamic UI based on:**
```javascript
const isRequester = request.requester.id === currentUserId
const myVolunteerStatus = request.user_request_status.request_status
const requestStatus = request.status

// Show buttons based on role and status
if (isRequester) {
  switch(requestStatus) {
    case 'pending':
      show: ['Delete', 'View Applications']
      break
    case 'accepted':
      show: ['Start Request']
      break
    case 'delayed':
      show: ['Start Anyway', 'Cancel Warning']
      break
    case 'in_progress':
      show: ['Complete Request', 'Chat']
      break
  }
} else {
  switch(requestStatus) {
    case 'pending':
      show: ['Join Request']
      break
    case 'accepted':
      if (myVolunteerStatus === 'approved') {
        show: ['Cancel Request', 'Chat']
      }
      break
    case 'in_progress':
      if (myVolunteerStatus === 'approved') {
        show: ['Group Chat', '1-on-1 Chat']
      }
      break
  }
}
```

### 💬 Chat Access

**1-on-1 Chat:**
```bash
POST /api/chat/rooms/create/
{
  "request_id": "33e31386-...",
  "participant_id": "214f..."
}

Response:
{
  "room_id": "abc123...",
  "room_type": "one_on_one"
}
```

**Group Chat:**
```bash
GET /api/chat/rooms/?request_id={id}&is_group_chat=true

Response:
{
  "rooms": [
    {
      "id": "xyz789...",
      "is_group_chat": true,
      "participants": [...]
    }
  ]
}
```

**WebSocket Connection:**
```javascript
ws://localhost:8000/ws/chat/{room_id}/?token={access_token}
```

---

## 4. Automated Workflows

### Auto-Start (Background Job)
**Runs:** Every 1 minute
**Triggers:** When `date_needed <= now()` AND `status IN ['pending', 'accepted']`

**Logic:**
```
IF approved_volunteers >= volunteers_needed:
  → status = 'in_progress'
  → Create group chat (if > 1 volunteer)
  → Notify all participants
ELSE:
  → status = 'delayed'
  → Start 1-hour grace period timer
  → Notify requester
```

### Auto-Cancel (Background Job)
**Runs:** Every 1 hour
**Triggers:** When `status = 'delayed'` AND `delayed_at + 1 hour <= now()`

**Logic:**
```
→ status = 'auto_cancelled'
→ Notify all volunteers
→ End request
```

### Auto-Complete (Background Job)
**Runs:** Every 1 hour
**Triggers:** When `status = 'in_progress'` AND `start_time + 48 hours <= now()`

**Logic:**
```
→ status = 'completed'
→ auto_completed = True
→ Start feedback enforcement timer
→ Notify requester
```

---

## 5. Error Handling

**Common Error Codes:**
```json
400 Bad Request
{
  "error": "Cannot accept your own request"
}

403 Forbidden
{
  "error": "Only the requester can approve volunteers"
}

404 Not Found
{
  "error": "Volunteer request not found or already processed"
}
```

**Frontend should handle:**
- Invalid state transitions (400)
- Permission errors (403)
- Network timeouts (retry logic)
- WebSocket disconnections (auto-reconnect)

---

## 6. State Transition Rules

| From | To | Trigger | Required Role |
|------|-----|---------|---------------|
| pending | accepted | First volunteer approved | Requester |
| accepted | pending | All volunteers withdraw | System |
| accepted | in_progress | Manual start OR auto-start | Requester/System |
| accepted | delayed | date_needed passes, not enough volunteers | System |
| delayed | in_progress | Requester clicks "Start Anyway" | Requester |
| delayed | auto_cancelled | 1 hour grace period expires | System |
| in_progress | completed | Requester completes + gives feedback | Requester |

---

## 7. Testing Checklist

**Frontend should test:**
- ✅ Join request as volunteer
- ✅ Requester approves/rejects volunteer
- ✅ Manual start request
- ✅ Cancel volunteer request (before in_progress)
- ✅ Complete request (with feedback requirement)
- ✅ Chat access (1-on-1 and group)
- ✅ State-based button visibility
- ✅ Error message display
- ✅ Auto-cancel countdown (delayed state)

---

**Last Updated:** 2025-09-24
**API Version:** 1.0