# Booking Management System

## Overview
This repository contains the source code for the **Logistics Booking Portal**, a Salesforce Experience Cloud solution designed to allow external customers to track shipments securely.

The system enables the following core capabilities:
* **Bookings:** Represent customer deliveries and are associated with Accounts.
* **Contacts:** May manage multiple Accounts and should be able to view and track their Bookings via Experience Cloud.
* **Booking History:** Stores changes to the Booking record.
* **Notifications:** On the delivery date, all associated Contacts under the Account should be notified of the delivery and status.
## Deployment Pre-requisites
**IMPORTANT:** Before deploying this code to a new Org, you must enable the following standard feature, otherwise the `DeliveryNotificationBatch` class will fail to compile.

1.  Go to **Setup** > **Account Settings**.
2.  Check the box: **"Allow users to relate a contact to multiple accounts"**.
3.  Click **Save**.

## Key Features

### 1. User Interface (LWC)
* **Component:** `bookingManager`
* **Pattern:** Master-Detail (Split View) interface.
* **Functionality:** Custom multi-select dropdown allowing users to filter by "Status" and "Delivery Date" simultaneously.
* **Performance:** Implements lazy loading for history records and enforces `LIMIT 100` to handle large data volumes.

### 2. Automation & Audit
* **Trigger:** `BookingHistoryTrigger` (After Update)
    * Automatically creates immutable records in `Booking_History__c` whenever a Booking's Status or Date is changed.
* **Batch Apex:** `DeliveryNotificationBatch`
    * Schedulable class that runs daily (e.g., 8:00 AM).
    * Identifies bookings due `TODAY` and sends email notifications to the Primary Contact and all related Account Contacts.

### 3. Security Architecture
* **Sharing Model:** Private OWD with **Sharing Sets** (Contact.RelatedAccount → Booking.Account).
* **Permissions:** Custom Permission Set (`Portal_User_Access`) for granular object access.

---

## Repository Structure

```text
force-app/main/default/
│
├── classes/
│   ├── BookingPortalController.cls       # LWC Controller (Safe Data Retrieval)
│   └── DeliveryNotificationBatch.cls # Schedulable Batch for Emails
│
├── triggers/
│   └── BookingHistoryTrigger.trigger            # Audit Trail Logic
│
├── lwc/
│   └── bookingManager/                   # Custom Dashboard UI
│
├── objects/
│   ├── Booking__c/                       # Main Object
│   └── Booking_History__c/               # Audit Log Object
│
└── permissionsets/
    └── Portal_User_Access.permissionset-meta.xml
