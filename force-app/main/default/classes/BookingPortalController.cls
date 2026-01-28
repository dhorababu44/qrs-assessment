public with sharing class BookingPortalController {
 
    @AuraEnabled(cacheable=true)
    public static List<Booking__c> getBookings(List<String> statuses, Date deliveryDate) {
        String query = 'SELECT Id, Name, Status__c, Delivery_Date__c, Logistic_Company__c, Delivery_Address__c ' + 'FROM Booking__c WHERE Id != null';
        
        if (statuses != null && !statuses.isEmpty()) {
            query += ' AND Status__c IN :statuses';
        }
 
        if (deliveryDate != null) {
            query += ' AND Delivery_Date__c = :deliveryDate';
        }
        
        query += ' ORDER BY CreatedDate DESC LIMIT 100';
        
        return Database.query(query);
    }
 
    @AuraEnabled(cacheable=true)
    public static List<Booking_History__c> getBookingHistory(Id bookingId) {
        return [SELECT Id, Field_Changed__c, Old_Value__c, New_Value__c, Change_Date__c, Changed_By__r.Name FROM Booking_History__c WHERE Booking__c = :bookingId ORDER BY Change_Date__c DESC];
    }
}