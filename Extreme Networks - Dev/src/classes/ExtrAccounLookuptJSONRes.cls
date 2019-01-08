/**
* Class Name : ExtrAccountLookupService
* Purpose    : To send the response back to Web methods
* Author     : Karthik Kasapa
* Date       : 11/20/2018
* Invoked by : processToFindBestAccountId method in class ExtrAccountLookupService
*/

global class ExtrAccounLookuptJSONRes {
    public BestAccount BestAccount;
    public class BestAccount {
        public String Id{get;set;} 
        public String status{get;set;}   
        public String recordType{get;set;}
        public String type{get;set;}
        public string calloutStatus{get;set;}
        public string ErrorMessage{get;set;}
    }
}