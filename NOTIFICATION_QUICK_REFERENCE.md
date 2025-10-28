# Notification API - Quick Reference

## 🎯 What's New

The `/api/requests/` endpoint now includes notification indicators:

```json
{
  "has_pending_notifications": true,
  "notification_count": 5
}
```

## 📊 Notification Logic

### For Requesters (My Posts)
```
notification_count = pending_volunteers + unread_messages
```

### For Volunteers (My Volunteering)
```
notification_count = unread_messages
```

## 🔌 API Endpoint

```bash
GET /api/requests/?view={community|my_requests|my_volunteering}
Authorization: Bearer <token>
```

## 📱 Frontend Implementation

### React/React Native
```jsx
{request.has_pending_notifications && (
  <Badge count={request.notification_count} />
)}
```

### Flutter
```dart
if (request.hasPendingNotifications)
  Badge(
    label: Text('${request.notificationCount}'),
    child: Icon(Icons.notifications),
  )
```

## 🧪 Test It

```bash
ACCESS_TOKEN="your-token"

# My requests (shows pending volunteers + unread messages)
curl -X GET "http://65.2.140.83:8000/api/requests/?view=my_requests" \
  -H "Authorization: Bearer $ACCESS_TOKEN"

# My volunteering (shows only unread messages)
curl -X GET "http://65.2.140.83:8000/api/requests/?view=my_volunteering" \
  -H "Authorization: Bearer $ACCESS_TOKEN"
```

## 📋 Example Response

```json
{
  "count": 2,
  "results": [
    {
      "id": "uuid-1",
      "title": "Need help moving",
      "status": "pending",
      "has_pending_notifications": true,
      "notification_count": 3,
      // ... other fields
    },
    {
      "id": "uuid-2",
      "title": "Grocery shopping",
      "status": "accepted",
      "has_pending_notifications": false,
      "notification_count": 0,
      // ... other fields
    }
  ]
}
```

## ✅ What Counts as a Notification?

| Notification Type | For Requester | For Volunteer |
|-------------------|---------------|---------------|
| Pending volunteers awaiting approval | ✅ Yes | ❌ No |
| Unread chat messages | ✅ Yes | ✅ Yes |

## 🎨 UI Examples

### Simple Dot Indicator
Show a red dot when `has_pending_notifications` is true

### Badge with Count
Show a badge with `notification_count` value

### Color Coding
- 0 notifications: No indicator
- 1-3 notifications: Orange
- 4-10 notifications: Red
- 11+ notifications: Dark Red

## 💡 Best Practices

1. **Polling**: Refresh every 30-60 seconds
2. **Clear on View**: Mark as read when user opens the request
3. **Visual Feedback**: Use clear, contrasting colors
4. **Accessibility**: Add ARIA labels for screen readers

## 📞 Need Help?

See full documentation: `API_NOTIFICATION_DOCUMENTATION.md`
