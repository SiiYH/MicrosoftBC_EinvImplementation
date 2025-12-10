codeunit 70000002 "MY eInv Authentication"
{
    procedure TestConnectionAndVerifyTIN(var MYeInvSetup: Record "MY eInv Setup"): Boolean
    var
        HttpClient: HttpClient;
        HttpContent: HttpContent;
        HttpHeaders: HttpHeaders;
        HttpResponse: HttpResponseMessage;
        RequestBody: Text;
        ResponseText: Text;
        AccessToken: Text;
        ExpiresIn: Integer;
    begin
        // Validate setup
        if MYeInvSetup.GetClientID() = '' then
            Error('Client ID is not configured.');
        if MYeInvSetup.GetClientSecret() = '' then
            Error('Client Secret is not configured.');
        if MYeInvSetup."Identity Service URL" = '' then
            Error('Identity Service URL is not configured.');

        // Build authentication request
        RequestBody := StrSubstNo('grant_type=client_credentials&client_id=%1&client_secret=%2&scope=InvoicingAPI',
            MYeInvSetup.GetClientID(),
            MYeInvSetup.GetClientSecret());

        HttpContent.WriteFrom(RequestBody);
        HttpContent.GetHeaders(HttpHeaders);
        HttpHeaders.Clear();
        HttpHeaders.Add('Content-Type', 'application/x-www-form-urlencoded');

        // Set timeout
        HttpClient.Timeout(MYeInvSetup."Timeout (Seconds)" * 1000);

        // Make request
        if not HttpClient.Post(MYeInvSetup."Identity Service URL", HttpContent, HttpResponse) then
            Error('Failed to connect to LHDN MyInvois authentication service.');

        HttpResponse.Content.ReadAs(ResponseText);

        if not HttpResponse.IsSuccessStatusCode then
            Error('Authentication failed: %1\Response: %2', HttpResponse.HttpStatusCode, ResponseText);

        // Parse response and extract token
        if not ParseAuthResponse(ResponseText, AccessToken, ExpiresIn) then
            Error('Failed to parse authentication response.');

        // Store token
        MYeInvSetup.SetAccessToken(AccessToken, ExpiresIn);

        // Decode JWT and extract TIN
        ExtractTINFromToken(AccessToken, MYeInvSetup);

        // Mark as verified
        MYeInvSetup."TIN Verified" := true;
        MYeInvSetup."TIN Verification Date" := CurrentDateTime;
        MYeInvSetup.Modify(true);

        exit(true);
    end;

    local procedure ParseAuthResponse(ResponseText: Text; var AccessToken: Text; var ExpiresIn: Integer): Boolean
    var
        JsonObject: JsonObject;
        JsonToken: JsonToken;
    begin
        ///{"iss":"https://identity.myinvois.hasil.gov.my","nbf":1763432542,"iat":1763432542,"exp":1763436142,"aud":"https://identity.myinvois.hasil.gov.my/resources","scope":["InvoicingAPI"],"client_id":"1a24c69c-190c-4877-b9e6-6ea3fed73bfb","IsTaxRepres":"1","IsIntermediary":"0","IntermedId":"0","IntermedTIN":"","IntermedROB":"","IntermedEnforced":"2","name":"C4889129000:1a24c69c-190c-4877-b9e6-6ea3fed73bfb","SSId":"f1fb77b6-f259-053e-c8ed-58f95414daab","preferred_username":"Microsoft Dynamics 365 Business Central ","TaxId":"21810","TaxpayerTIN":"C4889129000","ProfId":"26227","IsTaxAdmin":"0","IsSystem":"1"}

        if not JsonObject.ReadFrom(ResponseText) then
            exit(false);

        if JsonObject.Get('access_token', JsonToken) then
            AccessToken := JsonToken.AsValue().AsText()
        else
            exit(false);

        if JsonObject.Get('expires_in', JsonToken) then
            ExpiresIn := JsonToken.AsValue().AsInteger()
        else
            ExpiresIn := 3600; // Default 1 hour

        exit(true);
    end;

    local procedure ExtractTINFromToken(AccessToken: Text; var MYeInvSetup: Record "MY eInv Setup")
    var
        PayloadJson: JsonObject;
        JsonToken: JsonToken;
        TIN: Text;
    begin
        // Decode JWT payload
        if not DecodeJWTPayload(AccessToken, PayloadJson) then
            exit;

        // Try common claim names for TIN
        if PayloadJson.Get('TaxpayerTIN', JsonToken) then
            TIN := JsonToken.AsValue().AsText();

        if TIN <> '' then begin
            MYeInvSetup."Authenticated TIN" := CopyStr(TIN, 1, 20);
            MYeInvSetup.Modify();
        end;
    end;

    local procedure DecodeJWTPayload(JWT: Text; var PayloadJson: JsonObject): Boolean
    var
        Parts: List of [Text];
        PayloadBase64: Text;
        PayloadText: Text;
        Base64Convert: Codeunit "Base64 Convert";
        TempBlob: Codeunit "Temp Blob";
        InStr: InStream;
        OutStr: OutStream;
    begin
        // JWT format: header.payload.signature
        Parts := JWT.Split('.');
        if Parts.Count <> 3 then
            exit(false);

        Parts.Get(2, PayloadBase64);

        // JWT uses Base64URL encoding, replace characters
        PayloadBase64 := PayloadBase64.Replace('-', '+');
        PayloadBase64 := PayloadBase64.Replace('_', '/');

        // Add padding if needed
        while (StrLen(PayloadBase64) mod 4) <> 0 do
            PayloadBase64 += '=';

        // Decode Base64
        TempBlob.CreateOutStream(OutStr);
        Base64Convert.FromBase64(PayloadBase64, OutStr);
        TempBlob.CreateInStream(InStr);
        InStr.ReadText(PayloadText);

        // Parse JSON
        exit(PayloadJson.ReadFrom(PayloadText));
    end;

    procedure GetValidToken(var MYeInvSetup: Record "MY eInv Setup"): Text
    begin
        if not MYeInvSetup.Get() then
            Error('MY eInv Setup is not configured.');

        // Check if token is still valid
        if MYeInvSetup.IsTokenValid() then
            exit(MYeInvSetup.GetAccessToken());

        // Token expired or doesn't exist, get new one
        if not TestConnectionAndVerifyTIN(MYeInvSetup) then
            Error('Failed to authenticate with LHDN MyInvois.');

        exit(MYeInvSetup.GetAccessToken());
    end;

    ///
    /// Certificate Management
    ///
    procedure UploadAndSendCertificateToAzure(var LHDNSetup: Record "MY eInv Setup")
    var
        TempBlob: Codeunit "Temp Blob";
        FileManagement: Codeunit "File Management";
        InStr: InStream;
        OutStr: OutStream;
        FileName: Text;
        CertPassword: Text;
        Base64Content: Text;
    begin
        // Step 1: Upload certificate file
        if not UploadIntoStream('Select Certificate File', '', 'Certificate Files (*.pfx;*.p12)|*.pfx;*.p12', FileName, InStr) then
            exit;

        // Step 2: Get certificate password
        CertPassword := GetCertificatePassword();
        if CertPassword = '' then
            Error('Certificate password is required.');

        // Step 3: Read file content
        TempBlob.CreateOutStream(OutStr);
        CopyStream(OutStr, InStr);

        // Step 4: Convert to Base64
        Base64Content := ConvertBlobToBase64(TempBlob);

        // Step 5: Validate certificate locally (optional but recommended)
        if not ValidateCertificateFormat(Base64Content) then
            Error('Invalid certificate file format.');

        // Step 6: Send to Azure Function
        SendCertificateToAzure(LHDNSetup, Base64Content, CertPassword, FileName);

        Message('Certificate uploaded successfully to Azure Key Vault!');
    end;

    local procedure GetCertificatePassword(): Text
    var
        MYeInvPasswordDialog: Page "MY eInv Password Dialog";
        CertPassword: Text;
    begin
        // Use a simple dialog to get password
        CertPassword := '';
        MYeInvPasswordDialog.RunModal();
        CertPassword := MYeInvPasswordDialog.GetPassword();

        exit(CertPassword);
    end;

    local procedure ConvertBlobToBase64(var TempBlob: Codeunit "Temp Blob"): Text
    var
        Base64Convert: Codeunit "Base64 Convert";
        InStr: InStream;
        Base64Text: Text;
    begin
        TempBlob.CreateInStream(InStr);
        Base64Text := Base64Convert.ToBase64(InStr);
        exit(Base64Text);
    end;

    local procedure ValidateCertificateFormat(Base64Content: Text): Boolean
    begin
        // Basic validation - check if content exists and looks like base64
        if Base64Content = '' then
            exit(false);
        if StrLen(Base64Content) < 100 then
            exit(false);
        exit(true);
    end;

    procedure SendCertificateToAzure(var LHDNSetup: Record "MY eInv Setup"; CertBase64: Text; CertPassword: Text; FileName: Text)
    var
        Client: HttpClient;
        Content: HttpContent;
        ContentHeaders: HttpHeaders;
        ResponseMsg: HttpResponseMessage;
        RequestBody: Text;
        ResponseText: Text;
        AzureFunctionKey: Text;
        CompanyName: Text;
    begin
        // 1. Validate Azure Function URL
        if LHDNSetup."Azure Function URL" = '' then
            Error('Azure Function URL is not configured. Please configure it first.');

        // 2. Get Azure Function Key
        AzureFunctionKey := GetAzureFunctionKey(LHDNSetup);
        if AzureFunctionKey = '' then
            Error('Azure Function Key is not configured.');

        // 3. Get company identifier for unique certificate naming
        CompanyName := CopyStr(CompanyProperty.DisplayName(), 1, 50);
        CompanyName := DelChr(CompanyName, '=', ' '); // Remove spaces

        // 4. Build JSON request body
        RequestBody := BuildUploadRequestJson(CertBase64, CertPassword, FileName, CompanyName);

        // 5. Set up HTTP content
        Content.WriteFrom(RequestBody);
        Content.GetHeaders(ContentHeaders);
        ContentHeaders.Clear(); // IMPORTANT: Clear default headers
        ContentHeaders.Add('Content-Type', 'application/json'); // Set correct content type

        // 6. Add function key to header
        Client.DefaultRequestHeaders.Add('x-functions-key', AzureFunctionKey);

        // 7. Send POST request to Azure Function
        if not Client.Post(LHDNSetup."Azure Function URL" + '/api/UploadCertificate', Content, ResponseMsg) then
            Error('Failed to connect to Azure Function. Please check the URL and network connection.');

        // 8. Check response status
        if not ResponseMsg.IsSuccessStatusCode then begin
            ResponseMsg.Content.ReadAs(ResponseText);
            Error('Azure Function returned error: %1 - %2', ResponseMsg.HttpStatusCode, ResponseText);
        end;

        // 9. Parse successful response
        ResponseMsg.Content.ReadAs(ResponseText);
        UpdateCertificateMetadata(LHDNSetup, ResponseText, FileName);
    end;

    local procedure BuildUploadRequestJson(CertBase64: Text; CertPassword: Text; FileName: Text; CompanyName: Text): Text
    var
        JsonObj: JsonObject;
        JsonText: Text;
    begin
        JsonObj.Add('certificateBase64', CertBase64);
        JsonObj.Add('certificatePassword', CertPassword);
        JsonObj.Add('certificateFileName', FileName);
        JsonObj.Add('companyIdentifier', CompanyName);
        JsonObj.Add('certificateName', CompanyName + '-LHDN-Certificate');

        JsonObj.WriteTo(JsonText);
        exit(JsonText);
    end;

    local procedure UpdateCertificateMetadata(var LHDNSetup: Record "MY eInv Setup"; ResponseJson: Text; FileName: Text)
    var
        JsonObj: JsonObject;
        JsonToken: JsonToken;
    begin
        if not JsonObj.ReadFrom(ResponseJson) then
            Error('Invalid response from Azure Function.');

        LHDNSetup."Certificate File Name" := CopyStr(FileName, 1, MaxStrLen(LHDNSetup."Certificate File Name"));
        LHDNSetup."Certificate Configured" := true;

        // Extract certificate details from response
        if JsonObj.Get('certificateId', JsonToken) then
            LHDNSetup."Certificate ID" := CopyStr(JsonToken.AsValue().AsText(), 1, MaxStrLen(LHDNSetup."Certificate Id"));

        if JsonObj.Get('issuer', JsonToken) then
            LHDNSetup."Certificate Issuer" := CopyStr(JsonToken.AsValue().AsText(), 1, MaxStrLen(LHDNSetup."Certificate Issuer"));

        if JsonObj.Get('subject', JsonToken) then
            LHDNSetup."Certificate Subject" := CopyStr(JsonToken.AsValue().AsText(), 1, MaxStrLen(LHDNSetup."Certificate Subject"));

        if JsonObj.Get('serialNumber', JsonToken) then
            LHDNSetup."Certificate Serial Number" := CopyStr(JsonToken.AsValue().AsText(), 1, MaxStrLen(LHDNSetup."Certificate Serial Number"));

        if JsonObj.Get('validFrom', JsonToken) then
            Evaluate(LHDNSetup."Certificate Valid From", JsonToken.AsValue().AsText());

        if JsonObj.Get('validTo', JsonToken) then
            Evaluate(LHDNSetup."Certificate Valid To", JsonToken.AsValue().AsText());

        LHDNSetup.Modify(true);
    end;

    procedure GetAzureFunctionKey(LHDNSetup: Record "MY eInv Setup"): Text
    var
        FunctionKey: Text;
    begin
        if IsNullGuid(LHDNSetup."Azure Function Key") then
            exit('');

        if IsolatedStorage.Get(LHDNSetup."Azure Function Key", DataScope::Company, FunctionKey) then
            exit(FunctionKey);

        exit('');
    end;

    procedure SetAzureFunctionKey(var LHDNSetup: Record "MY eInv Setup")
    var
        PasswordDialog: Page "MY eInv Password Dialog";
        FunctionKey: Text;
        KeyGuid: Guid;
    begin
        // Reuse your password dialog page
        PasswordDialog.RunModal();
        FunctionKey := PasswordDialog.GetPassword();

        if FunctionKey = '' then
            exit; // User cancelled or left empty

        KeyGuid := CreateGuid();
        if not IsolatedStorage.Set(KeyGuid, FunctionKey, DataScope::Company) then
            Error('Failed to store Azure Function Key securely.');

        LHDNSetup."Azure Function Key" := KeyGuid;
        LHDNSetup.Modify(true);

        Message('Azure Function Key stored securely.');
    end;

    procedure TestAzureConnection(LHDNSetup: Record "MY eInv Setup")
    var
        Client: HttpClient;
        ResponseMsg: HttpResponseMessage;
        AzureFunctionKey: Text;
        HealthUrl: Text;
        ResponseText: Text;
    begin
        if LHDNSetup."Azure Function URL" = '' then
            Error('Azure Function URL is not configured.');

        // Normalize URL (remove trailing slash)
        HealthUrl := LHDNSetup."Azure Function URL".TrimEnd('/') + '/api/Health';

        AzureFunctionKey := GetAzureFunctionKey(LHDNSetup);

        if AzureFunctionKey <> '' then begin
            if not Client.DefaultRequestHeaders.Contains('x-functions-key') then
                Client.DefaultRequestHeaders.Add('x-functions-key', AzureFunctionKey);
        end;

        if not Client.Get(HealthUrl, ResponseMsg) then
            Error('Failed to connect to Azure Function at %1.', HealthUrl);

        ResponseMsg.Content.ReadAs(ResponseText);

        if ResponseMsg.IsSuccessStatusCode then
            Message('Connection successful! Azure Function is responding: %1', ResponseText)
        else
            Error('Azure Function returned error %1: %2', ResponseMsg.HttpStatusCode, ResponseText);
    end;


    procedure RemoveCertificateFromAzure(var LHDNSetup: Record "MY eInv Setup")
    var
        Client: HttpClient;
        RequestMsg: HttpRequestMessage;
        ResponseMsg: HttpResponseMessage;
        Content: HttpContent;
        RequestBody: Text;
        JsonObj: JsonObject;
        CompanyName: Text;
    begin
        if not LHDNSetup."Certificate Configured" then
            Error('No certificate is configured.');

        CompanyName := CopyStr(CompanyProperty.DisplayName(), 1, 50);
        CompanyName := DelChr(CompanyName, '=', ' ');

        JsonObj.Add('certificateName', CompanyName + '-LHDN-Certificate');
        JsonObj.WriteTo(RequestBody);

        Content.WriteFrom(RequestBody);
        RequestMsg.Method := 'DELETE';
        RequestMsg.SetRequestUri(LHDNSetup."Azure Function URL" + '/api/RemoveCertificate');
        RequestMsg.Content := Content;

        if Client.Send(RequestMsg, ResponseMsg) and ResponseMsg.IsSuccessStatusCode then begin
            ClearCertificateMetadata(LHDNSetup);
            Message('Certificate removed successfully from Azure Key Vault.');
        end else
            Error('Failed to remove certificate from Azure.');
    end;

    local procedure ClearCertificateMetadata(var LHDNSetup: Record "MY eInv Setup")
    begin
        Clear(LHDNSetup."Certificate File Name");
        Clear(LHDNSetup."Certificate Configured");
        Clear(LHDNSetup."Certificate Issuer");
        Clear(LHDNSetup."Certificate Subject");
        Clear(LHDNSetup."Certificate Serial Number");
        Clear(LHDNSetup."Certificate Valid From");
        Clear(LHDNSetup."Certificate Valid To");
        LHDNSetup.Modify(true);
    end;
}
