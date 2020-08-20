public without sharing class fileUploadController {
  @AuraEnabled
  public static String generateEncryptedToken(Id recordId) {
    system.debug(recordId);
    Blob key = getAESKey();
    Blob recordIdAsBlob = Blob.valueOf(recordId);
    Blob encryptedRecordId = Crypto.encryptWithManagedIV('AES128', key, recordIdAsBlob);
    String encryptedDataStr = EncodingUtil.base64Encode(encryptedRecordId);
    String decryptedId = decryptToken(encryptedDataStr);
    System.debug(decryptedId);
    return encryptedDataStr;
  }

  public static Blob getAESKey() {
    File_Encryption__c fileEncryptionCS = File_Encryption__c.getOrgDefaults();
    if (fileEncryptionCS.Key__c == null) {
      Blob key = createAESKey();
      return key;
    } else {
      Blob key = EncodingUtil.base64Decode(fileEncryptionCS.Key__c);
      system.debug(key);
      return key;
    }
  }

  public static Blob createAESKey() {
    File_Encryption__c fileEncryptionCS = File_Encryption__c.getOrgDefaults();
    Blob key = Crypto.generateAesKey(128);
    fileEncryptionCS.Key__c = EncodingUtil.base64Encode(key);
    insert fileEncryptionCS;
    return key;
  }

  /**
   * associateFile matches token against a ContentDocument through the content version custom field.
   * Then it decrypts the token which contains a recordId and creates a ContentDocumentLink between the document and the record.
   *
   * Following the guidance in https://developer.salesforce.com/docs/component-library/bundle/lightning-file-upload/documentation
   * the document DOES upload, but when calling the method from the LWC we can not query for the ContentDocument
   * without sharing context. The document is not found.
   *
   * @param  token the token passed in from the LWC
   */
  @AuraEnabled
  public static void associateFile(String token) {
    ContentDocument contentDocument = getRelatedContentDocument(token);
    String recordId = decryptToken(token);
    updateContentDocument(recordId, contentDocument);
  }

  public static String decryptToken(String token) {
    File_Encryption__c fileEncryptionCS = File_Encryption__c.getOrgDefaults();
    Blob key = EncodingUtil.base64Decode(fileEncryptionCS.Key__c);
    Blob data = EncodingUtil.base64Decode(token);
    Blob decrypted = Crypto.decryptWithManagedIV('AES128', key, data);
    String decryptedString = decrypted.toString();
    return decryptedString;
  }

  public static contentDocument getRelatedContentDocument(String token) {
    List<ContentDocument> contentDocuments = [SELECT Id FROM ContentDocument ORDER BY CreatedDate DESC];
    //List<ContentDocument> contentDocuments = [SELECT Id FROM ContentDocument WHERE LatestPublishedVersion.GuestReference_fileupload__c = :token ORDER BY CreatedDate DESC];
    ContentDocument contentDocument = contentDocuments.size() == 1 ? contentDocuments.get(0) : null;
    return contentDocument;
  }

  public static void updateContentDocument(String recordId, ContentDocument contentDocument) {
    ContentDocumentLink contentlink = new ContentDocumentLink();
    contentlink.LinkedEntityId = recordId;
    contentlink.ShareType = 'C';
    contentlink.ContentDocumentId = contentDocument.Id;
    contentlink.Visibility = 'AllUsers';
    insert contentlink;
  }
}
