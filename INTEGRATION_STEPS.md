# Quick Integration Steps

Follow these steps in order to integrate the Temporary GC feature into your application.

## ✅ Step 1: Backend Setup (5 minutes)

### 1.1 Run Database Migration

```bash
# Open MySQL Workbench or command line
# Connect to your logistic database
# Run this file:
C:\Users\IMT290\Desktop\Projects\logistic_back_v2.0\temporary_gc_migration.sql
```

### 1.2 Verify Tables Created

```sql
SHOW TABLES LIKE 'temporary_gc';
DESCRIBE temporary_gc;
DESCRIBE gc_creation;  -- Should have new columns: created_at, updated_at, created_by_user_id
```

### 1.3 Update server.js

Open: `C:\Users\IMT290\Desktop\Projects\logistic_back_v2.0\server.js`

Add this line around line 23 (with other requires):

```javascript
const temporary_gc = require('./temporary_gc');
```

Add this line around line 66 (with other app.use):

```javascript
app.use('/temporary-gc', temporary_gc);
```

### 1.4 Restart Backend

```bash
cd C:\Users\IMT290\Desktop\Projects\logistic_back_v2.0
node server.js
```

You should see: `listening : 8080`

## ✅ Step 2: Test Backend API (2 minutes)

Use Postman or browser to test:

```
GET http://localhost:8080/temporary-gc/list?companyId=your-company-id
```

Expected response:

```json
{
  "success": true,
  "data": []
}
```

If you get this, backend is working! ✅

## ✅ Step 3: Flutter Integration (3 minutes)

### 3.1 Add Routes to Your App

Find your route configuration file (usually in `main.dart` or a separate routes file).

Add these routes:

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

### 3.2 Add Navigation Button

In your main menu or dashboard, add a button to access temporary GCs:

```dart
ListTile(
  leading: Icon(Icons.description_outlined),
  title: Text('Temporary GC Forms'),
  onTap: () => Get.toNamed('/temporary-gc-list'),
),
```

### 3.3 Initialize Controller

In your main app initialization (or dashboard):

```dart
Get.put(TemporaryGCController());
```

## ✅ Step 4: Verify Admin Role (1 minute)

Make sure at least one user has admin role in database:

```sql
UPDATE profile_picture 
SET user_role = 'admin' 
WHERE userId = 1;  -- Replace 1 with your admin user ID
```

## ✅ Step 5: Test the Feature (5 minutes)

### As Admin:

1. Login as admin user
2. Navigate to "Temporary GC Forms"
3. Click "+" button
4. Fill some fields (e.g., Branch, From, To, Consignor, Consignee)
5. Click "Create Temporary GC"
6. You should see success message with temp GC number

### As Regular User:

1. Login as regular user
2. Navigate to "Temporary GC Forms"
3. You should see the temporary GC created by admin
4. Click "Fill Form"
5. Pre-filled fields should be displayed
6. Fill remaining fields
7. Submit with your GC number
8. Success! GC should be created

## 🎯 Quick Test Scenarios

### Test 1: Basic Flow

- [ ] Admin creates temporary GC
- [ ] User views temporary GC list
- [ ] User fills and submits temporary GC
- [ ] GC is created successfully

### Test 2: Locking Mechanism

- [ ] User A opens temporary GC (gets locked)
- [ ] User B tries to open same temporary GC (gets error)
- [ ] Wait 10 minutes
- [ ] User B can now open it

### Test 3: Duplicate Prevention

- [ ] User A submits with GC number "GC-001"
- [ ] User B tries to submit same temp GC with "GC-001"
- [ ] User B gets error message

### Test 4: Admin Bypass

- [ ] Create a GC (as regular user)
- [ ] Wait 25 hours (or change created_at in database)
- [ ] Try to edit as regular user (should fail)
- [ ] Try to edit as admin (should succeed)

## 🔧 Troubleshooting

### Backend not responding?

```bash
# Check if server is running
# Check server.js has the new routes
# Check console for errors
```

### Frontend errors?

```dart
// Make sure all imports are correct
// Check if controller is initialized
// Verify API URL in api_config.dart
```

### Database errors?

```sql
-- Check if tables exist
SHOW TABLES LIKE 'temporary_gc';

-- Check if columns added to gc_creation
DESCRIBE gc_creation;
```

## 📝 Configuration

### Change Lock Duration

Edit `temporary_gc.js` line ~270:

```javascript
// Change 10 to desired minutes
OR TIMESTAMPDIFF(MINUTE, locked_at, NOW()) > 10
```

### Change API Base URL

Edit `lib/api_config.dart`:

```dart
static String _baseUrl = 'http://YOUR_IP:8080';
```

## 🎉 Success Indicators

You'll know everything is working when:

- ✅ Backend starts without errors
- ✅ API endpoints respond correctly
- ✅ Admin can create temporary GCs
- ✅ Users can see and fill temporary GCs
- ✅ GCs are created with user's actual GC numbers
- ✅ Duplicate submissions are prevented
- ✅ Admin can edit GCs anytime

## 📚 Additional Resources

- Full documentation: `TEMPORARY_GC_IMPLEMENTATION.md`
- Backend setup: `C:\Users\IMT290\Desktop\Projects\logistic_back_v2.0\TEMPORARY_GC_SETUP.md`
- API reference: See "API Endpoints" section in main documentation

## 🆘 Need Help?

1. Check console logs (both backend and frontend)
2. Verify database schema
3. Test API endpoints individually
4. Review error messages carefully
5. Check user roles in database

---

**Estimated Total Setup Time: 15-20 minutes**

Good luck! 🚀
