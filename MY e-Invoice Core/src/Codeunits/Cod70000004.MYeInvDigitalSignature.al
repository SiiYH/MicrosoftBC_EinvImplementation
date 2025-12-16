codeunit 70000004 "MY eInv Digital Signature"
{
    var
        SigningFailedErr: Label 'Document signing failed: %1';
        InvalidResponseErr: Label 'Invalid response from signing service';
        EmptyXMLErr: Label 'Document XML cannot be empty';
        TimeoutErr: Label 'Signing service request timed out. Please check your internet connection and Azure Function status.';
        NoCertificateErr: Label 'Certificate ID is not configured. Please configure it in MY eInv Setup.';
        NoFunctionKeyErr: Label 'Azure Function Key is not configured. Please configure it in MY eInv Setup.';
        InvalidURLErr: Label 'Azure Function URL is not valid. It must start with https://';

    procedure SignDocument(DocumentXML: Text; Setup: Record "MY eInv Setup") SignedXML: Text
    var
        ErrorMessage: Text;
    begin
        if not SignDocumentWithError(DocumentXML, Setup, SignedXML, ErrorMessage) then
            Error(SigningFailedErr, ErrorMessage);
    end;

    procedure SignDocumentWithError(DocumentXML: Text; Setup: Record "MY eInv Setup"; var SignedXML: Text; var ErrorMessage: Text): Boolean
    var
        Client: HttpClient;
        RequestMessage: HttpRequestMessage;
        ResponseMessage: HttpResponseMessage;
        Content: HttpContent;
        Headers: HttpHeaders;
        RequestBody: Text;
        ResponseBody: Text;
        SigningURL: Text;
        StatusCode: Integer;
    begin
        // Validate input
        if DocumentXML = '' then begin
            ErrorMessage := EmptyXMLErr;
            exit(false);
        end;

        // Validate setup
        if not ValidateSetup(Setup, ErrorMessage) then
            exit(false);

        // Build full signing URL
        SigningURL := Setup."Azure Function URL";
        if not SigningURL.EndsWith('/') then
            SigningURL += '/';
        SigningURL += 'api/SignDocument';

        // Build request body
        RequestBody := BuildSigningRequest(DocumentXML, Setup);

        // Setup HTTP request
        Content.WriteFrom(RequestBody);
        Content.GetHeaders(Headers);
        Headers.Clear();
        Headers.Add('Content-Type', 'application/json');

        RequestMessage.Method := 'POST';
        RequestMessage.SetRequestUri(SigningURL);
        RequestMessage.Content := Content;

        // Add authentication header
        RequestMessage.GetHeaders(Headers);
        Headers.Add('x-functions-key', Setup.GetAzureFunctionKey());

        // Add custom headers for logging/tracking
        if Setup."Certificate ID" <> '' then
            Headers.Add('X-Certificate-ID', CopyStr(Setup."Certificate ID", 1, 50));
        Headers.Add('X-Company-Name', CopyStr(CompanyName(), 1, 50));

        // Set timeout (30 seconds)
        Client.Timeout := 30000;

        // Send request
        if not Client.Send(RequestMessage, ResponseMessage) then begin
            ErrorMessage := TimeoutErr;
            LogSigningAttempt(0, 'Timeout', Setup);
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

    local procedure ValidateSetup(Setup: Record "MY eInv Setup"; var ErrorMessage: Text): Boolean
    begin
        if Setup."Azure Function URL" = '' then begin
            ErrorMessage := 'Azure Function URL is not configured';
            exit(false);
        end;

        if not Setup."Azure Function URL".StartsWith('https://') then begin
            ErrorMessage := InvalidURLErr;
            exit(false);
        end;

        if Setup."Certificate ID" = '' then begin
            ErrorMessage := NoCertificateErr;
            exit(false);
        end;

        if Setup.GetAzureFunctionKey() = '' then begin
            ErrorMessage := NoFunctionKeyErr;
            exit(false);
        end;

        exit(true);
    end;

    local procedure BuildSigningRequest(DocumentXML: Text; Setup: Record "MY eInv Setup") RequestBody: Text
    var
        JRequest: JsonObject;
    begin
        JRequest.Add('DocumentXml', DocumentXML);

        // Use certificate from Azure Key Vault
        if Setup."Certificate ID" <> '' then
            JRequest.Add('CertificateName', Setup."Certificate ID");

        JRequest.Add('UseXAdES', true); // Always use XAdES for LHDN

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
                ErrorMessage += ': ' + JToken.AsValue().AsText()
            else if JResponse.Get('message', JToken) then
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

    procedure TestConnection(Setup: Record "MY eInv Setup") TestResult: Text
    var
        Client: HttpClient;
        ResponseMessage: HttpResponseMessage;
        HealthURL: Text;
        ErrorMessage: Text;
    begin
        // Validate setup first
        if not ValidateSetup(Setup, ErrorMessage) then
            exit('Configuration Error: ' + ErrorMessage);

        // Build Health endpoint URL
        HealthURL := Setup."Azure Function URL";
        if not HealthURL.EndsWith('/') then
            HealthURL += '/';
        HealthURL += 'api/Health';

        // Add function key
        Client.DefaultRequestHeaders.Add('x-functions-key', Setup.GetAzureFunctionKey());
        Client.Timeout := 10000; // 10 seconds for test

        if not Client.Get(HealthURL, ResponseMessage) then
            exit('Connection failed: Timeout or network error');

        if ResponseMessage.IsSuccessStatusCode then
            exit('✓ Connection successful (HTTP 200)')
        else
            exit(StrSubstNo('✗ Connection failed with HTTP %1', ResponseMessage.HttpStatusCode));
    end;

    procedure ExportXMLWithSigning(DocumentXML: Text; Setup: Record "MY eInv Setup"; FileName: Text)
    var
        SignedXML: Text;
        ErrorMessage: Text;
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
        InStr: InStream;
        ActualFileName: Text;
    begin
        // Sign the document
        if not SignDocumentWithError(DocumentXML, Setup, SignedXML, ErrorMessage) then
            Error('Failed to sign document: %1', ErrorMessage);

        // Create file name if not provided
        if FileName = '' then
            FileName := 'signed-' + Format(CurrentDateTime, 0, '<Year4><Month,2><Day,2>-<Hours24><Minutes,2><Seconds,2>') + '.xml';

        // Write to temp blob
        TempBlob.CreateOutStream(OutStr, TextEncoding::UTF8);

        // Only add XML declaration if not already present
        if not SignedXML.StartsWith('<?xml') then
            OutStr.WriteText('<?xml version="1.0" encoding="UTF-8"?>');

        OutStr.WriteText(SignedXML);

        // Download file
        TempBlob.CreateInStream(InStr, TextEncoding::UTF8);
        DownloadFromStream(InStr, 'Export Signed XML', '', 'XML Files (*.xml)|*.xml', ActualFileName);

        Message('Signed XML exported successfully');
    end;

    procedure ExportXMLWithoutSigning(DocumentXML: Text; FileName: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
        InStr: InStream;
        ActualFileName: Text;
    begin
        // Create file name if not provided
        if FileName = '' then
            FileName := 'unsigned-' + Format(CurrentDateTime, 0, '<Year4><Month,2><Day,2>-<Hours24><Minutes,2><Seconds,2>') + '.xml';

        // Write to temp blob
        TempBlob.CreateOutStream(OutStr, TextEncoding::UTF8);

        // Only add XML declaration if not already present
        if not DocumentXML.StartsWith('<?xml') then
            OutStr.WriteText('<?xml version="1.0" encoding="UTF-8"?>');

        OutStr.WriteText(DocumentXML);

        // Download file
        TempBlob.CreateInStream(InStr, TextEncoding::UTF8);
        DownloadFromStream(InStr, 'Export XML', '', 'XML Files (*.xml)|*.xml', ActualFileName);

        Message('XML exported successfully');
    end;

    procedure GetLastError(): Text
    begin
        exit(GetLastErrorText());
    end;
}