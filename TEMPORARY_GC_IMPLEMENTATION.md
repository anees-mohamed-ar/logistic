# Temporary GC Feature - Complete Implementation Guide

## Overview
This feature allows admins to create partially filled temporary GC forms that users can complete with their own GC numbers. It includes robust locking mechanisms to prevent concurrent editing conflicts and admin bypass for 24-hour edit restrictions.

## Features Implemented

### 1. **Temporary GC Creation (Admin Only)**
- Admins can create partially filled GC templates
- System generates unique temporary GC numbers (format: `TEMP-XXXXX-XXXXX`)
- All GC fields are supported for pre-filling

### 2. **Locking Mechanism**
- Automatic locking when a user opens a temporary GC
- Lock duration: 10 minutes
- Prevents concurrent editing by multiple users
- Automatic lock expiration
- Manual unlock capability

### 3. **GC Conversion**
- Users fill remaining fields
- System replaces temporary GC number with user's actual GC number
- Duplicate GC number detection
- Transaction-based for data integrity
- Conflict resolution (first-come-first-served)

### 4. **Admin Bypass for 24-Hour Edit Restriction**
- Regular users: Can only edit GC within 24 hours of creation
- Admins: Can edit GC anytime (no time restriction)
- Automatic role-based permission checking

## Files Created

### Backend (C:\Users\IMT290\Desktop\Projects\logistic_back_v2.0)
1. **temporary_gc.js** - Complete API implementation
2. **temporary_gc_migration.sql** - Database schema
3. **TEMPORARY_GC_SETUP.md** - Backend setup instructions

### Frontend (c:\Users\IMT290\StudioProjects\Logistic)
1. **lib/models/temporary_gc.dart** - Data model
2. **lib/controller/temporary_gc_controller.dart** - Business logic
3. **lib/screens/temporary_gc_list_screen.dart** - User view screen
4. **lib/screens/create_temporary_gc_screen.dart** - Admin create screen

## Setup Instructions

### Step 1: Backend Setup

1. **Run Database Migration**
   ```bash
   # Navigate to backend folder
   cd C:\Users\IMT290\Desktop\Projects\logistic_back_v2.0
   
   # Open MySQL and run the migration
   mysql -u root -p logistic < temporary_gc_migration.sql
   ```

2. **Update server.js**
   Add these lines to your `server.js`:
   ```javascript
   // Add with other requires (around line 23)
   const temporary_gc = require('./temporary_gc');
   
   // Add with other app.use statements (around line 66)
   app.use('/temporary-gc', temporary_gc);
   ```

3. **Restart Backend Server**
   ```bash
   node server.js
   ```

### Step 2: Flutter Setup

1. **Add Routes** (if using named routes)
   Add to your route configuration:
   ```dart
   GetPage(
     name: '/temporary-gc-list',
     page: () => const TemporaryGCListScreen(),
   ),
   GetPage(
     name: '/create-temporary-gc',
     page: () => const CreateTemporaryGCScreen(),
   ),
   ```

2. **Initialize Controller**
   In your main app or dashboard, initialize the controller:
   ```dart
   Get.put(TemporaryGCController());
   ```

3. **Add Navigation**
   Add a button/menu item to navigate to temporary GC list:
   ```dart
   ElevatedButton(
     onPressed: () => Get.toNamed('/temporary-gc-list'),
     child: Text('Temporary GC Forms'),
   ),
   ```

## API Endpoints

### 1. Create Temporary GC (Admin Only)
```
POST /temporary-gc/create
Body: {
  "userId": 1,
  "CompanyId": "company-id",
  "Branch": "Main Branch",
  "TruckFrom": "Mumbai",
  "TruckTo": "Delhi",
  ... (any GC fields)
}
Response: {
  "success": true,
  "message": "Temporary GC created successfully",
  "data": {
    "id": 1,
    "temp_gc_number": "TEMP-XXXXX-XXXXX"
  }
}
```

### 2. List Available Temporary GCs
```
GET /temporary-gc/list?companyId=company-id
Response: {
  "success": true,
  "data": [...]
}
```

### 3. Get Single Temporary GC
```
GET /temporary-gc/get/:tempGcNumber
Response: {
  "success": true,
  "data": {...}
}
```

### 4. Lock Temporary GC
```
POST /temporary-gc/lock/:tempGcNumber
Body: {
  "userId": 2
}
Response: {
  "success": true,
  "message": "Temporary GC locked successfully"
}
```

### 5. Unlock Temporary GC
```
POST /temporary-gc/unlock/:tempGcNumber
Body: {
  "userId": 2
}
```

### 6. Convert to Actual GC
```
POST /temporary-gc/convert/:tempGcNumber
Body: {
  "userId": 2,
  "actualGcNumber": "GC-2024-001",
  "DriverName": "John Doe",
  "DriverPhoneNumber": "9876543210",
  ... (additional fields to fill)
}
Response: {
  "success": true,
  "message": "Temporary GC converted to actual GC successfully",
  "data": {
    "gc_number": "GC-2024-001",
    "gc_id": 123
  }
}
```

### 7. Update Temporary GC (Admin Only)
```
PUT /temporary-gc/update/:tempGcNumber
Body: {
  "userId": 1,
  ... (fields to update)
}
```

### 8. Delete Temporary GC (Admin Only)
```
DELETE /temporary-gc/delete/:tempGcNumber
Body: {
  "userId": 1
}
```

### 9. Check Edit Permission (Admin Bypass)
```
GET /temporary-gc/can-edit/:gcNumber?companyId=xxx&userId=xxx
Response: {
  "success": true,
  "canEdit": true,
  "isAdmin": true
}
```

## User Flow

### For Admins:
1. Navigate to Temporary GC List screen
2. Click "+" button to create new temporary GC
3. Fill in fields that should be pre-populated
4. Save as temporary GC
5. System generates unique temporary GC number
6. Users can now see and fill this template

### For Regular Users:
1. Navigate to Temporary GC List screen
2. View available temporary GC forms
3. Click "Fill Form" on desired template
4. System locks the temporary GC (10 minutes)
5. Pre-filled fields are displayed
6. Fill remaining fields
7. Submit with their actual GC number
8. System converts temporary GC to actual GC
9. If GC number already exists, user gets error message

## Conflict Resolution

### Scenario: Two users try to fill the same temporary GC

1. **User A** clicks "Fill Form" → System locks temporary GC for User A
2. **User B** clicks "Fill Form" → Gets error: "This temporary GC is currently being edited by another user"
3. **User A** submits with GC number "GC-001" → Success
4. **User B** waits 10 minutes for lock to expire, then tries again
5. **User B** submits with GC number "GC-002" → Success (different GC number)

### Scenario: Two users submit with same GC number

1. **User A** submits with GC number "GC-001" → Success
2. **User B** submits with GC number "GC-001" → Error: "This GC number already exists. Another user may have filled this temporary GC."

## Database Schema

### temporary_gc Table
```sql
- id (PK, AUTO_INCREMENT)
- temp_gc_number (UNIQUE)
- created_by_user_id
- created_at
- is_locked (0/1)
- locked_by_user_id
- locked_at
- is_converted (0/1)
- converted_gc_number
- converted_by_user_id
- converted_at
- [All GC form fields...]
- CompanyId
```

### gc_creation Table (Modified)
```sql
- [Existing fields...]
- created_at (NEW)
- updated_at (NEW)
- created_by_user_id (NEW)
```

## Security Features

1. **Role-Based Access Control**
   - Only admins can create/update/delete temporary GCs
   - Regular users can only view and convert
   - Automatic role verification on every request

2. **Concurrency Control**
   - Locking mechanism prevents race conditions
   - 10-minute lock timeout
   - Transaction-based conversion

3. **Data Validation**
   - User ID required for all operations
   - Company ID validation
   - GC number uniqueness check
   - Lock ownership verification

4. **Admin Privileges**
   - Bypass 24-hour edit restriction
   - Full CRUD operations on temporary GCs
   - View all temporary GCs across company

## Error Handling

| Status Code | Meaning | Example |
|-------------|---------|---------|
| 200 | Success | Operation completed successfully |
| 201 | Created | Temporary GC created |
| 400 | Bad Request | Missing required parameters |
| 403 | Forbidden | User is not admin |
| 404 | Not Found | Temporary GC doesn't exist |
| 409 | Conflict | GC number already exists |
| 423 | Locked | Being edited by another user |
| 500 | Server Error | Database or server error |

## Testing Checklist

### Backend Testing
- [ ] Run database migration successfully
- [ ] Server starts without errors
- [ ] All endpoints respond correctly
- [ ] Admin role check works
- [ ] Locking mechanism functions properly
- [ ] GC number uniqueness validation works
- [ ] Transaction rollback on errors

### Frontend Testing
- [ ] Temporary GC list loads correctly
- [ ] Admin can create temporary GC
- [ ] Users can view temporary GCs
- [ ] Lock mechanism prevents concurrent editing
- [ ] GC conversion works correctly
- [ ] Error messages display properly
- [ ] Admin bypass for 24-hour restriction works

### Integration Testing
- [ ] End-to-end flow: Admin creates → User fills → GC created
- [ ] Concurrent user scenario
- [ ] Duplicate GC number scenario
- [ ] Lock timeout scenario
- [ ] Admin edit after 24 hours

## Troubleshooting

### Issue: "Temporary GC not found"
- **Cause**: Temporary GC was already converted or deleted
- **Solution**: Refresh the list and select another temporary GC

### Issue: "This temporary GC is currently being edited by another user"
- **Cause**: Another user has locked the temporary GC
- **Solution**: Wait 10 minutes for lock to expire or choose another template

### Issue: "This GC number already exists"
- **Cause**: Another user submitted the same temporary GC first
- **Solution**: This is expected behavior. The first user's submission wins.

### Issue: "Only admins can create temporary GCs"
- **Cause**: User role is not set to 'admin' in database
- **Solution**: Update user_role in profile_picture table

### Issue: Backend API not responding
- **Cause**: Server not updated with new routes
- **Solution**: Check server.js has temporary_gc routes added and restart server

## Future Enhancements

1. **Email Notifications**
   - Notify users when new temporary GCs are available
   - Alert when lock is about to expire

2. **Template Management**
   - Save frequently used templates
   - Template categories

3. **Audit Trail**
   - Track who viewed/edited temporary GCs
   - Detailed conversion history

4. **Bulk Operations**
   - Create multiple temporary GCs at once
   - Batch conversion

5. **Advanced Locking**
   - Configurable lock duration
   - Force unlock by admin
   - Lock extension

## Support

For issues or questions:
1. Check this documentation
2. Review backend logs: `console.log` statements in temporary_gc.js
3. Check Flutter console for frontend errors
4. Verify database schema matches migration file

## Version History

- **v1.0.0** (2025-01-24)
  - Initial implementation
  - Basic CRUD operations
  - Locking mechanism
  - Admin bypass for 24-hour restriction
  - Complete Flutter UI
