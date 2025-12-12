// ═════════════════════════════════════════════════════════════════
// CODEUNIT 70000005: MY eInv Azure Signer
// Handles communication with Azure Function (Key Vault Integration)
// ═════════════════════════════════════════════════════════════════

codeunit 70000005 "MY eInv Azure Signer"
{
    var
        DiagnosticResultMsg: Label 'Diagnostic Results:\%1';

    /// <summary>
    /// Diagnostic of Azure Function
    /// </summary>
    /// <param name="Setup"></param>
    /// <returns></returns>
    procedure RunFullDiagnostic(Setup: Record "MY eInv Setup"): Text
    var
        Results: Text;
    begin
        Results := '═══ DIGITAL SIGNATURE DIAGNOSTICS ═══\\';
        Results += CheckConfiguration(Setup);
        Results += CheckCertificateSetup(Setup);
        Results += CheckNetworkConnectivity(Setup);
        Results += TestMinimalRequest(Setup);
        Results += '\═══════════════════════════════════';

        Message(DiagnosticResultMsg, Results);
        exit(Results);
    end;

    local procedure CheckConfiguration(Setup: Record "MY eInv Setup"): Text
    var
        Result: Text;
    begin
        Result := '1. CONFIGURATION CHECK\';

        if Setup."Azure Function URL" = '' then
            Result += '   ✗ Azure Function URL: NOT SET\'
        else
            Result += '   ✓ Azure Function URL: ' + CopyStr(Setup."Azure Function URL", 1, 50) + '...\';

        if Setup.GetAzureFunctionKey() = '' then
            Result += '   ✗ Signing Service Key: NOT SET\'
        else
            Result += '   ✓ Signing Service Key: SET (length: ' + Format(StrLen(Setup.GetAzureFunctionKey())) + ')\';

        // if Setup."Certificate Source" = Setup."Certificate Source"::"Key Vault" then begin
        Result += '   • Certificate Source: Key Vault\';
        if Setup."Certificate ID" = '' then
            Result += '   ✗ Company Certificate Name: NOT SET\'
        else
            Result += '   ✓ Company Certificate Name: ' + Setup."Certificate ID" + '\';
        /* end else begin
            Result += '   • Certificate Source: Base64 (Legacy)\';
            Setup.CalcFields("Certificate Base64");
            if Setup."Certificate Base64".HasValue then
                Result += '   ✓ Certificate Base64: Uploaded\'
            else
                Result += '   ✗ Certificate Base64: NOT UPLOADED\';
        end; */

        exit(Result + '\');
    end;

    local procedure CheckCertificateSetup(Setup: Record "MY eInv Setup"): Text
    var
        Result: Text;
    begin
        Result := '2. CERTIFICATE SETUP\';

        // if Setup."Certificate Source" = Setup."Certificate Source"::"Key Vault" then begin
        Result += '   Expected in Azure:\';
        Result += '   • Key Vault: [From Function App config]\';
        Result += '   • Certificate Name: ' + Setup."Certificate ID" + '\';
        Result += '   Note: Verify in Azure Portal that:\';
        Result += '     1. Certificate exists in Key Vault\';
        Result += '     2. Function App has Get/List permissions\';
        Result += '     3. Function App Managed Identity is enabled\';
        /* end else begin
            Setup.CalcFields("Certificate Base64");
            if Setup."Certificate Base64".HasValue then begin
                Result += '   ✓ Certificate uploaded to BC\';
                if Setup."Certificate Password" <> '' then
                    Result += '   ✓ Password provided\';
            end;
        end; */

        exit(Result + '\');
    end;

    local procedure CheckNetworkConnectivity(Setup: Record "MY eInv Setup"): Text
    var
        Client: HttpClient;
        Response: HttpResponseMessage;
        Result: Text;
        TestUrl: Text;
    begin
        Result := '3. NETWORK CONNECTIVITY\';

        // Test basic connectivity to Azure
        TestUrl := CopyStr(Setup."Azure Function URL", 1, StrPos(Setup."Azure Function URL", '/api'));
        if TestUrl = '' then
            TestUrl := Setup."Azure Function URL";

        Client.Timeout := 5000;
        if Client.Get(TestUrl, Response) then
            Result += '   ✓ Can reach: ' + TestUrl + '\'
        else
            Result += '   ✗ Cannot reach: ' + TestUrl + '\';

        exit(Result + '\');
    end;

    local procedure TestMinimalRequest(Setup: Record "MY eInv Setup"): Text
    var
        Client: HttpClient;
        RequestMessage: HttpRequestMessage;
        ResponseMessage: HttpResponseMessage;
        Content: HttpContent;
        Headers: HttpHeaders;
        RequestBody: Text;
        ResponseBody: Text;
        Result: Text;
        JRequest: JsonObject;
    begin
        Result := '4. TEST REQUEST\';

        // Create minimal test request
        JRequest.Add('DocumentXml', '<?xml version="1.0"?><Test>Diagnostic</Test>');

        // if Setup."Certificate Source" = Setup."Certificate Source"::"Key Vault" then
        JRequest.Add('CertificateName', Setup."Certificate ID");
        /* else begin
            // For Base64, would need to add certificate data
            Result += '   • Using Base64 certificate from setup\';
        end; */

        JRequest.Add('UseXAdES', true);
        JRequest.WriteTo(RequestBody);

        // Setup request
        Content.WriteFrom(RequestBody);
        Content.GetHeaders(Headers);
        Headers.Clear();
        Headers.Add('Content-Type', 'application/json');

        RequestMessage.Method := 'POST';
        RequestMessage.SetRequestUri(Setup."Azure Function URL");
        RequestMessage.Content := Content;

        RequestMessage.GetHeaders(Headers);
        Headers.Add('x-functions-key', Setup.GetAzureFunctionKey());

        Client.Timeout := 30000;

        // Send request
        if Client.Send(RequestMessage, ResponseMessage) then begin
            ResponseMessage.Content.ReadAs(ResponseBody);
            Result += '   HTTP Status: ' + Format(ResponseMessage.HttpStatusCode) + '\';
            Result += '   Response Length: ' + Format(StrLen(ResponseBody)) + ' chars\';

            if ResponseMessage.IsSuccessStatusCode then begin
                Result += '   ✓ Request successful\';
            end else begin
                Result += '   ✗ Request failed\';
                Result += '   Error: ' + CopyStr(ResponseBody, 1, 200) + '\';
            end;
        end else begin
            Result += '   ✗ Request timeout or network error\';
        end;

        exit(Result + '\');
    end;

    procedure GetDetailedError(Setup: Record "MY eInv Setup"; DocumentXML: Text): Text
    var
        Client: HttpClient;
        RequestMessage: HttpRequestMessage;
        ResponseMessage: HttpResponseMessage;
        Content: HttpContent;
        Headers: HttpHeaders;
        RequestBody: Text;
        ResponseBody: Text;
        JRequest: JsonObject;
        JResponse: JsonObject;
        JToken: JsonToken;
        ErrorDetails: Text;
    begin
        // Build full request
        JRequest.Add('DocumentXml', DocumentXML);

        // if Setup."Certificate Source" = Setup."Certificate Source"::"Key Vault" then begin
        if Setup."Certificate ID" <> '' then
            JRequest.Add('CertificateName', Setup."Certificate ID");
        /* end else begin
            Setup.CalcFields("Certificate Base64");
            if Setup."Certificate Base64".HasValue then begin
                // Add Base64 certificate
                // Note: This needs to be implemented based on how you store it
                Message('Base64 certificate mode - ensure certificate is properly encoded');
            end;
        end; */

        JRequest.Add('UseXAdES', true);
        JRequest.WriteTo(RequestBody);

        // Setup request
        Content.WriteFrom(RequestBody);
        Content.GetHeaders(Headers);
        Headers.Clear();
        Headers.Add('Content-Type', 'application/json');

        RequestMessage.Method := 'POST';
        RequestMessage.SetRequestUri(Setup."Azure Function URL");
        RequestMessage.Content := Content;

        RequestMessage.GetHeaders(Headers);
        Headers.Add('x-functions-key', Setup.GetAzureFunctionKey());
        Headers.Add('X-Company-Name', Setup."Certificate ID");

        Client.Timeout := 30000;

        // Send and analyze response
        if Client.Send(RequestMessage, ResponseMessage) then begin
            ResponseMessage.Content.ReadAs(ResponseBody);

            ErrorDetails := 'HTTP Status: ' + Format(ResponseMessage.HttpStatusCode) + '\';
            ErrorDetails += 'Response: ' + ResponseBody + '\';

            // Try to parse JSON error
            if JResponse.ReadFrom(ResponseBody) then begin
                if JResponse.Get('ErrorMessage', JToken) then
                    ErrorDetails += 'Error Message: ' + JToken.AsValue().AsText();

                if JResponse.Get('error', JToken) then
                    ErrorDetails += 'Error: ' + JToken.AsValue().AsText();
            end;
        end else begin
            ErrorDetails := 'Connection failed - timeout or network error';
        end;

        exit(ErrorDetails);
    end;

    procedure ExportRequestForDebug(Setup: Record "MY eInv Setup"; DocumentXML: Text): Text
    var
        JRequest: JsonObject;
        RequestBody: Text;
    begin
        JRequest.Add('DocumentXml', CopyStr(DocumentXML, 1, 500) + '...');
        JRequest.Add('CertificateName', Setup."Certificate ID");
        JRequest.Add('UseXAdES', true);
        JRequest.WriteTo(RequestBody);

        exit(RequestBody);
    end;

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
        CertificateId: Text;
    begin
        // Get certificate ID from setup
        CertificateId := Setup."Certificate ID";

        if CertificateId = '' then
            Error('Certificate ID is not configured. Please specify the certificate name from Azure Key Vault.');

        // Build JSON request matching Azure Function's XmlSignRequest class
        JRequest.Add('XmlContent', DocumentXML);
        JRequest.Add('CertificateId', CertificateId);

        exit(FormatJson(JRequest));
    end;

    local procedure GetSigningURL(Setup: Record "MY eInv Setup"): Text
    var
        URL: Text;
        FunctionKey: Text;
    begin
        URL := Setup."Azure Function URL";

        if URL = '' then
            Error('Azure Function URL is not configured.');

        // Ensure URL ends with /SignXML if not already specified
        if not URL.EndsWith('/SignXML') then begin
            if not URL.EndsWith('/') then
                URL += '/';
            URL += 'SignXML';
        end;

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
        CertThumbprint: Text;
    begin
        // Read response content
        Response.Content.ReadAs(ResponseJson);

        // Check HTTP status
        if not Response.IsSuccessStatusCode then begin
            // Try to parse error response
            if JResponse.ReadFrom(ResponseJson) then begin
                if JResponse.Get('error', JToken) then
                    ErrorMessage := JToken.AsValue().AsText()
                else
                    ErrorMessage := ResponseJson;
            end else
                ErrorMessage := ResponseJson;

            Error('Signing service returned error: %1 - %2\Response: %3',
                Response.HttpStatusCode,
                Response.ReasonPhrase,
                ErrorMessage);
        end;

        // Parse successful response
        if not JResponse.ReadFrom(ResponseJson) then
            Error('Invalid response from signing service. Response: %1', ResponseJson);

        // Check success flag (lowercase 'success')
        if JResponse.Get('success', JToken) then begin
            if not JToken.AsValue().AsBoolean() then begin
                ErrorMessage := 'Signing failed';
                if JResponse.Get('error', JToken) then
                    ErrorMessage += ': ' + JToken.AsValue().AsText();
                Error(ErrorMessage);
            end;
        end else
            Error('Response does not contain success flag. Response: %1', ResponseJson);

        // Extract signed XML (lowercase 'signedXml')
        if not JResponse.Get('signedXml', JToken) then
            Error('Signed XML not found in response. Response: %1', ResponseJson);

        SignedXML := JToken.AsValue().AsText();

        if SignedXML = '' then
            Error('Signed XML is empty.');

        // Optionally log certificate thumbprint for verification
        if JResponse.Get('certificateThumbprint', JToken) then begin
            CertThumbprint := JToken.AsValue().AsText();
            Message('Document signed successfully using certificate: %1', CertThumbprint);
        end;

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