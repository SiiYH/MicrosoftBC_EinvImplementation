codeunit 70000004 "MY eInv Digital Signature"
{
    var
        SigningFailedErr: Label 'Document signing failed: %1';
        InvalidResponseErr: Label 'Invalid response from signing service';
        EmptyXMLErr: Label 'Document XML cannot be empty';
        TimeoutErr: Label 'Signing service request timed out';

    procedure SignDocument(DocumentXML: Text; Setup: Record "MY eInv Setup") SignedXML: Text
    var
        ErrorMessage: Text;
    begin
        if not SignDocumentWithError(DocumentXML, Setup, SignedXML, ErrorMessage) then
            Error(SigningFailedErr, ErrorMessage);
    end;

    procedure SignDocumentWithError(DocumentXML: Text; Setup: Record "MY eInv Setup"; var SignedXML: Text; var ErrorMessage: Text): Boolean
    var
        eInvAuth: Codeunit "MY eInv Authentication";
        Client: HttpClient;
        RequestMessage: HttpRequestMessage;
        ResponseMessage: HttpResponseMessage;
        Content: HttpContent;
        Headers: HttpHeaders;
        RequestBody: Text;
        ResponseBody: Text;
        AzureFunctionKey: Text;
        JResponse: JsonObject;
        JToken: JsonToken;
        StatusCode: Integer;
    begin
        // Validate input
        if DocumentXML = '' then begin
            ErrorMessage := EmptyXMLErr;
            exit(false);
        end;

        Setup.TestField("Azure Function URL");
        AzureFunctionKey := eInvAuth.GetAzureFunctionKey(Setup);
        if AzureFunctionKey = '' then
            Error('Azure Function Key is not configured.');

        // Build request body
        RequestBody := BuildSigningRequest(DocumentXML, Setup);

        // Setup HTTP request
        Content.WriteFrom(RequestBody);
        Content.GetHeaders(Headers);
        Headers.Clear();
        Headers.Add('Content-Type', 'application/json');

        RequestMessage.Method := 'POST';
        RequestMessage.SetRequestUri(Setup."Azure Function URL".TrimEnd('/') + '/api/SignDocument');
        RequestMessage.Content := Content;

        // Add authentication header
        RequestMessage.GetHeaders(Headers);
        Headers.Add('x-functions-key', AzureFunctionKey);

        // Add custom headers for logging/tracking
        if Setup."Certificate ID" <> '' then
            Headers.Add('X-Company-Name', Setup."Certificate ID");
        Headers.Add('X-Customer-Id', CopyStr(CompanyName(), 1, 50));

        // Set timeout (30 seconds)
        Client.Timeout := 30000;

        // Send request
        if not Client.Send(RequestMessage, ResponseMessage) then begin
            ErrorMessage := TimeoutErr;
            exit(false);
        end;

        // Read response
        ResponseMessage.Content.ReadAs(ResponseBody);
        StatusCode := ResponseMessage.HttpStatusCode;

        // Log for debugging
        LogSigningAttempt(StatusCode, ResponseBody, Setup);

        // Handle response
        if not ResponseMessage.IsSuccessStatusCode then begin
            ErrorMessage := ParseErrorResponse(ResponseBody, StatusCode);
            exit(false);
        end;

        // Parse successful response
        if not ParseSigningResponse(ResponseBody, SignedXML, ErrorMessage) then
            exit(false);

        exit(true);
    end;

    local procedure BuildSigningRequest(DocumentXML: Text; Setup: Record "MY eInv Setup") RequestBody: Text
    var
        JRequest: JsonObject;
    begin
        JRequest.Add('DocumentXml', DocumentXML);

        // Choose certificate source
        /* case Setup."Certificate Source" of
            Setup."Certificate Source"::"Key Vault":
                begin */
        // Use certificate from Azure Key Vault
        if Setup."Certificate ID" <> '' then
            JRequest.Add('CertificateName', Setup."Certificate ID");
        JRequest.Add('UseXAdES', true); // Always use XAdES for LHDN
                                        /* end;
                                    Setup."Certificate Source"::"Base64":
                                        begin
                                            // Legacy: Use certificate from setup (if stored)
                                            if Setup."Certificate Base64" <> '' then begin
                                                JRequest.Add('CertificateBase64', Setup."Certificate Base64");
                                                if Setup."Certificate Password" <> '' then
                                                    JRequest.Add('CertificatePassword', Setup."Certificate Password");
                                            end;
                                            JRequest.Add('UseXAdES', true);
                                        end;
                                end; */

        JRequest.WriteTo(RequestBody);
    end;

    local procedure ParseSigningResponse(ResponseBody: Text; var SignedXML: Text; var ErrorMessage: Text): Boolean
    var
        JResponse: JsonObject;
        JToken: JsonToken;
    begin
        if not JResponse.ReadFrom(ResponseBody) then begin
            ErrorMessage := InvalidResponseErr;
            exit(false);
        end;

        // Check success flag
        if JResponse.Get('Success', JToken) then begin
            if not JToken.AsValue().AsBoolean() then begin
                if JResponse.Get('ErrorMessage', JToken) then
                    ErrorMessage := JToken.AsValue().AsText()
                else
                    ErrorMessage := 'Signing failed with unknown error';
                exit(false);
            end;
        end;

        // Get signed XML
        if not JResponse.Get('SignedXml', JToken) then begin
            ErrorMessage := 'SignedXml not found in response';
            exit(false);
        end;

        SignedXML := JToken.AsValue().AsText();

        if SignedXML = '' then begin
            ErrorMessage := 'SignedXml is empty';
            exit(false);
        end;

        exit(true);
    end;

    local procedure ParseErrorResponse(ResponseBody: Text; StatusCode: Integer) ErrorMessage: Text
    var
        JResponse: JsonObject;
        JToken: JsonToken;
    begin
        ErrorMessage := StrSubstNo('HTTP %1', StatusCode);

        if JResponse.ReadFrom(ResponseBody) then begin
            if JResponse.Get('ErrorMessage', JToken) then
                ErrorMessage += ': ' + JToken.AsValue().AsText()
            else if JResponse.Get('error', JToken) then
                ErrorMessage += ': ' + JToken.AsValue().AsText();
        end else begin
            // If response is plain text
            if ResponseBody <> '' then
                ErrorMessage += ': ' + CopyStr(ResponseBody, 1, 250);
        end;
    end;

    local procedure LogSigningAttempt(StatusCode: Integer; ResponseBody: Text; Setup: Record "MY eInv Setup")
    var
        ActivityLog: Record "Activity Log";
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Setup);

        if StatusCode = 200 then
            ActivityLog.LogActivity(
                RecRef,
                ActivityLog.Status::Success,
                'SIGN',
                'Document signing successful',
                CopyStr('Certificate: ' + Setup."Certificate ID", 1, 250))
        else
            ActivityLog.LogActivity(
                RecRef,
                ActivityLog.Status::Failed,
                'SIGN',
                StrSubstNo('Document signing failed (HTTP %1)', StatusCode),
                CopyStr(ResponseBody, 1, 250));
    end;

    /* procedure TestConnection(Setup: Record "MY eInv Setup") TestResult: Text
    var
        eInvAuth: Codeunit "MY eInv Authentication";
        Client: HttpClient;
        RequestMessage: HttpRequestMessage;
        ResponseMessage: HttpResponseMessage;
        Headers: HttpHeaders;
        TestXML: Text;
        AzureFunctionKey: Text;
    begin
        AzureFunctionKey := eInvAuth.GetAzureFunctionKey(Setup);
        if AzureFunctionKey = '' then
            Error('Azure Function Key is not configured.');

        // Simple test XML
        TestXML := '<?xml version="1.0" encoding="UTF-8"?><Test>Connection Test</Test>';

        Setup.TestField("Signing Service URL");

        RequestMessage.Method := 'POST';
        RequestMessage.SetRequestUri(Setup."Signing Service URL");
        RequestMessage.GetHeaders(Headers);
        Headers.Add('x-functions-key', AzureFunctionKey);

        Client.Timeout := 10000; // 10 seconds for test

        if not Client.Send(RequestMessage, ResponseMessage) then
            exit('Connection failed: Timeout or network error');

        if ResponseMessage.IsSuccessStatusCode then
            exit('Connection successful')
        else
            exit(StrSubstNo('Connection failed with HTTP %1', ResponseMessage.HttpStatusCode));
    end; */
}
