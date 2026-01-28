trigger BookingHistoryTrigger on Booking__c (after update) {
    List<Booking_History__c> historyRecordsToInsert = new List<Booking_History__c>();
        for (Booking__c newBooking : Trigger.new) {
                Booking__c oldBooking = Trigger.oldMap.get(newBooking.Id);
                if (newBooking.Status__c != oldBooking.Status__c) {
                Booking_History__c history = new Booking_History__c();
                history.Booking__c = newBooking.Id;              
                history.Change_Date__c = System.now();           
                history.Changed_By__c = UserInfo.getUserId();    
                history.Field_Changed__c = 'Status';             
                history.Old_Value__c = oldBooking.Status__c;     
                history.New_Value__c = newBooking.Status__c;     
                
                historyRecordsToInsert.add(history); 
        }
        
        if (newBooking.Delivery_Date__c != oldBooking.Delivery_Date__c) {
            Booking_History__c history = new Booking_History__c();
            history.Booking__c = newBooking.Id;
            history.Change_Date__c = System.now();
            history.Changed_By__c = UserInfo.getUserId();
            history.Field_Changed__c = 'Delivery Date';
            history.Old_Value__c = String.valueOf(oldBooking.Delivery_Date__c);
            history.New_Value__c = String.valueOf(newBooking.Delivery_Date__c);
            
            historyRecordsToInsert.add(history);
        }
    }
    if (!historyRecordsToInsert.isEmpty()) {
        insert historyRecordsToInsert;
    }
}