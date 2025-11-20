// ═════════════════════════════════════════════════════════════════
// CODEUNIT 70000005: MY eInv Azure Signer
// Handles communication with Azure Function
// ═════════════════════════════════════════════════════════════════

codeunit 70000005 "MY eInv Azure Signer"
{
    procedure SignViaAzureFunction(DocumentXML: Text; Setup: Record "MY eInv Setup"): Text
    var
        Client: HttpClient;
        Content: HttpContent;
        Headers: HttpHeaders;
        Response: HttpResponseMessage;
        RequestJson: Text;
        ResponseJson: Text;
        SignedXML: Text;
        RequestTimeout: Duration;
    begin
        // Build request
        RequestJson := BuildSigningRequest(DocumentXML, Setup);
        
        // Configure HTTP client
        Content.WriteFrom(RequestJson);
        Content.GetHeaders(Headers);
        Headers.Clear();
        Headers.Add('Content-Type', 'application/json');
        
        // Set timeout (default 120 seconds for signing operations)
        RequestTimeout := Setup."Timeout (Seconds)" * 1000;
        if RequestTimeout = 0 then
            RequestTimeout := 120000; // 120 seconds default
            
        Client.Timeout(RequestTimeout);
        
        // Call Azure Function
        if not Client.Post(GetSigningURL(Setup), Content, Response) then
            Error('Failed to connect to signing service. Please check your Azure Function configuration and network connectivity.');
        
        // Handle response
        SignedXML := HandleSigningResponse(Response);
        
        exit(SignedXML);
    end;
    
    local procedure BuildSigningRequest(DocumentXML: Text; Setup: Record "MY eInv Setup"): Text
    var
        JRequest: JsonObject;
        CertBase64: Text;
        CertPassword: Text;
    begin
        // Get certificate data
        CertBase64 := GetCertificateAsBase64(Setup);
        CertPassword := Setup.GetCertificatePassword();
        
        if (CertBase64 = '') or (CertPassword = '') then
            Error('Certificate data is missing or incomplete.');
        
        // Build JSON request matching Azure Function's SigningRequest class
        JRequest.Add('DocumentXml', DocumentXML);
        JRequest.Add('CertificateBase64', CertBase64);
        JRequest.Add('CertificatePassword', CertPassword);
        
        exit(FormatJson(JRequest));
    end;
    
    local procedure GetCertificateAsBase64(Setup: Record "MY eInv Setup"): Text
    var
        Base64Convert: Codeunit "Base64 Convert";
        InStr: InStream;
        CertBase64: Text;
    begin
        if not Setup."Certificate Content".HasValue then
            exit('');
        
        Setup."Certificate Content".CreateInStream(InStr);
        CertBase64 := Base64Convert.ToBase64(InStr);
        
        exit(CertBase64);
    end;
    
    local procedure GetSigningURL(Setup: Record "MY eInv Setup"): Text
    var
        URL: Text;
        FunctionKey: Text;
    begin
        URL := Setup."Azure Function URL";
        
        if URL = '' then
            Error('Azure Function URL is not configured.');
        
        // Add function key if configured
        FunctionKey := Setup.GetAzureFunctionKey();
        if FunctionKey <> '' then begin
            if URL.Contains('?') then
                URL += '&code=' + FunctionKey
            else
                URL += '?code=' + FunctionKey;
        end;
        
        exit(URL);
    end;
    
    local procedure HandleSigningResponse(Response: HttpResponseMessage): Text
    var
        ResponseJson: Text;
        JResponse: JsonObject;
        JToken: JsonToken;
        SignedXML: Text;
        ErrorMessage: Text;
    begin
        // Check HTTP status
        if not Response.IsSuccessStatusCode then begin
            Response.Content.ReadAs(ResponseJson);
            Error('Signing service returned error: %1 - %2\Response: %3', 
                Response.HttpStatusCode, 
                Response.ReasonPhrase,
                ResponseJson);
        end;
        
        // Parse response
        Response.Content.ReadAs(ResponseJson);
        
        if not JResponse.ReadFrom(ResponseJson) then
            Error('Invalid response from signing service.');
        
        // Check success flag
        if JResponse.Get('Success', JToken) then begin
            if not JToken.AsValue().AsBoolean() then begin
                ErrorMessage := 'Signing failed';
                if JResponse.Get('Message', JToken) then
                    ErrorMessage += ': ' + JToken.AsValue().AsText();
                Error(ErrorMessage);
            end;
        end else
            Error('Response does not contain Success flag.');
        
        // Extract signed XML
        if not JResponse.Get('SignedXml', JToken) then
            Error('Signed XML not found in response.');
        
        SignedXML := JToken.AsValue().AsText();
        
        if SignedXML = '' then
            Error('Signed XML is empty.');
        
        exit(SignedXML);
    end;
    
    local procedure FormatJson(JObject: JsonObject): Text
    var
        JsonText: Text;
    begin
        JObject.WriteTo(JsonText);
        exit(JsonText);
    end;
}
