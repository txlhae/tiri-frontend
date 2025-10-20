# Location Update API Documentation

## Overview
This document describes the location update endpoints for the TIRI platform. Users can update their location information to enable location-based features such as nearby service request notifications.

---

## Endpoints

### 1. Update User Location

**Endpoint:** `POST /api/profile/update-location/`
**Method:** `POST` or `PATCH`
**Authentication:** Required (JWT Token)
**Content-Type:** `application/json`

#### Description
Updates the authenticated user's location information. This endpoint accepts GPS coordinates and optional address details.

#### Request Headers
```
Authorization: Bearer <access_token>
Content-Type: application/json
```

#### Request Body Parameters

| Parameter | Type | Required | Constraints | Description |
|-----------|------|----------|-------------|-------------|
| `latitude` | Float | Yes | -90 to 90 | GPS latitude coordinate |
| `longitude` | Float | Yes | -180 to 180 | GPS longitude coordinate |
| `address` | String | No | Max 255 chars | Full street address |
| `city` | String | No | Max 100 chars | City name |
| `state` | String | No | Max 100 chars | State/Province name |
| `postal_code` | String | No | Max 20 chars | ZIP/Postal code |

#### Example Request
```bash
curl -X POST "http://65.2.140.83:8000/api/profile/update-location/" \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..." \
  -H "Content-Type: application/json" \
  -d '{
    "latitude": 40.7128,
    "longitude": -74.0060,
    "address": "123 Main Street",
    "city": "New York",
    "state": "NY",
    "postal_code": "10001"
  }'
```

#### Success Response (200 OK)
```json
{
  "message": "Location updated successfully",
  "location": {
    "latitude": 40.7128,
    "longitude": -74.006,
    "address": "123 Main Street",
    "city": "New York",
    "state": "NY",
    "postal_code": "10001"
  }
}
```

#### Error Responses

**400 Bad Request - Missing Required Fields**
```json
{
  "location": [
    "Both latitude and longitude are required."
  ]
}
```

**400 Bad Request - Invalid Coordinates**
```json
{
  "latitude": [
    "Ensure this value is greater than or equal to -90."
  ],
  "longitude": [
    "Ensure this value is less than or equal to 180."
  ]
}
```

**401 Unauthorized**
```json
{
  "detail": "Authentication credentials were not provided."
}
```

---

### 2. Update Profile (Including Location)

**Endpoint:** `PUT/PATCH /api/profile/update/`
**Method:** `PUT` or `PATCH`
**Authentication:** Required (JWT Token)
**Content-Type:** `multipart/form-data` or `application/json`

#### Description
Updates user profile information, including location fields. This endpoint supports both profile data and file uploads.

#### Request Body Parameters (Location Fields)

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `latitude` | Float | No | GPS latitude coordinate |
| `longitude` | Float | No | GPS longitude coordinate |
| `address` | String | No | Full street address |
| `city` | String | No | City name |
| `state` | String | No | State/Province name |
| `postal_code` | String | No | ZIP/Postal code |

*(Also supports: `first_name`, `last_name`, `country`, `phone_number`, `profile_image`, `bio`, `date_of_birth`)*

#### Example Request
```bash
curl -X PATCH "http://65.2.140.83:8000/api/profile/update/" \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..." \
  -H "Content-Type: application/json" \
  -d '{
    "first_name": "John",
    "city": "New York",
    "latitude": 40.7128,
    "longitude": -74.0060
  }'
```

#### Success Response (200 OK)
Returns the full user profile with all updated fields.

---

## Integration Guide

### Frontend/Mobile Integration

#### Step 1: Request User Location Permission
```javascript
// React Native / Flutter example
const getLocation = async () => {
  const permission = await requestLocationPermission();
  if (permission === 'granted') {
    const location = await getCurrentPosition();
    return location;
  }
};
```

#### Step 2: Send Location to Backend
```javascript
const updateUserLocation = async (latitude, longitude, address) => {
  const response = await fetch('http://65.2.140.83:8000/api/profile/update-location/', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${accessToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      latitude,
      longitude,
      address: address || '',
      city: city || '',
      state: state || '',
      postal_code: postalCode || ''
    })
  });

  const data = await response.json();
  return data;
};
```

#### Step 3: Handle Reverse Geocoding (Optional)
You can use Google Maps Geocoding API or similar services to convert coordinates to addresses before sending to backend:

```javascript
const reverseGeocode = async (latitude, longitude) => {
  // Use Google Maps Geocoding API or other service
  const response = await fetch(
    `https://maps.googleapis.com/maps/api/geocode/json?latlng=${latitude},${longitude}&key=${GOOGLE_API_KEY}`
  );
  const data = await response.json();

  if (data.results && data.results.length > 0) {
    const addressComponents = data.results[0].address_components;
    return {
      address: data.results[0].formatted_address,
      city: findComponent(addressComponents, 'locality'),
      state: findComponent(addressComponents, 'administrative_area_level_1'),
      postal_code: findComponent(addressComponents, 'postal_code')
    };
  }
};
```

---

## Use Cases

### 1. User Registration/Onboarding
During user registration, prompt users to enable location services to find nearby help requests

### 2. Profile Settings
Allow users to update their location from profile settings

### 3. Background Location Updates
Periodically update user location to ensure accurate nearby notifications

---

## Important Notes

### Privacy & Permissions
- Always request location permission from users before accessing GPS
- Clearly explain why location is needed (e.g., "Find nearby help requests")
- Allow users to opt-out or update location manually

### Accuracy
- GPS coordinates should be accurate to at least 4-6 decimal places
- Use device's best location provider (GPS, Network, or Fused)
- Consider caching location updates to avoid excessive API calls

### Location-Based Features
Once location is set, users will:
- Receive notifications for service requests within 50km radius
- See distance to nearby requests
- Be discoverable by requesters in their area

---

**Last Updated:** 2025-10-20
**API Version:** 1.0
**Base URL:** http://65.2.140.83:8000
