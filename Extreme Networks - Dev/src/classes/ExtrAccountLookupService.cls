/**
* Class Name : ExtrAccountLookupService
* Purpose    : To find the best Account from the request received from Web Methods
* Author     : Karthik Kasapa
* Date       : 11/20/2018
* Invoked by : Web Methods
*/

@RestResource(urlMapping='/ExtrAccountLookupService/*')
global class ExtrAccountLookupService {
    
    /**
    * Purpose   : This Http Post method and this will find the Best account
    * Parameters: - 
    * Return    : string
    */
    @HttpPost
    global static String processToFindBestAccountId() {
        RestRequest req = RestContext.request; // Getting REST API request 
        string strJSONReq  = req.requestBody.toString(); // Assign the request to string
        try{
            ExtrAccounLookuptJSONReq ExtrActSrvcObj =  (ExtrAccounLookuptJSONReq)System.JSON.deserialize(strJSONReq, ExtrAccounLookuptJSONReq.class); // Parsing requet into Apex object
            list<Id> lstOfIntialActIds = new list<Id>();
            set<Id> setOfActIds = new set<Id>();
            if(ExtrActSrvcObj != null && ExtrActSrvcObj.ExtrAccountIds != null){ // Checking if IDs availble in the request or not 
                if(ExtrActSrvcObj.ExtrAccountIds.Size() > 0){
                    try{
                        for(ExtrAccounLookuptJSONReq.ExtrAccountIdCls actId : ExtrActSrvcObj.ExtrAccountIds){ // Looping the IDs from Requesdt
                            if(actId != null && actId.Id != null && actId.Id.trim() != ''){
                                lstOfIntialActIds.add(Id.valueOf(actId.Id.trim())); // Adding IDs into the list which it will be usefull identifying the order of Ids
                                setOfActIds.add(Id.valueOf(actId.Id.trim())); // This set is for Querying the records from Account object
                            }    
                        }
                    }catch(Exception Ex){ // This is for if any invalid id found in request
                        new ExtrIntegrationLog().createExtremeIntegrationLog(
                            new ExtrIntegrationLog.ErrorLog(
                                'ExtrAccountLookupServiceCls', 
                                'Web Methods Integration', 
                                null, 
                                Ex    
                            )
                        );  
                        return prepareFailureResponse('Invalid request.');      
                    }
                }    
            }
            
            if(!lstOfIntialActIds.isEmpty()){ // To check if Ids availble in request or not 
                list<Account> lstOfExiActs = [SELECT Id,Name,RecordType.Name,Type,Partner_Status__c,IsCustomerPortal,createdDate FROM Account WHERE ID IN:setOfActIds order by createdDate asc]; // Querying the records from SFDC Database  
                list<Account> lstOfPartners = new list<Account>();
                list<Account> lstOfEnduser = new list<Account>();
                if(!lstOfExiActs.isEmpty()){
                    for(Account actObj : lstOfExiActs){ // Looping the SFDC records and separating the records with Record Type
                        if(actObj.RecordType.Name == system.label.ExtrAccountLookupService_Partner){
                            lstOfPartners.add(actObj);   // Adding the Partner Records into the list 
                        }else if(actObj.RecordType.Name == system.label.ExtrAccountLookupService_EndUser){
                            lstOfEnduser.add(actObj);  // Adding the End user Records into the list    
                        }        
                    }
                    if(!lstOfPartners.isEmpty()){ // If at least one Partenr Record availble enter into this block
                        map<string,list<Account>> mapOfStatusWithActs = new map<string,list<Account>>();
                        for(Account actObj : lstOfPartners){ // Looping the Partner REcords 
                            if(actObj.Partner_Status__c != null && (actObj.Partner_Status__c == 'Active' || actObj.Partner_Status__c == 'Inactive' || actObj.Partner_Status__c == 'Potential')){ // Checking the Status not null and status either Active;Inactvie;Potential
                                // Prepare the map with Key as status and value as list of Acct records
                                list<Account> lstOfTempActs;
                                if(mapOfStatusWithActs.ContainsKey(actObj.Partner_Status__c)){
                                    lstOfTempActs = mapOfStatusWithActs.get(actObj.Partner_Status__c);
                                }else{
                                    lstOfTempActs = new list<Account>();    
                                }
                                lstOfTempActs.add(actObj);
                                mapOfStatusWithActs.put(actObj.Partner_Status__c,lstOfTempActs);
                            } 
                        }
                        if(!mapOfStatusWithActs.isEmpty()){ // If records found with Status
                            list<string> lstWithActStatus = new list<string>{'Active', 'Inactive', 'Potential'};
                            for(string strStatus : lstWithActStatus){ // Looping the Status Order and process the Best record
                                if(mapOfStatusWithActs.get(strStatus) != null){
                                    return processActs(mapOfStatusWithActs.get(strStatus),lstOfIntialActIds);   // Common method to return best Account
                                }                                   
                            }   
                        }else{ // If no records found with status then create integration objcect and return null
                            return prepareResponse('Partner Account is missing Status');        
                        }    
                    }else if(!lstOfEnduser.isEmpty()){
                        map<string,list<Account>> mapOfTypeWithActs = new map<string,list<Account>>();
                        for(Account actObj : lstOfEnduser){
                            if(actObj.Type != null && (actObj.Type == 'Active' || actObj.Type == 'Inactive' || actObj.Type == 'Field Engaged' || actObj.Type == 'Target')){
                                list<Account> lstOfTempActs;
                                if(mapOfTypeWithActs.ContainsKey(actObj.Type)){
                                    lstOfTempActs = mapOfTypeWithActs.get(actObj.Type);
                                }else{
                                    lstOfTempActs = new list<Account>();    
                                }
                                lstOfTempActs.add(actObj);
                                mapOfTypeWithActs.put(actObj.Type,lstOfTempActs);
                            } 
                        }
                        if(!mapOfTypeWithActs.isEmpty()){
                            system.debug('**mapOfTypeWithActs**'+mapOfTypeWithActs);
                            list<string> lstWithActType = new list<string>{'Active', 'Inactive', 'Field Engaged' ,'Target'};
                            for(string strType : lstWithActType){
                                if(mapOfTypeWithActs.get(strType) != null){
                                    return processActs(mapOfTypeWithActs.get(strType),lstOfIntialActIds);   
                                }
                            }   
                        }else{
                            return prepareResponse('End User Account is missing Type');                             
                        }                          
                    }else{ 
                        new ExtrIntegrationLog().createExtremeIntegrationLog(
                            new ExtrIntegrationLog.InformationLog(
                                'ExtrAccountLookupServiceCls', 
                                'Web Methods Integration', 
                                null,
                                'Partner or End User records not found'
                            )
                        );
                        return prepareFailureResponse('Partner or End User records not found'); 
                    }
                }else{
                    new ExtrIntegrationLog().createExtremeIntegrationLog(
                        new ExtrIntegrationLog.InformationLog(
                            'ExtrAccountLookupServiceCls', 
                            'Web Methods Integration', 
                            null,
                            'No records found.'
                        )
                    );
                    return prepareFailureResponse('No records found. ');                      
                }    
            }else{
                new ExtrIntegrationLog().createExtremeIntegrationLog(
                    new ExtrIntegrationLog.InformationLog(
                        'ExtrAccountLookupServiceCls', 
                        'Web Methods Integration', 
                        null,
                        'No records found.'
                    )
                );
                return prepareFailureResponse('No records found. ');    
            }
        }catch(Exception Ex){ 
            new ExtrIntegrationLog().createExtremeIntegrationLog(
                new ExtrIntegrationLog.ErrorLog(
                    'ExtrAccountLookupServiceCls', 
                    'Web Methods Integration', 
                    null, 
                    Ex    
                )
            );      
            return prepareFailureResponse('Invalid request ');                 
        } 
        return null;  
    }
    
    /**
    * Purpose   : Method to find best Account from list of Accounts
    * Parameters: lstToProcessActs, lstOfIntialActIds
    * Return    : string
    */
    static string processActs( list<Account> lstToProcessActs, list<Id> lstOfIntialActIds){ 
        if(!lstToProcessActs.isEmpty() && lstToProcessActs.size() == 1){ // If single record found entr and preapare response and return.
            return prepareResponse(lstToProcessActs[0]); // 
        }else if(!lstToProcessActs.isEmpty() && lstToProcessActs.size() > 1){ // If multiple records found with any Status/Type
            map<Date,list<Account>> mapOfCreatedDateWithActs = new map<Date,list<Account>>();
            for(Account actObj : lstToProcessActs){ //Loop the multiple reocrss 
                // Prepare the map with Key As Date and value aslist of acts
                list<Account> lstOfTemps;
                if(mapOfCreatedDateWithActs.containsKey(actObj.createdDate.Date())){
                    lstOfTemps = mapOfCreatedDateWithActs.get(actObj.createdDate.Date());   
                }else{                  
                    lstOfTemps = new list<Account>();   
                }
                lstOfTemps.add(actObj);
                mapOfCreatedDateWithActs.put(actObj.createdDate.Date(),lstOfTemps);                                             
            }
            
            list<Date> lstOfDates = new list<Date>(); // Hodling the dates
            lstOfDates.addAll(mapOfCreatedDateWithActs.KeySet()); // Adding the dates into the list
            lstOfDates.sort(); // Sorting the dates with asc order
            list<Account> lstOfMultiplePortalActs = new list<Account>();
            map<boolean,list<Account>> mapPortalEnableWithActs = new map<boolean,list<Account>>();
            for(Date dt : lstOfDates){
                if(mapOfCreatedDateWithActs.get(dt) != null && mapOfCreatedDateWithActs.get(dt).Size() == 1){
                    return prepareResponse(mapOfCreatedDateWithActs.get(dt)[0]);    
                }else if(mapOfCreatedDateWithActs.get(dt) != null && mapOfCreatedDateWithActs.get(dt).Size() > 1){ // If multiple record
                    list<Account> lstOfSameDateActs = mapOfCreatedDateWithActs.get(dt);                 
                    for(Account actObj : lstOfSameDateActs){
                        list<Account> lstOfTemp;
                        if(mapPortalEnableWithActs.containsKey(actObj.IsCustomerPortal)){
                            lstOfTemp = mapPortalEnableWithActs.get(actObj.IsCustomerPortal);               
                        }else{
                            lstOfTemp = new list<Account>();    
                        }
                        lstOfTemp.add(actObj);
                        mapPortalEnableWithActs.put(actObj.IsCustomerPortal,lstOfTemp);
                    }                           
                }   
            }
            if(!mapPortalEnableWithActs.isEmpty()){
                if(mapPortalEnableWithActs.get(true) != null){
                    if(mapPortalEnableWithActs.get(true).Size() == 1){
                        return prepareResponse(mapPortalEnableWithActs.get(true)[0]);           
                    }else if(mapPortalEnableWithActs.get(true).Size() > 1){
                        lstOfMultiplePortalActs.addAll(mapPortalEnableWithActs.get(true));      
                    }   
                }else if(mapPortalEnableWithActs.get(false) != null){
                    if(mapPortalEnableWithActs.get(false).Size() == 1){
                        return prepareResponse(mapPortalEnableWithActs.get(false)[0]);          
                    }else if(mapPortalEnableWithActs.get(false).Size() > 1){
                        lstOfMultiplePortalActs.addAll(mapPortalEnableWithActs.get(false));     
                    }   
                }
                
            }
            if(!lstOfMultiplePortalActs.isEmpty()){
                for(Id actId : lstOfIntialActIds){
                    for(Account actObj : lstOfMultiplePortalActs){
                        if(actId == actObj.Id){
                            return prepareResponse(actObj); 
                        }   
                    }   
                }
            }
        }
        return null;
    }    
    
    /**
    * Purpose   : Prepare the success response for all the filter criterias
    * Parameters: actObj
    * Return    : string
    */
    static string prepareResponse(Account actObj){
        ExtrAccounLookuptJSONRes.BestAccount BstActObj = new ExtrAccounLookuptJSONRes.BestAccount();    
            BstActObj.Id = actObj.Id;
            BstActObj.recordType = actObj.recordtype.Name;
            BstActObj.calloutStatus = 'SUCCESS';
            BstActObj.ErrorMessage = null;
            if(actObj.recordType.Name == 'Partner'){
                BstActObj.status = actObj.Partner_Status__c;    
            }else if(actObj.recordType.Name == 'End User'){
                BstActObj.type = actObj.Type;   
            }
        string strResponse = JSON.serialize(BstActObj); 
        new ExtrIntegrationLog().createExtremeIntegrationLog(
            new ExtrIntegrationLog.InformationLog(
                'ExtrAccountLookupServiceCls', 
                'Web Methods Integration', 
                actObj.Id,
                strResponse
            )
        );
        return strResponse;
    }
    
    /**
    * Purpose   : Prepare the error response for Deleted Account/Any Id other than Account/Empty Request OR Irrelevant Request/Request has any syntax error/Acct from recordtype other than Partner/End User
    * Parameters: strErrorMsg 
    * Return    : string
    */
    static string prepareFailureResponse(string strErrorMsg){
        ExtrAccounLookuptJSONRes.BestAccount BstActObj = new ExtrAccounLookuptJSONRes.BestAccount();  
            BstActObj.calloutStatus = 'FAILURE';
            BstActObj.ErrorMessage = strErrorMsg;
        string strResponse = JSON.serialize(BstActObj);        
        return strResponse;
    }
    
    /**
    * Purpose   : Prepare the success response for No records found scenario
    * Parameters: strMsg 
    * Return    : string
    */
    static string prepareResponse(string strMsg){
        ExtrAccounLookuptJSONRes.BestAccount BstActObj = new ExtrAccounLookuptJSONRes.BestAccount();    
            BstActObj.Id = null;
            BstActObj.recordType = null;
            BstActObj.calloutStatus = 'SUCCESS';
            BstActObj.ErrorMessage = 'No Records Found';
            BstActObj.status = null;    
            BstActObj.type = null;  
        string strResponse = JSON.serialize(BstActObj); 
        new ExtrIntegrationLog().createExtremeIntegrationLog(
            new ExtrIntegrationLog.InformationLog(
                'ExtrAccountLookupServiceCls', 
                'Web Methods Integration', 
                null,
                strMsg
            )
        );
        return strResponse;
    }    
    
}