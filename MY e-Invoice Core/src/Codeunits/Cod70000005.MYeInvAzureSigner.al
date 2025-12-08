// ═════════════════════════════════════════════════════════════════
// CODEUNIT 70000005: MY eInv Azure Signer
// Handles communication with Azure Function (Key Vault Integration)
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