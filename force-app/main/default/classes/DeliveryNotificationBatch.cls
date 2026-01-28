public class DeliveryNotificationBatch implements Database.Batchable<sObject>, Schedulable {

    public Database.QueryLocator start(Database.BatchableContext BC) {
        Date today = System.today();
        
        return Database.getQueryLocator([SELECT Id, Name, Status__c, Delivery_Address__c, Logistic_Company__c, Account__c, Contact__c, Contact__r.Email FROM Booking__c WHERE Delivery_Date__c = :today]);
    }

    public void execute(Database.BatchableContext BC, List<Booking__c> scope) {
        
        Set<Id> accountIds = new Set<Id>();
        for (Booking__c b : scope) {
            if (b.Account__c != null) {
                accountIds.add(b.Account__c);
            }
        }

        List<AccountContactRelation> relations = [SELECT AccountId, ContactId, Contact.Email FROM AccountContactRelation WHERE AccountId IN :accountIds AND IsActive = TRUE];

        Map<Id, List<AccountContactRelation>> accountToContactsMap = new Map<Id, List<AccountContactRelation>>();
        Set<Id> allContactIds = new Set<Id>();

        for (AccountContactRelation acr : relations) {
            if (!accountToContactsMap.containsKey(acr.AccountId)) {
                accountToContactsMap.put(acr.AccountId, new List<AccountContactRelation>());
            }
            accountToContactsMap.get(acr.AccountId).add(acr);
            allContactIds.add(acr.ContactId);
        }

        Map<Id, Id> contactToUserMap = new Map<Id, Id>();
        for (User u : [SELECT Id, ContactId FROM User WHERE ContactId IN :allContactIds AND IsActive = TRUE]) {
            contactToUserMap.put(u.ContactId, u.Id);
        }

        CustomNotificationType notificationType = [
            SELECT Id FROM CustomNotificationType 
            WHERE DeveloperName = 'Delivery_Update' 
            LIMIT 1
        ];

        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();
        
        for (Booking__c b : scope) {
            
            Set<String> emailAddresses = new Set<String>();
            Set<String> userIdsForBell = new Set<String>();

            Set<Id> contactsForBooking = new Set<Id>();

            if (b.Contact__c != null) {
                contactsForBooking.add(b.Contact__c);
                if (b.Contact__r.Email != null) emailAddresses.add(b.Contact__r.Email);
            }

            if (accountToContactsMap.containsKey(b.Account__c)) {
                for (AccountContactRelation acr : accountToContactsMap.get(b.Account__c)) {
                    contactsForBooking.add(acr.ContactId);
                    if (acr.Contact.Email != null) emailAddresses.add(acr.Contact.Email);
                }
            }

            for (Id contactId : contactsForBooking) {
                if (contactToUserMap.containsKey(contactId)) {
                    userIdsForBell.add(contactToUserMap.get(contactId));
                }
            }

            String emailSubject = 'Update: Your Delivery Arrives Today (' + b.Name + ')';
            
            String emailBody = 'Hello, <br/><br/>Your shipment is scheduled for delivery today.<br/><br/>';
            emailBody += '<b>Booking Status:</b> ' + b.Status__c + '<br/>';
            emailBody += '<b>Delivery Address:</b> ' + b.Delivery_Address__c + '<br/>';
            emailBody += '<b>Logistic Company:</b> ' + b.Logistic_Company__c + '<br/><br/>';
            emailBody += 'Please log in to the portal for more details.';

            String bellBody = 'Status: ' + b.Status__c + 
                              ' | Company: ' + b.Logistic_Company__c + 
                              ' | Addr: ' + b.Delivery_Address__c;

            if (!emailAddresses.isEmpty()) {
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setToAddresses(new List<String>(emailAddresses));
                mail.setSubject(emailSubject);
                mail.setHtmlBody(emailBody);
                mail.setSaveAsActivity(false); 
                emailsToSend.add(mail);
            }

            if (!userIdsForBell.isEmpty()) {
                Messaging.CustomNotification bell = new Messaging.CustomNotification();
                bell.setTitle('Delivery Today: ' + b.Name);
                bell.setBody(bellBody);
                bell.setNotificationTypeId(notificationType.Id);
                bell.setTargetId(b.Id);
                
                try {
                    bell.send(userIdsForBell);
                } catch (Exception e) {
                    System.debug('Error sending bell notification: ' + e.getMessage());
                }
            }
        }

        if (!emailsToSend.isEmpty()) {
            Messaging.sendEmail(emailsToSend);
        }
    }

    public void finish(Database.BatchableContext BC) {
    }

    public void execute(SchedulableContext SC) {
        Database.executeBatch(new DeliveryNotificationBatch());
    }
}