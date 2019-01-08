/**
* Class Name : ExtrAccountLookupService
* Purpose    : To parse the request received from Web Methods
* Author     : Karthik Kasapa
* Date       : 11/20/2018
* Invoked by : Web Methods
*/

public class ExtrAccounLookuptJSONReq {
    public list<ExtrAccountIdCls> ExtrAccountIds{get;set;}
    
    public class ExtrAccountIdCls{
        public string Id{get;set;}
    }
}