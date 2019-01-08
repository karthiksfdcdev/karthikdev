/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class ExtrAccountLookupServiceTest {

    static testMethod void processToFindBestAccountIdEndUser() {
        
        // Create the account(s)
        Map<String, Schema.RecordTypeInfo> accountRecordTypeInfosByName = Schema.SObjectType.Account.getRecordTypeInfosByName();
        
        list<Account> lstOfEndUserActs = new list<Account>();
        
        Account endUser = new Account(
            Name = 'Marvel Comics',
            RecordTypeId = accountRecordTypeInfosByName.get(system.label.ExtrAccountLookupService_EndUser).getRecordTypeId(),
            Type = 'Active');
        lstOfEndUserActs.add(endUser); 
           
        endUser = new Account(
            Name = 'Marvel Comics',
            RecordTypeId = accountRecordTypeInfosByName.get(system.label.ExtrAccountLookupService_EndUser).getRecordTypeId(),
            Type = 'Active');                
		lstOfEndUserActs.add(endUser); 
        Account partner = new Account(
            Name = 'Partner Account',
            RecordTypeId = accountRecordTypeInfosByName.get(system.label.ExtrAccountLookupService_Partner).getRecordTypeId(),
            Type = 'Indirect Reseller',Partner_Status__c = 'Active');

        insert lstOfEndUserActs;
        
        list<ExtrAccounLookuptJSONReq.ExtrAccountIdCls> lstOfExtActs = new list<ExtrAccounLookuptJSONReq.ExtrAccountIdCls>();
        
        ExtrAccounLookuptJSONReq.ExtrAccountIdCls ExtAct = new ExtrAccounLookuptJSONReq.ExtrAccountIdCls();
        	ExtAct.Id = lstOfEndUserActs[0].Id;
        lstOfExtActs.add(ExtAct);
        
        ExtAct = new ExtrAccounLookuptJSONReq.ExtrAccountIdCls();
        	ExtAct.Id = lstOfEndUserActs[1].Id;
        lstOfExtActs.add(ExtAct);
        
        ExtrAccounLookuptJSONReq ext = new ExtrAccounLookuptJSONReq();
        ext.ExtrAccountIds = lstOfExtActs;
        
        string strJSON = JSON.serialize(ext);
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/ExtrAccountLookupService/*';  
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(strJSON);
        
        RestContext.request = req;
        RestContext.response= res;
        
        Test.startTest();
        ExtrAccountLookupService.processToFindBestAccountId();
        Test.stopTest();        
    }
    
    static testMethod void processToFindBestAccountId() {
    	RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/ExtrAccountLookupService/*';  
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof('');
        
        RestContext.request = req;
        RestContext.response= res;
        
    	ExtrAccountLookupService.processToFindBestAccountId();	
    }
    
    static testMethod void processToFindBestAccountIdPartner() {
    	// Create the account(s)
        Map<String, Schema.RecordTypeInfo> accountRecordTypeInfosByName = Schema.SObjectType.Account.getRecordTypeInfosByName();
        
        list<Account> lstOfPartnerActs = new list<Account>();
        
         
        Account partner = new Account(
            Name = 'Partner Account',
            RecordTypeId = accountRecordTypeInfosByName.get(system.label.ExtrAccountLookupService_Partner).getRecordTypeId(),
            Type = 'Indirect Reseller',Partner_Status__c = 'Active');
		lstOfPartnerActs.add(partner);
		
		partner = new Account(
            Name = 'Partner Account',
            RecordTypeId = accountRecordTypeInfosByName.get(system.label.ExtrAccountLookupService_Partner).getRecordTypeId(),
            Type = 'Indirect Reseller',Partner_Status__c = 'Active');
        lstOfPartnerActs.add(partner);   
        
        insert lstOfPartnerActs;
        
        list<ExtrAccounLookuptJSONReq.ExtrAccountIdCls> lstOfExtActs = new list<ExtrAccounLookuptJSONReq.ExtrAccountIdCls>();
        
        ExtrAccounLookuptJSONReq.ExtrAccountIdCls ExtAct = new ExtrAccounLookuptJSONReq.ExtrAccountIdCls();
        	ExtAct.Id = lstOfPartnerActs[0].Id;
        lstOfExtActs.add(ExtAct);
        
        ExtAct = new ExtrAccounLookuptJSONReq.ExtrAccountIdCls();
        	ExtAct.Id = lstOfPartnerActs[1].Id;
        lstOfExtActs.add(ExtAct);
        
        ExtrAccounLookuptJSONReq ext = new ExtrAccounLookuptJSONReq();
        ext.ExtrAccountIds = lstOfExtActs;
        
        string strJSON = JSON.serialize(ext);
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/ExtrAccountLookupService/*';  
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(strJSON);
        
        RestContext.request = req;
        RestContext.response= res;
        
        
        Test.startTest();
        ExtrAccountLookupService.processToFindBestAccountId();
        Test.stopTest(); 
    }
    
    static testMethod void processToFindBestAccountIdeEndUser2() {     	
    	// Create the account(s)
        Map<String, Schema.RecordTypeInfo> accountRecordTypeInfosByName = Schema.SObjectType.Account.getRecordTypeInfosByName();
        
        list<Account> lstOfEndUserActs = new list<Account>();
        
        Account endUser = new Account(
            Name = 'Marvel Comics',
            RecordTypeId = accountRecordTypeInfosByName.get(system.label.ExtrAccountLookupService_EndUser).getRecordTypeId(),
            Type = 'OEM');
        lstOfEndUserActs.add(endUser); 
        insert lstOfEndUserActs;
        
        list<ExtrAccounLookuptJSONReq.ExtrAccountIdCls> lstOfExtActs = new list<ExtrAccounLookuptJSONReq.ExtrAccountIdCls>();
        
        ExtrAccounLookuptJSONReq.ExtrAccountIdCls ExtAct = new ExtrAccounLookuptJSONReq.ExtrAccountIdCls();
        	ExtAct.Id = lstOfEndUserActs[0].Id;
        lstOfExtActs.add(ExtAct);
        
        ExtrAccounLookuptJSONReq ext = new ExtrAccounLookuptJSONReq();
        ext.ExtrAccountIds = lstOfExtActs;
        
        string strJSON = JSON.serialize(ext);
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/ExtrAccountLookupService/*';  
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(strJSON);
        
        RestContext.request = req;
        RestContext.response= res;
        
        Test.startTest();
        ExtrAccountLookupService.processToFindBestAccountId();
        Test.stopTest();  
    }
    
    static testMethod void processToFindBestAccountIde2() {     	
    	
        list<ExtrAccounLookuptJSONReq.ExtrAccountIdCls> lstOfExtActs = new list<ExtrAccounLookuptJSONReq.ExtrAccountIdCls>();
        
        ExtrAccounLookuptJSONReq.ExtrAccountIdCls ExtAct = new ExtrAccounLookuptJSONReq.ExtrAccountIdCls();
        	ExtAct.Id = '001ABVCDERFG';
        lstOfExtActs.add(ExtAct);
        
        ExtrAccounLookuptJSONReq ext = new ExtrAccounLookuptJSONReq();
        ext.ExtrAccountIds = lstOfExtActs;
        
        string strJSON = JSON.serialize(ext);
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/ExtrAccountLookupService/*';  
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(strJSON);
        
        RestContext.request = req;
        RestContext.response= res;
        
        Test.startTest();
        ExtrAccountLookupService.processToFindBestAccountId();
        Test.stopTest();  
    }
    
    static testMethod void processToFindBestAccountIdeEndUser3() {     	
    	// Create the account(s)
        Map<String, Schema.RecordTypeInfo> accountRecordTypeInfosByName = Schema.SObjectType.Account.getRecordTypeInfosByName();
        
        list<Account> lstOfEndUserActs = new list<Account>();
        
        Account endUser = new Account(
            Name = 'Marvel Comics',
            RecordTypeId = accountRecordTypeInfosByName.get(system.label.ExtrAccountLookupService_EndUser).getRecordTypeId(),
            Type = 'OEM');
        lstOfEndUserActs.add(endUser); 
        insert lstOfEndUserActs;
        
        list<ExtrAccounLookuptJSONReq.ExtrAccountIdCls> lstOfExtActs = new list<ExtrAccounLookuptJSONReq.ExtrAccountIdCls>();
        
        ExtrAccounLookuptJSONReq.ExtrAccountIdCls ExtAct = new ExtrAccounLookuptJSONReq.ExtrAccountIdCls();
        	ExtAct.Id = lstOfEndUserActs[0].Id;
        lstOfExtActs.add(ExtAct);
        
        ExtrAccounLookuptJSONReq ext = new ExtrAccounLookuptJSONReq();
        ext.ExtrAccountIds = lstOfExtActs;
        
        string strJSON = JSON.serialize(ext);
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/ExtrAccountLookupService/*';  
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(strJSON);
        
        RestContext.request = req;
        RestContext.response= res;
        
        Test.startTest();
        delete lstOfEndUserActs;
        ExtrAccountLookupService.processToFindBestAccountId();
        Test.stopTest();  
    }
    
    static testMethod void processToFindBestAccountIdeEndUser4() {     	
    	// Create the account(s)
        Map<String, Schema.RecordTypeInfo> accountRecordTypeInfosByName = Schema.SObjectType.Account.getRecordTypeInfosByName();
        
        list<Account> lstOfEndUserActs = new list<Account>();
        
        Account endUser = new Account(
            Name = 'Marvel Comics',
            RecordTypeId = accountRecordTypeInfosByName.get('Admin Accounts').getRecordTypeId(),
            Type = 'OEM');
        lstOfEndUserActs.add(endUser); 
        insert lstOfEndUserActs;
        
        list<ExtrAccounLookuptJSONReq.ExtrAccountIdCls> lstOfExtActs = new list<ExtrAccounLookuptJSONReq.ExtrAccountIdCls>();
        
        ExtrAccounLookuptJSONReq.ExtrAccountIdCls ExtAct = new ExtrAccounLookuptJSONReq.ExtrAccountIdCls();
        	ExtAct.Id = lstOfEndUserActs[0].Id;
        lstOfExtActs.add(ExtAct);
        
        ExtrAccounLookuptJSONReq ext = new ExtrAccounLookuptJSONReq();
        ext.ExtrAccountIds = lstOfExtActs;
        
        string strJSON = JSON.serialize(ext);
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/ExtrAccountLookupService/*';  
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(strJSON);
        
        RestContext.request = req;
        RestContext.response= res;
        
        Test.startTest();
        ExtrAccountLookupService.processToFindBestAccountId();
        Test.stopTest();  
    }
    
}