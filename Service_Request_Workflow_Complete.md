# TIRI Service Request Workflow - Complete Reference

> **Version:** 2.0
> **Last Updated:** 2025-09-24
> **Status:** Implementation Ready

---

## 📋 Executive Summary

The TIRI service request system manages the complete lifecycle of community help requests, from creation to completion and feedback. It operates on a **time-based automation system** with strict enforcement of volunteer commitments and requester accountability.

**Key Metrics:**
- ⏱️ **48-hour auto-completion** after work starts
- 🔒 **72-hour feedback deadline** with account suspension enforcement
- ⚖️ **3-strike termination** policy for repeat offenders
- 🚫 **1-hour grace period** for understaffed requests

---

## 🗂️ Quick Reference

### Status Overview

| Status | Description | Can Accept Volunteers? | Visible in Public Feed? | Next States |
|--------|-------------|------------------------|-------------------------|-------------|
| **pending** | Just created, open for volunteers | ✅ Yes | ✅ Yes (if not full) | accepted, cancelled, expired |
| **accepted** | At least 1 volunteer approved | ✅ Yes (if not full) | ✅ Yes (if not full) | in_progress, pending, cancelled, expired |
| **in_progress** | Work started, volunteers locked in | ❌ No | ❌ No | completed, auto_cancelled |
| **expired** | Not enough volunteers at deadline | ❌ No | ❌ No | in_progress, auto_cancelled |
| **completed** | Work finished, awaiting feedback | ❌ No | ❌ No | *(terminal)* |
| **cancelled** | Requester cancelled before start | ❌ No | ❌ No | *(terminal)* |
| **auto_cancelled** | System cancelled (no volunteers) | ❌ No | ❌ No | *(terminal)* |

### Volunteer Assignment Statuses

| Status | Description | Can Withdraw? | Locked In? |
|--------|-------------|---------------|------------|
| **pending** | Applied, awaiting approval | ✅ Yes (cancel) | ❌ No |
| **approved** | Requester approved | ✅ Yes (withdraw) | ❌ No |
| **rejected** | Requester rejected | ❌ N/A | ❌ No |
| **cancelled** | Volunteer cancelled before approval | ❌ N/A | ❌ No |
| **withdrawn** | Volunteer left after approval | ❌ N/A | ❌ No |
| **completed** | Work done, feedback received | ❌ N/A | ✅ Yes |
| **auto_cancelled** | System cancelled request | ❌ N/A | ❌ No |

### Time-Based Rules

| Event | Timing | Action | Consequences |
|-------|--------|--------|--------------|
| Request created | Immediate | Status = `pending` | Visible in public feed |
| `date_needed` arrives | Minute-precision | Auto-start OR expire | Depends on volunteer count |
| Expired → grace period | +1 hour | Auto-cancel | All volunteers notified |
| Work starts | When `in_progress` | Start 48h timer | Group chat created |
| Auto-complete | +48 hours | Status = `completed` | Feedback timer starts |
| Feedback deadline 1 | +24h from complete | Remind button enabled | Volunteers can nudge |
| Feedback deadline 2 | +48h from complete | Final warning sent | Email + push notification |
| Feedback deadline 3 | +72h from complete | Account suspended | 72-hour lockout |

---

## 🔄 Complete Workflow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                    SERVICE REQUEST LIFECYCLE                     │
└─────────────────────────────────────────────────────────────────┘

 [CREATE REQUEST]
        │
        ▼
   ┌─────────┐
   │ PENDING │ ◄─────────────────┐ (volunteer withdraws,
   └─────────┘                   │  all volunteers gone)
        │                        │
        │ (first volunteer       │
        │  approved)             │
        ▼                        │
   ┌─────────┐                   │
   │ACCEPTED │                   │
   └─────────┘                   │
        │                        │
        │ (slots filled OR       │
        │  time arrives)         │
        ▼                        │
   ┌──────────────────┐          │
   │ CHECKPOINT:      │          │
   │ date_needed time │          │
   └──────────────────┘          │
        │                        │
        ├─────────────┬──────────┘
        │             │
        ▼             ▼
  [Enough Vol]   [Not Enough]
        │             │
        ▼             ▼
 ┌────────────┐  ┌─────────┐
 │IN_PROGRESS │  │ EXPIRED │
 └────────────┘  └─────────┘
        │             │
        │             ├───────────┐
        │             │           │
        │      [Requester         │
        │       starts    [1 hour grace
        │       anyway]    period ends]
        │             │           │
        │             ▼           ▼
        │        ┌────────────┐ ┌──────────────┐
        │        │IN_PROGRESS │ │AUTO_CANCELLED│
        │        └────────────┘ └──────────────┘
        │             │               │
        │             │               ▼
        ▼             ▼          [Dead request]
    [48 hours]   [Manual
     timer]       complete]
        │             │
        ├─────────────┤
        │             │
        ▼             ▼
   ┌───────────┐
   │ COMPLETED │
   └───────────┘
        │
        ▼
   [Feedback enforcement]
        │
        ├─────┬─────┬─────┐
        │     │     │     │
       24h   48h   72h  ✅
        │     │     │  Feedback
        │     │     │  submitted
        │     │     │
     [Wait] [Warn] [Suspend]
```

---

## 📊 Detailed State Transitions

### 1. Request Creation

```
USER INPUT → BACKEND PROCESSING → RESULT
```

| Step | Action | Backend Processing | Database Changes |
|------|--------|-------------------|------------------|
| 1 | User fills form | Validate all fields | - |
| 2 | Submit request | Create ServiceRequest object | `status = 'pending'` |
| 3 | Set expiration | Calculate from `date_needed` | `expires_at = date_needed` |
| 4 | Make visible | Add to public feed query | - |

**Fields Stored:**
- `date_needed` (DateTimeField) - Exact date + time
- `volunteers_needed` (1-10)
- `estimated_hours` (1-24)
- Location, description, category, etc.

---

### 2. Volunteer Application Flow

```
┌──────────────┐
│   VOLUNTEER  │
│    CLICKS    │
│ "HELP BUTTON"│
└──────────────┘
       │
       ▼
┌──────────────────┐
│  Create Entry:   │
│ RequestVolunteer │
│ status='pending' │
└──────────────────┘
       │
       ▼
┌──────────────────┐     ┌─────────────────┐
│  Requester sees  │────▶│  NOTIFICATION   │
│  application in  │     │ (FCM - dormant) │
│  request details │     └─────────────────┘
└──────────────────┘
       │
       ▼
┌──────────────────────────────┐
│  Requester Decision:         │
│  ┌─────────┐   ┌──────────┐ │
│  │ APPROVE │   │  REJECT  │ │
│  └─────────┘   └──────────┘ │
└──────────────────────────────┘
       │                  │
       ▼                  ▼
   [Approved]        [Rejected]
   status='approved'  status='rejected'
       │                  │
       ▼                  └─────▶ [Volunteer notified]
   Add to ManyToMany              [Update log (private)]
   volunteers_assigned
       │
       ▼
   IF first volunteer:
   Request status → 'accepted'
       │
       ▼
   Check if full (approved == needed)
       │
       ├─────────────┬─────────────┐
       ▼             ▼             ▼
   [Not full]    [Full]       [Full→Not Full]
   Stay in feed  Hide from   Reappear in feed
                 public feed (volunteer withdraws)
```

---

### 3. Scheduled Time Trigger

```
┌─────────────────────────────────────────────────────┐
│         BACKGROUND JOB (Every 1 minute)             │
│  Query: date_needed <= now() AND status IN          │
│         ('pending', 'accepted')                     │
└─────────────────────────────────────────────────────┘
                         │
                         ▼
          ┌──────────────────────────┐
          │  Count approved          │
          │  volunteers              │
          └──────────────────────────┘
                         │
          ┌──────────────┴──────────────┐
          ▼                             ▼
    ┌──────────┐                  ┌───────────┐
    │ approved │                  │ approved  │
    │    >=    │                  │     <     │
    │  needed  │                  │  needed   │
    └──────────┘                  └───────────┘
          │                             │
          ▼                             ▼
┌──────────────────┐          ┌──────────────────┐
│  AUTO-START      │          │  EXPIRE REQUEST  │
│                  │          │                  │
│ • Status →       │          │ • Status →       │
│   'in_progress'  │          │   'expired'      │
│ • Set start_time │          │ • Set expired_at │
│ • Create group   │          │ • Start 1h timer │
│   chat (if >1)   │          │ • Notify requester│
│ • Notify all     │          └──────────────────┘
│ • Lock volunteers│                    │
└──────────────────┘          ┌─────────┴────────┐
          │                   │                  │
          ▼                   ▼                  ▼
  [Work begins]      [Wait 1 hour]    [Requester clicks
                              │        "Start Anyway"]
                              ▼                  │
                     ┌─────────────────┐         │
                     │ AUTO-CANCEL     │         │
                     │ status →        │         │
                     │ 'auto_cancelled'│         │
                     │                 │         │
                     │ • Notify all    │         │
                     │ • Dead request  │         │
                     └─────────────────┘         │
                                                  ▼
                                         ┌────────────────┐
                                         │ Status →       │
                                         │ 'in_progress'  │
                                         │ (with fewer    │
                                         │  volunteers)   │
                                         └────────────────┘
```

---

### 4. Work Completion & Feedback

```
┌─────────────────────────────────────────────────────┐
│              COMPLETION TRIGGERS                     │
└─────────────────────────────────────────────────────┘
                         │
         ┌───────────────┴───────────────┐
         ▼                               ▼
┌──────────────────┐          ┌────────────────────┐
│ MANUAL COMPLETE  │          │  AUTO-COMPLETE     │
│ (within 48h)     │          │  (at 48h mark)     │
│                  │          │                    │
│ Requester clicks │          │ Background job:    │
│ "Mark Complete"  │          │ start_time + 48h   │
└──────────────────┘          └────────────────────┘
         │                               │
         │                               ▼
         │                    ┌────────────────────┐
         │                    │ auto_completed =   │
         │                    │       True         │
         │                    └────────────────────┘
         │                               │
         └───────────────┬───────────────┘
                         ▼
              ┌─────────────────────┐
              │ Status = 'completed'│
              │ completed_at = now()│
              └─────────────────────┘
                         │
         ┌───────────────┴─────────────┐
         ▼                             ▼
  [MANUAL PATH]                 [AUTO PATH]
         │                             │
         ▼                             ▼
  Show feedback form          Feedback not submitted
  (immediate, atomic)                  │
         │                             │
         ▼                             ▼
  Requester MUST submit      ┌──────────────────────┐
  before API completes       │  FEEDBACK TIMELINE   │
         │                   └──────────────────────┘
         │                             │
         │                   ┌─────────┴─────────┐
         │                   │                   │
         ▼                   ▼                   ▼
  [Feedback given]      [24h passes]       [48h passes]
         │                   │                   │
         │                   ▼                   ▼
         │          ┌─────────────────┐ ┌─────────────────┐
         │          │ "Remind" button │ │ AUTO-SEND       │
         │          │ shown to        │ │ Final warning:  │
         │          │ volunteers      │ │ • Email         │
         │          └─────────────────┘ │ • Push notify   │
         │                   │          └─────────────────┘
         │                   │                   │
         │                   └─────────┬─────────┘
         │                             │
         │                             ▼
         │                        [72h passes]
         │                             │
         │                             ▼
         │                   ┌─────────────────────┐
         │                   │ SUSPEND ACCOUNT     │
         │                   │ • 72-hour lockout   │
         │                   │ • Increment counter │
         │                   │ • Force logout      │
         │                   │                     │
         │                   │ If 3rd offense:     │
         │                   │ TERMINATE ACCOUNT   │
         │                   └─────────────────────┘
         │                             │
         └─────────────────────────────┘
                         │
                         ▼
              ┌─────────────────────┐
              │  REPUTATION UPDATE  │
              │  (per volunteer)    │
              │                     │
              │ • total_hours +=    │
              │ • avg_rating calc   │
              │ • rating_count++    │
              └─────────────────────┘
```

---

## 🎯 Feed Visibility Logic

### Public Feed Algorithm

```python
# Pseudo-code for public feed query
requests = ServiceRequest.objects.filter(
    # Must be open status
    status__in=['pending', 'accepted'],

    # Not user's own request
    ~Q(requester=current_user),

    # Not fully staffed
    # (calculated: volunteers_assigned.count() < volunteers_needed)

    # Not past deadline
    date_needed__gt=now()
)

# DYNAMIC BEHAVIOR:
# - Request appears when created
# - Disappears when full (4/4 volunteers)
# - REAPPEARS when volunteer withdraws (3/4)
# - Disappears permanently when in_progress
```

### Visibility State Table

| Scenario | Volunteers | Status | In Public Feed? | In User Feed? |
|----------|-----------|--------|-----------------|---------------|
| Just created | 0/4 | pending | ✅ Yes | ✅ Yes (requester) |
| 1st approved | 1/4 | accepted | ✅ Yes | ✅ Yes (requester + volunteer) |
| 2nd approved | 2/4 | accepted | ✅ Yes | ✅ Yes (all participants) |
| 3rd approved | 3/4 | accepted | ✅ Yes | ✅ Yes |
| 4th approved | 4/4 | accepted | ❌ No (FULL) | ✅ Yes |
| 1 withdraws | 3/4 | accepted | ✅ Yes (REOPENS) | ✅ Yes |
| Work starts | 4/4 | in_progress | ❌ No | ✅ Yes |
| Completed | 4/4 | completed | ❌ No | ✅ Yes |
| Expired (no vol) | 0/4 | expired | ❌ No | ✅ Yes (requester) |

---

## 🚨 Edge Cases & Scenarios

### Edge Case 1: Race Condition - Last Slot

**Scenario:** Request needs 4 volunteers, has 3 approved. Two volunteers click "Accept" simultaneously for the last slot.

```
┌─────────────────────────────────────────┐
│  Volunteer A          Volunteer B       │
│      │                     │            │
│      ▼                     ▼            │
│  [Click Accept]      [Click Accept]     │
│      │                     │            │
│      ▼                     ▼            │
│  Check: 3/4          Check: 3/4         │
│  (both pass)         (both pass)        │
│      │                     │            │
│      ▼                     ▼            │
│  Create pending      Create pending     │
│      │                     │            │
│      ▼                     ▼            │
│  BOTH SUCCEED - NOW 5 PENDING           │
└─────────────────────────────────────────┘
```

**Current Behavior:** ⚠️ Both volunteers can apply (no issue at pending stage)
**Issue At:** Requester approval - can approve more than needed
**Fix Needed:** Add database lock when approving: `select_for_update()`

---

### Edge Case 2: Volunteer Withdraws During Auto-Start

**Scenario:** Request has exactly 4/4 volunteers. Auto-start job runs at `date_needed`. Simultaneously, 1 volunteer withdraws.

```
Time: 14:00:00.000
┌─────────────────────────────────────────┐
│  Background Job      Volunteer Action   │
│       │                    │            │
│  Check: 4/4           Click "Withdraw"  │
│  approved >= 4        Remove from       │
│       │               volunteers_assigned│
│       │                    │            │
│       ▼                    ▼            │
│  Start request       Now 3/4            │
│  status →            status → withdrawn │
│  'in_progress'                          │
│       │                                 │
│       ▼                                 │
│  Create group chat (includes           │
│  withdrawn volunteer!)                  │
└─────────────────────────────────────────┘
```

**Current Behavior:** ⚠️ Request starts with 3 volunteers, 4th already withdrew
**Fix Needed:** Atomic check + transaction for auto-start

---

### Edge Case 3: Browser Crash During Feedback

**Scenario:** Requester manually marks complete, feedback form opens, browser crashes before submit.

```
┌─────────────────────────────────────────┐
│        OLD BEHAVIOR (BAD)               │
│                                         │
│  Click "Complete" → Status='completed'  │
│  Show feedback form                     │
│  [Browser crash]                        │
│  No feedback given                      │
│  72h timer starts → Suspension!         │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│        NEW BEHAVIOR (GOOD)              │
│                                         │
│  Click "Complete" → Frontend shows form │
│  User fills feedback                    │
│  Submit → ATOMIC API call:              │
│    1. Mark complete                     │
│    2. Submit feedback                   │
│    3. Both succeed or both fail         │
│  [Browser crash before submit]          │
│  → Request still 'in_progress'          │
└─────────────────────────────────────────┘
```

**Solution:** Manual completion requires feedback in same API transaction

---

### Edge Case 4: Account Suspended Mid-Request

**Scenario:** User is suspended (missing feedback on another request) while they have active requests.

```
User has:
• Request A: Requester (in_progress)
• Request B: Volunteer (approved, not started)
• Request C: Volunteer (in_progress, locked in)

[Gets suspended at 72h mark for Request D]

┌─────────────────────────────────────────┐
│  ALL API CALLS NOW BLOCKED              │
│                                         │
│  GET /api/requests/   → 403 Forbidden   │
│  GET /api/chat/       → 403 Forbidden   │
│  POST /anything/      → 403 Forbidden   │
│                                         │
│  Frontend: Auto-logout                  │
│  Login attempt: "Suspended until..."    │
└─────────────────────────────────────────┘

IMPACT ON ACTIVE REQUESTS:
• Request A: ⚠️ Cannot complete or give feedback
  → Will auto-complete at 48h
  → Suspension extended! (missing more feedback)

• Request B: ✅ Other requester can reject & find new volunteer

• Request C: ⚠️ Locked in but can't communicate
  → Still receives hours when requester gives feedback
  → Reputation updated even while suspended
```

**Suspension Scope:** Complete API lockout
**Active Request Handling:** Other users unaffected, hours still awarded

---

### Edge Case 5: Manual Start with Zero Volunteers

**Scenario:** Requester tries to manually start request before `date_needed` with 0 approved volunteers.

```
Request created, 0 volunteers applied
       │
       ▼
Requester clicks "Start Request"
       │
       ▼
┌─────────────────────────────────┐
│  VALIDATION CHECK:              │
│  if approved_volunteers < 1:    │
│     return 400 Bad Request      │
│     "Need at least 1 volunteer" │
└─────────────────────────────────┘
       │
       ▼
   [BLOCKED]
```

**Current Behavior:** ✅ Prevented by validation
**Minimum Required:** 1 approved volunteer

---

## 🔗 Chat System Integration

### One-on-One Chat Creation

```
┌─────────────────────────────────────────┐
│  Requester OR Volunteer clicks "Chat"   │
└─────────────────────────────────────────┘
                    │
                    ▼
         ┌────────────────────┐
         │ Check if exists:   │
         │ ChatRoom.filter(   │
         │   request=X,       │
         │   requester=A,     │
         │   volunteer=B      │
         │ )                  │
         └────────────────────┘
                    │
         ┌──────────┴──────────┐
         ▼                     ▼
    [Exists]              [Not exists]
         │                     │
         ▼                     ▼
  Return room ID      Create new ChatRoom
         │            • Add both users
         │            • Link to request
         │            • is_group_chat=False
         │                     │
         └──────────┬──────────┘
                    ▼
          Open WebSocket connection
                    │
                    ▼
          /ws/chat/{room_id}/
```

**Timing:** Can chat anytime after volunteer is **approved**

---

### Group Chat Auto-Creation

```
Request status changes to 'in_progress'
                    │
                    ▼
         ┌────────────────────┐
         │ Count volunteers:  │
         │ if count > 1:      │
         │   create group chat│
         └────────────────────┘
                    │
                    ▼
         ┌────────────────────┐
         │ Create ChatRoom:   │
         │ • requester +      │
         │   all approved vol │
         │ • is_group_chat=   │
         │   True             │
         │ • Link to request  │
         └────────────────────┘
                    │
                    ▼
         ┌────────────────────┐
         │ Add all as         │
         │ participants       │
         └────────────────────┘
```

**Access Control Logic:**
```python
def can_access_group_chat(user, chat_room):
    request = chat_room.service_request

    # Real-time check (not one-time add)
    if user == request.requester:
        return True

    # Check if currently approved volunteer
    is_approved = request.volunteers_assigned.filter(
        id=user.id,
        requestvolunteer__status='approved'
    ).exists()

    return is_approved

# If volunteer withdraws:
# - Next message attempt → Access denied
# - Frontend shows: "You no longer have access"
```

---

## 📡 Notification Integration Points (FCM - Dormant)

### Notification Trigger Map

| Event | Recipient | Type | Priority | Message Template |
|-------|-----------|------|----------|------------------|
| Volunteer applies | Requester | `volunteer_request` | High | `{volunteer} wants to help with '{request}'` |
| Application approved | Volunteer | `request_accepted` | High | `Your request to join '{request}' was approved!` |
| Application rejected | Volunteer | `request_rejected` | Normal | `Your request was declined` |
| Request fully staffed | Requester | `request_fully_staffed` | Normal | `All {count} volunteer slots filled!` |
| Volunteer withdraws | Requester | `volunteer_cancelled` | High | `{volunteer} withdrew from '{request}'` |
| Request expired (no vol) | Requester | `request_expired` | High | `Not enough volunteers. Start anyway or cancel?` |
| Work auto-started | All participants | `work_started` | Normal | `Work has begun on '{request}'` |
| Request completed | All volunteers | `request_completed` | Normal | `'{request}' is complete. Please provide feedback!` |
| Feedback received | Volunteer | `feedback_received` | High | `You earned {hours} hours! {rating}⭐ from {requester}` |
| Feedback reminder | Requester | `feedback_reminder` | Normal | `Volunteers are waiting for feedback on '{request}'` |
| Final warning | Requester | `feedback_warning` | Urgent | `Provide feedback within 24h or account will be suspended` |
| Account suspended | User | `account_suspended` | Urgent | `Account suspended for 72h. Reason: Missing feedback` |
| Chat message (1-on-1) | Other person | `new_message` | Normal | `{sender}: {preview}` |
| Chat message (group) | All except sender | `new_group_message` | Normal | `{sender} in {request}: {preview}` |

### Implementation Pattern

```python
# Will be added to each workflow step:

from apps.notifications.services import NotificationService

# Example: After volunteer approval
NotificationService.create_notification(
    recipient=volunteer,
    notification_type='request_accepted',
    title='Request Approved!',
    message=f'Your request to join "{request.title}" was accepted',
    related_object_type='service_request',
    related_object_id=request.id,
    priority='high',

    # FCM-specific data
    fcm_data={
        'click_action': 'OPEN_REQUEST',
        'request_id': str(request.id)
    }
)

# Notification service will:
# 1. Save to database (for in-app)
# 2. Send FCM push (background task)
# 3. Log delivery status
```

---

## 🛠️ Implementation Checklist

### Phase 1: Data Model Updates

- [ ] **ServiceRequest model:**
  - [ ] Add `auto_cancelled` to RequestStatus choices
  - [ ] Add `start_time` (DateTimeField, null=True)
  - [ ] Add `auto_completed` (BooleanField, default=False)
  - [ ] Add `expired_at` (DateTimeField, null=True)
  - [ ] Update `save()` to set `expires_at = date_needed`

- [ ] **User model:**
  - [ ] Add `is_suspended` (BooleanField, default=False)
  - [ ] Add `suspension_end_time` (DateTimeField, null=True)
  - [ ] Add `suspension_count` (IntegerField, default=0)
  - [ ] Add `feedback_violations` (IntegerField, default=0)

- [ ] **ChatRoom model:**
  - [ ] Add `is_group_chat` (BooleanField, default=False)

- [ ] **RequestVolunteer model:**
  - [ ] Add `auto_cancelled` status to choices (already has others)

### Phase 2: Background Jobs Setup

- [ ] **Install scheduler:**
  - [ ] Option A: `django-cron`
  - [ ] Option B: `Celery` + `Celery Beat`
  - [ ] Option C: `APScheduler`

- [ ] **Create cron jobs:**
  - [ ] `auto_start_requests.py` - Every 1 minute
  - [ ] `auto_cancel_expired.py` - Every 1 hour
  - [ ] `auto_complete_requests.py` - Every 1 hour
  - [ ] `feedback_enforcement.py` - Every 1 hour

### Phase 3: Core Workflow Logic

- [ ] **Auto-start logic:**
  - [ ] Query requests where `date_needed <= now()`
  - [ ] Count approved volunteers
  - [ ] If enough: status → `in_progress`, create group chat
  - [ ] If not: status → `expired`, start grace timer

- [ ] **Auto-cancel logic:**
  - [ ] Query `expired` requests where `expired_at + 1h <= now()`
  - [ ] Status → `auto_cancelled`
  - [ ] Notify all volunteers

- [ ] **Auto-complete logic:**
  - [ ] Query `in_progress` where `start_time + 48h <= now()`
  - [ ] Status → `completed`, `auto_completed = True`
  - [ ] Start feedback timer

- [ ] **Feedback enforcement:**
  - [ ] Check `completed` requests without feedback
  - [ ] 24h: Enable remind button
  - [ ] 48h: Send final warning (email + push)
  - [ ] 72h: Suspend account

### Phase 4: Group Chat Auto-Creation

- [ ] **Trigger on in_progress:**
  - [ ] Hook into status change to `in_progress`
  - [ ] Check volunteer count > 1
  - [ ] Create ChatRoom with `is_group_chat=True`
  - [ ] Add requester + all approved volunteers

- [ ] **Access control:**
  - [ ] Update chat permissions to check real-time status
  - [ ] Remove static membership, use dynamic check

### Phase 5: Account Suspension System

- [ ] **Middleware:**
  - [ ] Create `SuspensionCheckMiddleware`
  - [ ] Check `is_suspended` and `suspension_end_time`
  - [ ] If suspended: Return 403 with suspension details

- [ ] **Login blocker:**
  - [ ] Update login endpoint to check suspension
  - [ ] Return suspension info in error response

- [ ] **Auto-lift suspension:**
  - [ ] Background job to check `suspension_end_time`
  - [ ] Set `is_suspended = False` when time expires

### Phase 6: Manual Completion + Feedback Atomic

- [ ] **Update complete endpoint:**
  - [ ] If manual complete: Require `feedback_data` in request
  - [ ] Wrap in transaction:
    ```python
    with transaction.atomic():
        request.status = 'completed'
        request.save()
        # Create feedback for all volunteers
        for volunteer_feedback in feedback_data:
            Feedback.objects.create(...)
    ```

### Phase 7: FCM Integration

- [ ] **Setup:**
  - [ ] Verify Firebase Admin SDK configured
  - [ ] Test FCM token storage on user device

- [ ] **Notification triggers:**
  - [ ] Add NotificationService calls to all workflow steps
  - [ ] Implement background tasks for async delivery
  - [ ] Add retry logic for failed deliveries

- [ ] **Testing:**
  - [ ] Test each notification type
  - [ ] Verify deep links work (open specific request)

### Phase 8: Feed Visibility Updates

- [ ] **Update queries:**
  - [ ] Exclude `auto_cancelled` from public feed
  - [ ] Exclude `expired` from public feed
  - [ ] Dynamic slot-based visibility

### Phase 9: API Endpoints to Add

- [ ] `POST /api/requests/{id}/start-anyway/` - Manual start during grace period
- [ ] `POST /api/requests/{id}/remind-feedback/` - Volunteer reminds requester
- [ ] `GET /api/users/me/suspension-status/` - Check suspension details
- [ ] `POST /api/requests/{id}/complete-with-feedback/` - Atomic completion

### Phase 10: Testing & Validation

- [ ] Unit tests for all state transitions
- [ ] Integration tests for complete workflows
- [ ] Edge case testing (race conditions, concurrent actions)
- [ ] Load testing for background jobs
- [ ] FCM notification delivery testing

---

## 📈 Success Metrics

Track these metrics to validate implementation:

| Metric | Target | Measurement |
|--------|--------|-------------|
| Auto-start success rate | >99% | Requests starting exactly at `date_needed` |
| Feedback completion rate | >90% | Feedback submitted within 24h |
| Account suspension rate | <5% | Users suspended for missing feedback |
| Race condition errors | 0 | Failed approvals due to concurrent access |
| Background job latency | <30 seconds | Time from trigger to execution |
| Notification delivery rate | >95% | FCM messages successfully delivered |

---

## 🔍 Troubleshooting Guide

### Common Issues

**Issue:** Requests not auto-starting at scheduled time
**Check:**
1. Background job running? (`ps aux | grep cron`)
2. `date_needed` timezone correct? (UTC vs local)
3. Request status still `accepted`?
4. Logs for errors in auto-start job

**Issue:** Volunteer can withdraw after request started
**Check:**
1. Request status is `in_progress`?
2. Withdrawal endpoint checking status?
3. Frontend showing correct button state?

**Issue:** Account suspended but user still logged in
**Check:**
1. Middleware installed in settings?
2. `is_suspended` flag set correctly?
3. Frontend handling 403 response?
4. Refresh token still valid? (Force logout needed)

**Issue:** Group chat not created
**Check:**
1. Request has >1 volunteer?
2. Status changed to `in_progress`?
3. Chat creation hook triggered?
4. Logs for chat creation errors

---

## 📝 Database Queries Reference

### Find requests needing auto-start:
```python
from django.utils import timezone
ServiceRequest.objects.filter(
    date_needed__lte=timezone.now(),
    status__in=['pending', 'accepted']
)
```

### Find requests needing auto-complete:
```python
from datetime import timedelta
ServiceRequest.objects.filter(
    status='in_progress',
    start_time__lte=timezone.now() - timedelta(hours=48)
)
```

### Find expired requests needing auto-cancel:
```python
ServiceRequest.objects.filter(
    status='expired',
    expired_at__lte=timezone.now() - timedelta(hours=1)
)
```

### Find requests missing feedback:
```python
from django.db.models import Count
ServiceRequest.objects.filter(
    status='completed',
    completed_at__lte=timezone.now() - timedelta(hours=72)
).annotate(
    feedback_count=Count('feedback_list')
).filter(feedback_count=0)
```

---

## 🎯 Conclusion

This workflow implements a **fair, automated, and enforceable** community service system with:

✅ **Time-based automation** - Requests start/complete automatically
✅ **Accountability** - Feedback required or face suspension
✅ **Flexibility** - Grace periods for edge cases
✅ **Real-time updates** - Push notifications keep everyone informed
✅ **Data integrity** - Atomic transactions prevent race conditions

**Status:** Ready for implementation. Start with Phase 1 (data models), then Phase 2 (background jobs).