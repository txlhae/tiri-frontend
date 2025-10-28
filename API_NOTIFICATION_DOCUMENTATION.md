# Service Request Notifications API Documentation

## Overview
The `/api/requests/` endpoint has been enhanced to include notification indicators that help users identify when there are pending actions or unread messages for their service requests.

## Feature Description
When fetching service requests, each request object now includes two new fields that indicate whether the current authenticated user has pending notifications:

- **`has_pending_notifications`**: A boolean flag indicating if there are any notifications
- **`notification_count`**: The total number of pending notifications

## What Counts as a Notification?

### For Request Creators (Requesters)
1. **Pending Volunteers**: Volunteers who have applied/requested to join the service request and are awaiting approval (status = `pending`)
2. **Unread Chat Messages**: Any unread messages in chat rooms associated with this service request (where the message sender is not the requester)

### For Volunteers
1. **Unread Chat Messages**: Any unread messages in chat rooms they participate in for this service request (where the message sender is not the volunteer)

## API Endpoint

### GET `/api/requests/`

**Description**: Fetch a list of service requests with notification indicators

**Authentication**: Required (Bearer Token)

**Query Parameters**:
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `view` | string | No | Filter context: `community`, `my_requests`, or `my_volunteering` |
| `user_lat` | float | No | User's latitude for location-based filtering |
| `user_lng` | float | No | User's longitude for location-based filtering |

**Response**: 200 OK

```json
{
  "count": 1,
  "next": null,
  "previous": null,
  "results": [
    {
      "id": "e99542b8-74d7-49c1-b4c3-7682739afd60",
      "title": "test profile view",
      "description": "Need help with moving furniture",
      "category": {
        "id": 1,
        "name": "Moving & Transportation",
        "icon": "truck"
      },
      "requester": {
        "id": "6d0705b1-4f8e-4095-a1bc-0035b38072e0",
        "username": "Arifa TK",
        "email": "arifa@example.com",
        "profile_picture": "https://example.com/profile.jpg"
      },
      "latitude": 9.9312,
      "longitude": 76.2673,
      "location_display": "Kochi, 123 Main Street...",
      "address": "123 Main Street, Near City Center",
      "date_needed": "2025-10-26T09:36:00Z",
      "estimated_hours": 2.5,
      "volunteers_needed": 3,
      "volunteers_assigned_count": 1,
      "status": "pending",
      "priority": "medium",
      "created_at": "2025-10-25T16:00:00Z",
      "distance": 5.3,
      "time_until_needed": "18 hours",

      // NEW FIELDS
      "has_pending_notifications": true,
      "notification_count": 4
    }
  ]
}
```

## New Response Fields

### `has_pending_notifications`
- **Type**: `boolean`
- **Description**: Indicates whether the current user has any pending notifications for this service request
- **Values**:
  - `true`: There are pending notifications (show indicator)
  - `false`: No pending notifications (hide indicator)
- **Use Case**: Show/hide the notification dot/badge on the UI

### `notification_count`
- **Type**: `integer`
- **Description**: The total count of pending notifications
- **Range**: `0` to `n` (where n is the sum of pending volunteers + unread messages)
- **Use Case**: Display a badge with the count of notifications

## Frontend Implementation Guide

### 1. Displaying the Notification Indicator

```javascript
// Example: React/React Native component
function ServiceRequestCard({ request }) {
  return (
    <div className="request-card">
      <h3>{request.title}</h3>

      {/* Show notification badge if there are notifications */}
      {request.has_pending_notifications && (
        <div className="notification-badge">
          {request.notification_count}
        </div>
      )}

      {/* Or just show a dot indicator */}
      {request.has_pending_notifications && (
        <span className="notification-dot" />
      )}
    </div>
  );
}
```

### 2. Color Indicator Based on Notification Count

```javascript
function getNotificationColor(count) {
  if (count === 0) return 'transparent';
  if (count <= 3) return '#FFA500'; // Orange
  if (count <= 10) return '#FF6B6B'; // Red
  return '#DC143C'; // Dark Red (urgent)
}
```

### 3. Flutter/Dart Example

```dart
Widget buildRequestCard(ServiceRequest request) {
  return Card(
    child: Stack(
      children: [
        // Request content
        Column(
          children: [
            Text(request.title),
            Text(request.description),
          ],
        ),

        // Notification badge
        if (request.hasPendingNotifications)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Text(
                '${request.notificationCount}',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
      ],
    ),
  );
}
```

## Example Scenarios

### Scenario 1: Requester with Pending Volunteers
**Situation**: A requester has 2 volunteers who have applied and are waiting for approval.

**API Response**:
```json
{
  "has_pending_notifications": true,
  "notification_count": 2
}
```

**UI Display**: Show a badge with "2" indicating 2 pending volunteer requests

---

### Scenario 2: Requester with Unread Messages
**Situation**: A requester has 5 unread messages across chat rooms for this service request.

**API Response**:
```json
{
  "has_pending_notifications": true,
  "notification_count": 5
}
```

**UI Display**: Show a badge with "5" indicating 5 unread messages

---

### Scenario 3: Requester with Both
**Situation**: A requester has 2 pending volunteers + 5 unread messages.

**API Response**:
```json
{
  "has_pending_notifications": true,
  "notification_count": 7
}
```

**UI Display**: Show a badge with "7" indicating combined notifications

---

### Scenario 4: Volunteer with Unread Messages
**Situation**: A volunteer has 3 unread messages in their 1-on-1 chat with the requester.

**API Response**:
```json
{
  "has_pending_notifications": true,
  "notification_count": 3
}
```

**UI Display**: Show a badge with "3" indicating 3 unread messages

---

### Scenario 5: No Notifications
**Situation**: No pending actions or unread messages.

**API Response**:
```json
{
  "has_pending_notifications": false,
  "notification_count": 0
}
```

**UI Display**: Hide the notification indicator completely

## Implementation Notes

### Performance Considerations
- The notification counts are calculated efficiently at query time
- For large datasets, consider implementing pagination (already supported by the API)
- The backend uses optimized database queries to minimize performance impact

### Real-time Updates
- For real-time notification updates, consider implementing WebSocket connections or polling
- Current implementation provides accurate counts on each API call
- Recommended polling interval: 30-60 seconds for the requests list view

### Notification Breakdown
If you need to distinguish between notification types (pending volunteers vs unread messages), you can:

1. Check if the current user is the requester of the request
2. If yes, notification count includes both pending volunteers and unread messages
3. If no (they're a volunteer), notification count only includes unread messages

## API Call Examples

### Example 1: Fetch User's Own Requests
```bash
GET /api/requests/?view=my_requests
Authorization: Bearer <token>
```

**Response**: Returns all requests created by the user with notification indicators showing pending volunteers and unread messages.

---

### Example 2: Fetch Community Posts
```bash
GET /api/requests/?view=community
Authorization: Bearer <token>
```

**Response**: Returns community requests (not created by the user) with notification indicators showing only unread messages (since they can't have pending volunteers for others' requests).

---

### Example 3: Fetch Volunteering Requests
```bash
GET /api/requests/?view=my_volunteering
Authorization: Bearer <token>
```

**Response**: Returns requests the user has volunteered for with notification indicators showing unread messages in their chat rooms.

---

### Example 4: With Location Filtering
```bash
GET /api/requests/?view=community&user_lat=9.9312&user_lng=76.2673
Authorization: Bearer <token>
```

**Response**: Returns nearby community requests (within 50km) with notification indicators.

## Testing the API

### Using cURL

```bash
# Replace with your actual token
ACCESS_TOKEN="your-jwt-token-here"

# Fetch my requests with notifications
curl -s -X GET "http://65.2.140.83:8000/api/requests/?view=my_requests" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json"

# Fetch community posts with notifications
curl -s -X GET "http://65.2.140.83:8000/api/requests/?view=community" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json"

# Fetch volunteering requests with notifications
curl -s -X GET "http://65.2.140.83:8000/api/requests/?view=my_volunteering" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json"
```

### Using JavaScript/TypeScript

```typescript
interface ServiceRequest {
  id: string;
  title: string;
  description: string;
  status: string;
  has_pending_notifications: boolean;
  notification_count: number;
  // ... other fields
}

async function fetchRequestsWithNotifications(viewType: string): Promise<ServiceRequest[]> {
  const response = await fetch(
    `http://65.2.140.83:8000/api/requests/?view=${viewType}`,
    {
      headers: {
        'Authorization': `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
    }
  );

  const data = await response.json();
  return data.results;
}

// Usage
const myRequests = await fetchRequestsWithNotifications('my_requests');
const requestsWithNotifications = myRequests.filter(r => r.has_pending_notifications);

console.log(`You have ${requestsWithNotifications.length} requests with notifications`);
```

## Notification States

| User Role | Notification Sources | When to Show |
|-----------|---------------------|--------------|
| **Requester** | Pending volunteers + Unread messages | `has_pending_notifications: true` |
| **Volunteer** | Unread messages only | `has_pending_notifications: true` |
| **Non-participant** | N/A | `has_pending_notifications: false` |

## Best Practices

### 1. Update Notifications on User Actions
When a user performs an action (e.g., approves a volunteer, reads a message), refresh the requests list to update notification counts.

### 2. Visual Hierarchy
- Use clear visual indicators (badges, dots, colors)
- Make notifications prominent but not overwhelming
- Consider using different colors for different urgency levels

### 3. User Experience
- Clear the notification indicator when the user navigates to the request detail page
- Show what type of notifications exist (e.g., "2 pending volunteers, 3 messages")
- Provide quick actions to address notifications

### 4. Accessibility
- Ensure notification badges have sufficient color contrast
- Provide text alternatives for screen readers
- Use ARIA labels for notification counts

## FAQ

### Q: Are the notification counts real-time?
**A**: The counts are accurate as of the API call time. For real-time updates, implement polling or WebSocket connections.

### Q: What happens if I have both pending volunteers and unread messages?
**A**: The `notification_count` will be the sum of both. The frontend doesn't need to distinguish between them for the badge display.

### Q: Can I get separate counts for volunteers vs messages?
**A**: Currently, the API returns a combined count. If you need separate counts, you can make additional API calls to the volunteer and chat endpoints, or request a backend enhancement.

### Q: Does the notification count affect API performance?
**A**: The queries are optimized and should have minimal performance impact. The backend uses efficient database queries with proper indexing.

### Q: What if I want to show different indicators for different notification types?
**A**: You can infer the notification type based on the user's role:
  - If the user is the requester, notifications could be either or both types
  - If the user is a volunteer, notifications are only unread messages
  - Consider fetching request details to get more specific information

## Support

For questions or issues related to this API:
- Backend Repository: [Link to your repo]
- Contact: [Your contact information]
- API Version: 1.0
- Last Updated: October 26, 2025
