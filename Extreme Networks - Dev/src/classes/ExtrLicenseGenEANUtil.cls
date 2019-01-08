/**
 * ExtrLicenseGenEANUtil
 * Utility class for various methods used in EAN license generation
 * Date: 4/6/2018
 */
public class ExtrLicenseGenEANUtil  {
    
    public static String LOG_PROCESS = 'EAN License Management';
    private static String EAN_ALGORITHM = 'EAN';
    private static String IDE_ALGORITHM = 'IDE';
    public static String skuList = '';
    public static final String IDE_Base = 'IDEBase';
    public static final String IDE_Feature = 'IDEFeature';
    public static final String IDE_HA = 'HA';
    public static final String IDE_SA = 'SA';
    
    private static List<License__c> currentLicense;
    private static List<License_Attribute__c> voucherAttributes;
    private static List<License_Attribute__c> hardwareAttributes;
    private static Set<Id> ideProducts;
    
    public static String getEANAlgorithmName() {
        String name = ExtrSetting__c.getInstance().EAN_Algorithm_Name__c;
        if (name == null) {
            name = EAN_ALGORITHM;
        }
        return name;
    }

    public static String getIDEAlgorithmName() {
        String name;
        if (name == null) {
            name = IDE_ALGORITHM;
        }
        return name;
    }
    
    public static Map<String,String> getProductDetails(List<String> skus) {
        Map<String,String> productDetails = new Map<String,String>();
        for(Product2 prod : [SELECT ProductCode,Description FROM Product2 WHERE ProductCode IN :skus]) {
            productDetails.put(prod.ProductCode,prod.Description);
        } 
        return productDetails;
    }

    // for a given voucher hardware mapping record, give the related license attributes
    public static List<License_Attribute__c> getAttributes(VoucherHardwareMapping__c mapping) {
        if(mapping == null) return new List<License_Attribute__c>();
        return [
            SELECT Id,Product_Type__c,Product_Category__c,Name__c,Value__c
            FROM License_Attribute__c
            WHERE Voucher_Hardware_Mapping__c = :mapping.Id
            AND Name__c != null
        ];
    }

    // for a given list of attributes, return a key-value pairing
    public static Map<String,String> getAttributeMap(List<License_Attribute__c> attributes) {
        Map<String,String> attrMap = new Map<String,String>();
        for(License_Attribute__c licAttr : attributes) {
            attrMap.put(licAttr.Name__c,licAttr.Value__c);
        }
        return attrMap;
    }
    
    // get the voucher-specific license attributes for a given request
    public static List<License_Attribute__c> getVoucherAttributes(VoucherHardwareMapping__c mapping) {
        if(voucherAttributes == null) {
            voucherAttributes = getAttributes(mapping);
        }
        return voucherAttributes;
    }

    // get the hardware-specific license attributes for a given request
    public static List<License_Attribute__c> getHardwareAttributes(VoucherHardwareMapping__c mapping) {
        if(hardwareAttributes == null) {
            hardwareAttributes = getAttributes(mapping);
        }
        return hardwareAttributes;
    }

    // get the currently installed license, if applicable
    public static List<License__c> getCurrentLicense(Asset hardwareAsset) {
        if(currentLicense == null && hardwareAsset != null) {
            currentLicense = [
                SELECT Id,
                    StatusCalc__c,
                    CurrentLevel__c,
                    MACAddress__c,
                    (SELECT Id,
                        Asset__c,
                        Asset__r.Status,
                        Asset__r.Product2Id,
                        Asset__r.Product2.Name,
                        Asset__r.Product2.ProductCode
                    FROM Vouchers__r)
                FROM License__c
                WHERE HardwareAsset__c = :hardwareAsset.Id
                AND StatusCalc__c = 'Active'
                ORDER BY CreatedDate DESC
            ];
        }
        return currentLicense;
    }
    
    // get all of the unique IDE installation serials across an account's active licenses
    public Static Set<String> getIDECurrentLicenses(Asset primaryVoucherAsset) {
        Set<String> activeLicenseSerials = new Set<String>();
        if(ideProducts == null) {
            ideProducts = new Set<Id>();
            for(VoucherHardwareMapping__c vhm : [SELECT Id,VoucherProduct__c FROM VoucherHardwareMapping__c WHERE Algorithm__c = :ExtrLicenseGenEANUtil.getIDEAlgorithmName()]) {
                ideProducts.add(vhm.VoucherProduct__c);
            }
        }
        
        for(VoucherLineItem__c vli : [
                SELECT Id,Asset__r.Product2Id,License__r.VirtualHardwareSerialNumber__c 
                FROM VoucherLineItem__c 
                WHERE License__r.Status__c = 'Active' 
                AND Asset__r.AccountId = :primaryVoucherAsset.AccountId
        ]) {
            
            if(ideProducts.contains(vli.Asset__r.Product2Id)) {
                activeLicenseSerials.add(vli.License__r.VirtualHardwareSerialNumber__c);
            }
            
        }
        return activeLicenseSerials;
    }

    // get the total list of vouchers installed as per the current active license
    public static List<VoucherLineItem__c> getInstalledVouchers(Asset hardwareAsset) {
        List<License__c> currentLicense = getCurrentLicense(hardwareAsset);
        List<VoucherLineItem__c> installedVouchers = new List<VoucherLineItem__c>();
        if(currentLicense != null && !currentLicense.isEmpty()) {
            installedVouchers = currentLicense[0].Vouchers__r;
        }
        return installedVouchers;
    }
    
    // get a unique set of the installed vouchers
    public static Map<String,String> getUniqueInstalledVouchers(List<VoucherLineItem__c> installedVouchers) {
        Map<String,String> uniqueVouchers = new Map<String,String>();
        if (installedVouchers != null && !installedVouchers.isEmpty()) {
            for (VoucherLineItem__c vli : [SELECT Id,Asset__r.Product2.ProductCode,Asset__r.Product2.Description FROM VoucherLineItem__c WHERE Id IN :installedVouchers]) {
                uniqueVouchers.put(vli.Asset__r.Product2.ProductCode,vli.Asset__r.Product2.Description);
            }
        }
        return uniqueVouchers;
    }
    
    // get the current level for the installed license, if applicable
    public static Integer getCurrentLevel(Asset hardwareAsset) {
        Integer currentLevel;
        List<License__c> currentLicense = getCurrentLicense(hardwareAsset);
        if(currentLicense != null && !currentLicense.isEmpty()) {
            currentLevel = currentLicense[0].CurrentLevel__c != null ? Integer.valueOf(currentLicense[0].CurrentLevel__c) : null;
        }
        return currentLevel;
    }
    
    // determine the new level for a new license to be created, if applicable
    public static Integer getNewLevel(Integer currentLevel, List<License_Attribute__c> voucherAttributes) {
        Integer newLevel = currentLevel;
        String capacityAttribute = ExtrLicenseGenSRAUtil.getVoucherCapacityAttrName(voucherAttributes);
        if(String.isNotBlank(capacityAttribute)) {
            Integer voucherCapacityValue = Integer.valueOf(ExtrLicenseGenSRAUtil.getCapacityAttributeValue(voucherAttributes));
            newLevel = (currentLevel != null ? currentLevel : 0) + voucherCapacityValue;
        }
        return newLevel;
    }
    
    /** 
     * determine the customer name and address to be passed to the license generator.
     * used for full license redemptions
     * @parameters related voucher asset for the license request in context
     * @return concatenated customer name + address string
     */
    public static String getCustomerNameAndAddress(Asset voucherAsset) {
        return getCustomerNameAndAddress(voucherAsset, null, null);
    }

    public static String getCustomerNameAndAddress(Evaluation__c eval, String customerInput) {
        return getCustomerNameAndAddress(null, eval, customerInput);
    }
    
    public static String getCustomerNameAndAddress(Asset voucherAsset, Evaluation__c eval, String customerInput) {
        String nameAddress = String.isNotBlank(customerInput) ? customerInput : 'Customer'; // failsafe placeholder which should end up getting overwritten below
        Account redemptionAccount;
        
        // if we have a voucher (full license request), use the voucher's account
        if(voucherAsset != null) {
            redemptionAccount = [SELECT Id,Name,BillingAddress FROM Account WHERE Id = :voucherAsset.AccountId];
        // otherwise for evals, see if there is a user populated in the Requested By field. 
        // if not, check if the running user is a portal/external user and use their account info
        } else if(eval != null) {
            if(eval.RequestedBy__r != null && eval.RequestedBy__r.AccountId != null) {
                redemptionAccount = [SELECT Id,Name,BillingAddress FROM Account WHERE Id = :eval.RequestedBy__r.AccountId];
            } else if(UserUtil.getAccount().Id != null) {
                redemptionAccount = [SELECT Id,Name,BillingAddress FROM Account WHERE Id = :UserUtil.getAccount().Id];
            }
        }
        
        if(redemptionAccount != null) {
            // use at least the customer name
            nameAddress = redemptionAccount.Name;
            // add the address if we have it
            if(redemptionAccount.BillingAddress != null) {
                string strActStreet = '';
                strActStreet = redemptionAccount.BillingAddress.getStreet().replace('\n', ' ');
                       
                nameAddress += ' ' +
                    strActStreet + ' ' +
                    redemptionAccount.BillingAddress.getCity() + ' ' +
                    redemptionAccount.BillingAddress.getState() + ' ' +
                    redemptionAccount.BillingAddress.getPostalCode();
            }
        }
        
        return nameAddress.trim();
    }
    
    /** 
     * Transform the license service response into a file so it can be downloaded
     * @parameters returned XML string from the EAN license service
     * @return SFDC attachment record
     */
    public static Attachment getAttachmentFromKey(String voucherType, String licKey, String mac, Asset installationAsset) {
        Attachment a = new Attachment();
        String productIdentifier = voucherType == 
                ExtrLicenseGenEANUtil.getIDEAlgorithmName() ? 
                installationAsset.Product2.ProductCode : 
                installationAsset.Product2.Product_Class__c.deleteWhitespace();
        if(licKey != null) {
            licKey = licKey.unescapeJava();
            a.Body = Blob.valueOf(licKey);
            a.Name = setupAttachmentFileName(voucherType, mac, productIdentifier);
        }
        return a;
    }

    // build attachment for Evaluation parent record
    public static Attachment getAttachmentFromKey(String voucherType, String licKey, String mac, Evaluation__c eval) {
        Attachment a = new Attachment();
        String productIdentifier = voucherType ==
                ExtrLicenseGenEANUtil.getIDEAlgorithmName() ?
                eval.Product__r.ProductCode :
                'Evaluation';
        if(licKey != null) {
            licKey = licKey.unescapeJava();
            a.Body = Blob.valueOf(licKey);
            a.Name = setupAttachmentFileName(voucherType, mac, productIdentifier);
        }
        return a;
    }
    
    // setup attachment file name and type according to product type/naming convention
    private static String setupAttachmentFileName(String voucherType, String mac, String productIdentifier) {
        String fileName;
        if(voucherType == ExtrLicenseGenEANUtil.getIDEAlgorithmName()) {
            fileName = 'IDE-LIC-' + mac.replace(':','-') + (mac.length() == 12 ? '-SA-' : '-HA-') + productIdentifier + '.txt';
        } else {
            // requested EAN naming convention for license files: HardwarePlatform_MacAddress
            fileName = productIdentifier + '_' + mac + '.xml';
        }
        return fileName;
    }

    /** 
     * If the license provided an expiration date, it's an eval license.
     * Extract it from the response XML and stamp it on the license and related eval record
     * @parameters returned XML string from the EAN license service
     * @return properly formatted Date variable
     */
    public static Date extractExpirationDate(String licenseXML) {
        // the license exp date will initially default to the duration fields set on eval products.
        // however, we should try to pull out the returned expiration date to compare them,
        // and use it if they are not (always assume the generator is correct)
        String extractedDateString;
        Date returnDate;
        String[] parsedDate;
        
        // try EAN format
        extractedDateString = licenseXML.substringBetween('<ExpirationDate>','</ExpirationDate>');
        if(extractedDateString != null) {
            parsedDate = extractedDateString.split('/');
        } else {
            // try IDE format
            extractedDateString = licenseXML.unescapeJava().substringBetween('Expiration','-');
            if(extractedDateString != null) {
                parsedDate = extractedDateString.replace(':','').trim().split(' ');
            }
        }
        
        
        
        if(!parsedDate.isEmpty() && parsedDate.size() == 3) {
            returnDate = Date.newInstance(
                    Integer.valueOf(parsedDate[0]),     // year
                    Integer.valueOf(parsedDate[1]),     // month
                    Integer.valueOf(parsedDate[2])      // day
            );
        }
        
        return returnDate;
    }

    public static Date extractExpirationDate(String responseString, String voucherType) {
        // the license exp date will initially default to the duration fields set on eval products.
        // however, we should try to pull out the returned expiration date to compare them,
        // and use it if they are not (always assume the generator is correct)
        String extractedDateString;
        String[] parsedDate;
        Date returnDate;

        // extract EAN expiration
        if(voucherType == ExtrLicenseGenEANUtil.getEANAlgorithmName()) {
            extractedDateString = responseString.substringBetween('<ExpirationDate>','</ExpirationDate>');
            if(extractedDateString != null) {
                parsedDate = extractedDateString.split('/');
            }
        }
        
        // extract IDE expiration
        if(voucherType == ExtrLicenseGenEANUtil.getIDEAlgorithmName()) {
            extractedDateString = responseString.unescapeJava().substringBetween('Expiration','-');
            if(extractedDateString != null) {
                parsedDate = extractedDateString.replace(':','').trim().split(' ');
            }
        }
        
        if(!parsedDate.isEmpty() && parsedDate.size() == 3) {
            returnDate = Date.newInstance(
                    Integer.valueOf(parsedDate[0]),     // year
                    Integer.valueOf(parsedDate[1]),     // month
                    Integer.valueOf(parsedDate[2])      // day
            );
        }

        return returnDate;
    }
    
    /** 
     * Get Voucher Hardware Mapping records
     * @parameters Voucher product
     * @return List<VoucherHardwareMapping__c>
     */
     public static List<VoucherHardwareMapping__c> getLicenseSKU(String productId){
          List<VoucherHardwareMapping__c> VoucherHardwareMappingRecords = new List<VoucherHardwareMapping__c>();
          VoucherHardwareMappingRecords = [SELECT Id,ProductLine__c,(SELECT Id,Value__c FROM Voucher_Attributes__r WHERE Name__c = 'License SKU') FROM VoucherHardwareMapping__c WHERE VoucherProduct__c =:productId];
          
          return VoucherHardwareMappingRecords;
       }
    
    /** 
     * Get the colon delimited product code string.
     * @parameters hardware asset and newly installed vouchers
     * @return colon delimited list of SKUs
     */
    public static String getEANSKUList(Asset hwAsset, List<Asset> swAssets) {
        //String skuList = '';
        // grab everything that's currently installed
        Set<String> newLicenseFeatures = new Set<String>(getUniqueInstalledVouchers(getInstalledVouchers(hwAsset)).keySet());
        VoucherHardwareMapping__c vhpObj = new VoucherHardwareMapping__c();        
        
        List<VoucherHardwareMapping__c> VoucherHardwareMappingRecords = getLicenseSKU(swAssets[0].Product2id);   
        
        if(!VoucherHardwareMappingRecords.isEmpty()){
           vhpObj = VoucherHardwareMappingRecords[0];             
        }
                
        if(vhpObj != null && !vhpObj.Voucher_Attributes__r.isEmpty() && vhpObj.Voucher_Attributes__r[0].Value__c != null){          
            newLicenseFeatures.add(vhpObj.Voucher_Attributes__r[0].Value__c);
            //return vhpObj.Voucher_Attributes__r[0].Value__c.trim();    
        }else {      
                // include the voucher being redeemed now
                newLicenseFeatures.add(swAssets[0].Product2.ProductCode);
               } 
               
            for(String sku : newLicenseFeatures) {
                skuList += sku.trim() + ':';
            }
            
            skuList = skuList.removeEnd(':');
            return skuList;
        
    }

    /** 
     * Get the product code string related to an evaluation record.
     * @parameters evaluation record
     * @return eval product SKU
     */
    public static String getEANSKUList(Evaluation__c eval) {        
        VoucherHardwareMapping__c vhpObj = new VoucherHardwareMapping__c();
        
        List<VoucherHardwareMapping__c> VoucherHardwareMappingRecords = getLicenseSKU(eval.Product__c);       
        
        if(!VoucherHardwareMappingRecords.isEmpty()){
           vhpObj = VoucherHardwareMappingRecords[0];             
        }
               
        if(vhpObj != null && !vhpObj.Voucher_Attributes__r.isEmpty() && vhpObj.Voucher_Attributes__r[0].Value__c != null){          
            return vhpObj.Voucher_Attributes__r[0].Value__c.trim();    
        }else
            return eval.Product__r.ProductCode.trim();
    }

     /** 
     * Get the product code string related to an asset record.
     * @parameters asset
     * @return asset product SKU
     */
    public static String getIDESKUList(Asset primaryVoucherAsset) {
        String skuList = primaryVoucherAsset.Product2.ProductCode;
        return skuList;
    }

     /** 
     * Get list of IDE configuration options.
     * @parameters N/A
     * @return List<SelectOption>
     */
    public static List<SelectOption> getIDELicenseCongirationOptions(){
    List<SelectOption> configOpts = new List<SelectOption>();
        Schema.DescribeFieldResult fieldResult = License__c.IDE_Configuration__c.getDescribe();
        List<Schema.PicklistEntry> picklistOptions = fieldResult.getPicklistValues();

        for( Schema.PicklistEntry opt : picklistOptions) {
            configOpts.add(new SelectOption(opt.getValue(), opt.getLabel()));
        }
        
        return configOpts;
    }

     /** 
     * Get Voucher Type for IDE product from VHM.
     * @parameters Voucher Id and Is Evaluation Boolean
     * @return String
     */
    public static String getIDEVoucherType(Id voucherRecordId, Boolean isEvaluation){
        
        String ideVoucherType;
        String productId;
        VoucherHardwareMapping__c[] vhm;
                
        if(isEvaluation) {
            productId = [SELECT Product__c FROM Evaluation__c WHERE Id = :voucherRecordId].Product__c;
        } else if(voucherRecordId.getSobjectType() == Schema.Asset.SObjectType) {
            productId = [SELECT Product2Id FROM Asset WHERE Id = :voucherRecordId].Product2Id;
        }
                
        if(productId != null) {
            vhm = [SELECT Id,VoucherType__c FROM VoucherHardwareMapping__c WHERE VoucherProduct__c = :productId];
            if(vhm != null) {
                ideVoucherType = vhm[0].VoucherType__c;
            }
        }

        return ideVoucherType;
    }
}