# 📱 Temporary GC Feature - Visual Guide

## 🎯 Quick Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    TEMPORARY GC WORKFLOW                     │
└─────────────────────────────────────────────────────────────┘

ADMIN CREATES TEMPLATE          USER FILLS TEMPLATE
        ↓                              ↓
┌───────────────────┐          ┌───────────────────┐
│  Partially Filled │          │  Complete Form    │
│  GC Template      │   →→→    │  with User's      │
│  (TEMP-XXX-XXX)   │          │  GC Number        │
└───────────────────┘          └───────────────────┘
        ↓                              ↓
┌───────────────────┐          ┌───────────────────┐
│  Stored in DB     │          │  Locked for       │
│  Available to All │          │  10 Minutes       │
└───────────────────┘          └───────────────────┘
                                       ↓
                               ┌───────────────────┐
                               │  Converted to     │
                               │  Actual GC        │
                               │  (GC-2024-001)    │
                               └───────────────────┘
```

---

## 🏠 Home Page - New Button

```
┌────────────────────────────────────────────────────────┐
│  Logistics GC - Home                                    │
├────────────────────────────────────────────────────────┤
│                                                         │
│  Quick Actions                          [View All ▼]   │
│                                                         │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐            │
│  │ New GC   │  │ GC List  │  │ Update   │            │
│  │ Note     │  │          │  │ Transit  │            │
│  └──────────┘  └──────────┘  └──────────┘            │
│                                                         │
│  ┌──────────────────────────────────────┐  ← NEW!     │
│  │  📄 Temporary GC                     │             │
│  │  Quick fill forms                    │             │
│  └──────────────────────────────────────┘             │
│                                                         │
└────────────────────────────────────────────────────────┘
```

---

## 📋 Temporary GC List Screen

```
┌────────────────────────────────────────────────────────┐
│  ← Temporary GC Forms                    [+] [↻]       │
├────────────────────────────────────────────────────────┤
│                                                         │
│  ┌──────────────────────────────────────────────────┐ │
│  │  TEMP-ABC123-XYZ                    [In Use 🔒]  │ │
│  │                                                   │ │
│  │  📍 Mumbai → Delhi                               │ │
│  │  🏢 From: ABC Company                            │ │
│  │  🏢 To: XYZ Company                              │ │
│  │                                                   │ │
│  │  [Main Branch] [20ft Container]                  │ │
│  │                                                   │ │
│  │  ⏰ Created: Oct 24, 2025, 4:30 PM               │ │
│  │                                      [Fill Form]  │ │
│  └──────────────────────────────────────────────────┘ │
│                                                         │
│  ┌──────────────────────────────────────────────────┐ │
│  │  TEMP-DEF456-ABC                                 │ │
│  │                                                   │ │
│  │  📍 Chennai → Bangalore                          │ │
│  │  🏢 From: PQR Company                            │ │
│  │  🏢 To: LMN Company                              │ │
│  │                                                   │ │
│  │  [South Branch] [10ft Container]                 │ │
│  │                                                   │ │
│  │  ⏰ Created: Oct 24, 2025, 3:15 PM               │ │
│  │                                      [Fill Form]  │ │
│  └──────────────────────────────────────────────────┘ │
│                                                         │
└────────────────────────────────────────────────────────┘
```

---

## ➕ Create Temporary GC Screen (Admin Only)

```
┌────────────────────────────────────────────────────────┐
│  ← Create Temporary GC                          [💾]   │
├────────────────────────────────────────────────────────┤
│                                                         │
│  ℹ️ Fill in the fields you want to pre-populate.      │
│     Users will complete the remaining fields.          │
│                                                         │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  │
│                                                         │
│  ℹ️ Basic Information                                  │
│                                                         │
│  Branch:        [Main Branch ▼]                        │
│  Truck Type:    [20ft Container]                       │
│  PO Number:     [PO-2024-001]                          │
│                                                         │
│  🚚 Route Details                                      │
│                                                         │
│  From Location: [Mumbai]                               │
│  To Location:   [Delhi]                                │
│                                                         │
│  🏢 Party Details                                      │
│                                                         │
│  Broker:        [Select Broker ▼]                      │
│  Consignor:     [ABC Company ▼]                        │
│  Consignee:     [XYZ Company ▼]                        │
│                                                         │
│  📦 Goods Details                                      │
│                                                         │
│  Description:   [Electronics]                          │
│  No. of Pkgs:   [50]        Method: [Boxes]           │
│                                                         │
│  💰 Financial Details                                  │
│                                                         │
│  Freight:       [₹ 50000]                              │
│  Advance:       [₹ 20000]                              │
│                                                         │
│  ┌──────────────────────────────────────────────────┐ │
│  │        [💾 Create Temporary GC]                  │ │
│  └──────────────────────────────────────────────────┘ │
│                                                         │
└────────────────────────────────────────────────────────┘
```

---

## 🔄 User Flow Diagram

```
USER OPENS APP
     │
     ├─→ Clicks "Temporary GC" on Home
     │
     ├─→ Sees List of Templates
     │
     ├─→ Clicks "Fill Form" on Template
     │
     ├─→ System Locks Template (10 min)
     │
     ├─→ Pre-filled Fields Displayed
     │
     ├─→ User Fills Remaining Fields
     │
     ├─→ User Enters Their GC Number
     │
     ├─→ Submits Form
     │
     ├─→ System Checks:
     │   ├─ Is GC Number Unique? ✓
     │   ├─ Is User Still Locked? ✓
     │   └─ All Required Fields? ✓
     │
     ├─→ Creates Actual GC
     │
     └─→ Success! ✅
```

---

## 🔒 Locking Mechanism

```
┌─────────────────────────────────────────────────────┐
│  SCENARIO: Two Users Try Same Template              │
└─────────────────────────────────────────────────────┘

TIME: 10:00 AM
┌─────────────┐                    ┌─────────────┐
│  User A     │                    │  User B     │
│  Clicks     │                    │  Waiting    │
│  "Fill Form"│                    │             │
└─────────────┘                    └─────────────┘
      │                                   │
      ├─→ Template LOCKED ✓              │
      │   for User A                     │
      │                                   │
      │                                   ├─→ Clicks "Fill Form"
      │                                   │
      │                                   ├─→ ❌ ERROR:
      │                                   │   "Being edited by
      │                                   │    another user"
      │                                   │
      ├─→ User A Fills Form              │
      │                                   │
      ├─→ Submits with GC-001 ✓          │
      │                                   │
      │                                   │
TIME: 10:10 AM (Lock Expires)            │
      │                                   │
      │                                   ├─→ Tries Again ✓
      │                                   │
      │                                   ├─→ Template LOCKED
      │                                   │   for User B
      │                                   │
      │                                   ├─→ Fills Form
      │                                   │
      │                                   ├─→ Submits with GC-002 ✓
      │                                   │
      ✓ Both Successful!                 ✓
```

---

## 🎨 Color Scheme

```
Primary Actions:     🔵 Blue (#4A90E2)
Success Messages:    🟢 Green (#34A853)
Warning/Lock:        🟠 Orange (#FF6F00)
Error Messages:      🔴 Red (#EA4335)
Admin Features:      🟣 Purple (#8E24AA)
Background:          ⚪ Light Gray (#F7F9FC)
Text:                ⚫ Dark Blue (#1E2A44)
```

---

## 📱 Screen Flow

```
┌─────────────┐
│  Home Page  │
└──────┬──────┘
       │
       ├─→ Click "Temporary GC"
       │
       ▼
┌──────────────────┐
│  Temp GC List    │
│  Screen          │
└────┬────────┬────┘
     │        │
     │        └─→ [+] Button (Admin Only)
     │            │
     │            ▼
     │        ┌──────────────────┐
     │        │  Create Temp GC  │
     │        │  Screen          │
     │        └──────────────────┘
     │
     └─→ Click "Fill Form"
         │
         ▼
     ┌──────────────────┐
     │  GC Form Screen  │
     │  (Pre-filled)    │
     └──────────────────┘
```

---

## 🎯 Success Indicators

```
✅ Backend Running:
   └─→ Console shows: "listening : 8080"

✅ Database Ready:
   └─→ Tables exist: temporary_gc, gc_creation

✅ Admin Set:
   └─→ user_role = 'admin' in database

✅ Frontend Running:
   └─→ "Temporary GC" button visible on home

✅ Feature Working:
   └─→ Can create and fill templates
```

---

## 🚀 READY TO USE!

Everything is visual, intuitive, and ready to go!

Just complete the 3 setup steps and enjoy! 🎉
