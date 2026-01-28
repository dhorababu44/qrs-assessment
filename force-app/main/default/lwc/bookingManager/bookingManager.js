import { LightningElement, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import getBookings from '@salesforce/apex/BookingPortalController.getBookings';
import getBookingHistory from '@salesforce/apex/BookingPortalController.getBookingHistory';
import BOOKING_OBJECT from '@salesforce/schema/Booking__c';
import STATUS_FIELD from '@salesforce/schema/Booking__c.Status__c';
 
const BOOKING_COLS = [
    { label: 'Booking Name', fieldName: 'Name', type: 'text' },
    { label: 'Status', fieldName: 'Status__c', type: 'text' },
    { label: 'Delivery Date', fieldName: 'Delivery_Date__c', type: 'date-local' },
    { label: 'Address', fieldName: 'Delivery_Address__c', type: 'text' },
    { label: 'Logistic Co.', fieldName: 'Logistic_Company__c', type: 'text' }
];
 
const HISTORY_COLS = [
    { label: 'Date Changed', fieldName: 'Change_Date__c', type: 'date', 
      typeAttributes: { day: 'numeric', month: 'short', hour: '2-digit', minute: '2-digit' }},
    { label: 'Field', fieldName: 'Field_Changed__c', type: 'text' },
    { label: 'Old Value', fieldName: 'Old_Value__c', type: 'text' },
    { label: 'New Value', fieldName: 'New_Value__c', type: 'text' }
];
 
export default class BookingManager extends NavigationMixin(LightningElement) {
    
    @track selectedStatuses = [];
    @track dateFilter = null;
    @track statusOptions = [];
    @track isDropdownOpen = false;
    @track bookings;
    @track historyRecords;
    @track selectedBookingId;
    @track selectedBookingName;
    
    bookingColumns = BOOKING_COLS;
    historyColumns = HISTORY_COLS;
 
    @wire(getObjectInfo, { objectApiName: BOOKING_OBJECT })
    objectInfo;
 
    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: STATUS_FIELD })
    wiredPicklists({ error, data }) {
        if (data) {
            this.statusOptions = data.values.map(plValue => {
                return { label: plValue.label, value: plValue.value };
            });
        }
    }
 
    @wire(getBookings, { statuses: '$selectedStatuses', deliveryDate: '$dateFilter' })
    wiredBookings({ error, data }) {
        if (data) {
            this.bookings = data;
        } else if (error) {
            console.error('Error:', error);
        }
    }
 
    @wire(getBookingHistory, { bookingId: '$selectedBookingId' })
    wiredHistory({ error, data }) {
        if (data) {
            this.historyRecords = data;
        }
    }
  
    toggleDropdown() {
        this.isDropdownOpen = !this.isDropdownOpen;
    }
 
    closeDropdown() {
        this.isDropdownOpen = false;
    }
 
    handleStatusChange(event) {
        this.selectedStatuses = event.detail.value;
    }
 
    handleDateChange(event) {
        this.dateFilter = event.target.value;
    }
 
    handleClear() {
        this.selectedStatuses = [];
        this.dateFilter = null;
        this.selectedBookingId = null;
        this.isDropdownOpen = false;
    }
 
    handleRowSelection(event) {
        const selectedRows = event.detail.selectedRows;
        if (selectedRows.length > 0) {
            this.selectedBookingId = selectedRows[0].Id;
            this.selectedBookingName = selectedRows[0].Name;
        } else {
            this.selectedBookingId = null;
        }
    }
 
    handleCreateNew() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Booking__c',
                actionName: 'new'
            }
        });
    }
 
    get dropdownClass() {
        return this.isDropdownOpen 
            ? 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-is-open' 
            : 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
    }
}