codeunit 70000008 "MY eInv Submission"
{
    var
        AccessToken: Text;
        TokenExpiry: DateTime;

    procedure SubmitDocument(DocumentXML: Text; SalesInvoiceHeader: Record "Sales Invoice Header"): Boolean
    var
        Setup: Record "MY eInv Setup";
        Authentication: Codeunit "MY eInv Authentication";
        SubmissionLog: Record "MY eInv Submission Log";
        SubmissionUID: Text;
        DocumentHash: Text;
        ResponseText: Text;
        AccessToken: Text;
        Success: Boolean;
    begin
        Setup.Get();

        // Get valid access token using existing authentication
        AccessToken := Authentication.GetValidToken(Setup);
        if AccessToken = '' then
            Error('Failed to obtain access token from MyInvois API.');

        // Submit the document
        Success := SubmitToMyInvois(DocumentXML, Setup, AccessToken, SalesInvoiceHeader."No.", SubmissionUID, DocumentHash, ResponseText);

        // Create submission log
        CreateSubmissionLog(SubmissionLog, SalesInvoiceHeader, SubmissionUID, DocumentHash, Success, ResponseText);

        // Update invoice header
        if Success then
            UpdateInvoiceHeader(SalesInvoiceHeader, SubmissionUID, DocumentHash);

        exit(Success);
    end;

    local procedure SubmitToMyInvois(
        DocumentXML: Text;
        Setup: Record "MY eInv Setup";
        AccessToken: Text;
        DocumentNo: Code[20];
        var SubmissionUID: Text;
        var DocumentHash: Text;
        var ResponseText: Text): Boolean
    var
        Client: HttpClient;
        RequestMessage: HttpRequestMessage;
        ResponseMessage: HttpResponseMessage;
        Headers: HttpHeaders;
        Content: HttpContent;
        ContentHeaders: HttpHeaders;
        RequestJson: JsonObject;
        RequestArray: JsonArray;
        DocumentObject: JsonObject;
        ResponseJson: JsonObject;
        RequestBody: Text;
        ApiUrl: Text;
        Base64XML: Text;
    begin
        // Build API URL - use the correct field name from your setup
        ApiUrl := Setup."API Base URL";  // or "MyInvois API URL" - check your table
        if not ApiUrl.EndsWith('/') then
            ApiUrl += '/';
        ApiUrl += 'api/v1.0/documentsubmissions';

        // Encode XML to Base64
        Base64XML := EncodeBase64(DocumentXML);

        // Calculate document hash (SHA-256)
        DocumentHash := CalculateSHA256Hash(DocumentXML);

        // Build JSON request according to MyInvois API spec
        DocumentObject.Add('format', 'XML');
        DocumentObject.Add('documentHash', DocumentHash);
        DocumentObject.Add('codeNumber', DocumentNo);
        DocumentObject.Add('document', Base64XML);

        RequestArray.Add(DocumentObject);
        RequestJson.Add('documents', RequestArray);
        RequestJson.WriteTo(RequestBody);

        // Setup HTTP request
        Content.WriteFrom(RequestBody);
        Content.GetHeaders(ContentHeaders);
        ContentHeaders.Clear();
        ContentHeaders.Add('Content-Type', 'application/json');

        RequestMessage.Content := Content;
        RequestMessage.Method := 'POST';
        RequestMessage.SetRequestUri(ApiUrl);

        // Add authorization header
        RequestMessage.GetHeaders(Headers);
        Headers.Add('Authorization', 'Bearer ' + AccessToken);

        // Set timeout
        Client.Timeout(Setup."Timeout (Seconds)" * 1000);

        // Send request
        if not Client.Send(RequestMessage, ResponseMessage) then begin
            ResponseText := 'Failed to connect to MyInvois API';
            exit(false);
        end;

        // Read response
        ResponseMessage.Content.ReadAs(ResponseText);

        // Check HTTP status
        if not ResponseMessage.IsSuccessStatusCode then begin
            LogError('MyInvois API Error', ResponseMessage.HttpStatusCode, ResponseText, '01', DocumentNo, RequestBody, ResponseText);
            exit(false);
        end;

        // Parse response
        if not ResponseJson.ReadFrom(ResponseText) then begin
            ResponseText := 'Failed to parse API response: ' + ResponseText;
            exit(false);
        end;

        // Extract submission UID
        if not GetSubmissionUID(ResponseJson, SubmissionUID) then begin
            ResponseText := 'Response does not contain submission UID';
            exit(false);
        end;

        exit(true);
    end;

    local procedure GetSubmissionUID(ResponseJson: JsonObject; var SubmissionUID: Text): Boolean
    var
        JsonToken: JsonToken;
    begin
        // Extract submissionUid from response
        if not ResponseJson.Get('submissionUid', JsonToken) then
            exit(false);

        SubmissionUID := JsonToken.AsValue().AsText();
        exit(SubmissionUID <> '');
    end;


    // ═════════════════════════════════════════════════════════════════
    // Document Status Check
    // ═════════════════════════════════════════════════════════════════

    procedure CheckDocumentStatus(SubmissionUID: Text; Setup: Record "MY eInv Setup"; var Status: Text; var StatusReason: Text): Boolean
    var
        Authentication: Codeunit "MY eInv Authentication";
        Client: HttpClient;
        RequestMessage: HttpRequestMessage;
        ResponseMessage: HttpResponseMessage;
        Headers: HttpHeaders;
        ResponseJson: JsonObject;
        ResponseText: Text;
        ApiUrl: Text;
        JsonToken: JsonToken;
        AccessToken: Text;
    begin
        // Get valid token
        AccessToken := Authentication.GetValidToken(Setup);
        if AccessToken = '' then
            exit(false);

        // Build API URL
        ApiUrl := Setup."API Base URL";  // or "MyInvois API URL"
        if not ApiUrl.EndsWith('/') then
            ApiUrl += '/';
        ApiUrl += 'api/v1.0/documentsubmissions/' + SubmissionUID;

        // Setup request
        RequestMessage.Method := 'GET';
        RequestMessage.SetRequestUri(ApiUrl);
        RequestMessage.GetHeaders(Headers);
        Headers.Add('Authorization', 'Bearer ' + AccessToken);

        // Set timeout
        Client.Timeout(Setup."Timeout (Seconds)" * 1000);

        // Send request
        if not Client.Send(RequestMessage, ResponseMessage) then
            exit(false);

        // Read response
        ResponseMessage.Content.ReadAs(ResponseText);

        if not ResponseMessage.IsSuccessStatusCode then
            exit(false);

        // Parse response
        if not ResponseJson.ReadFrom(ResponseText) then
            exit(false);

        // Extract status
        if ResponseJson.Get('status', JsonToken) then
            Status := JsonToken.AsValue().AsText();

        if ResponseJson.Get('statusReason', JsonToken) then
            StatusReason := JsonToken.AsValue().AsText();

        exit(true);
    end;

    // ═════════════════════════════════════════════════════════════════
    // Document Cancellation
    // ═════════════════════════════════════════════════════════════════

    procedure CancelDocument(SubmissionUID: Text; Reason: Text; Setup: Record "MY eInv Setup"): Boolean
    var
        Authentication: Codeunit "MY eInv Authentication";
        Client: HttpClient;
        RequestMessage: HttpRequestMessage;
        ResponseMessage: HttpResponseMessage;
        Headers: HttpHeaders;
        Content: HttpContent;
        ContentHeaders: HttpHeaders;
        RequestJson: JsonObject;
        RequestBody: Text;
        ApiUrl: Text;
        AccessToken: Text;
    begin
        // Get valid token
        AccessToken := Authentication.GetValidToken(Setup);
        if AccessToken = '' then
            exit(false);

        // Build API URL
        ApiUrl := Setup."API Base URL";  // or "MyInvois API URL"
        if not ApiUrl.EndsWith('/') then
            ApiUrl += '/';
        ApiUrl += 'api/v1.0/documentsubmissions/' + SubmissionUID + '/cancel';

        // Build request
        RequestJson.Add('reason', Reason);
        RequestJson.WriteTo(RequestBody);

        Content.WriteFrom(RequestBody);
        Content.GetHeaders(ContentHeaders);
        ContentHeaders.Clear();
        ContentHeaders.Add('Content-Type', 'application/json');

        RequestMessage.Content := Content;
        RequestMessage.Method := 'PUT';
        RequestMessage.SetRequestUri(ApiUrl);
        RequestMessage.GetHeaders(Headers);
        Headers.Add('Authorization', 'Bearer ' + AccessToken);

        // Set timeout
        Client.Timeout(Setup."Timeout (Seconds)" * 1000);

        // Send request
        if not Client.Send(RequestMessage, ResponseMessage) then
            exit(false);

        exit(ResponseMessage.IsSuccessStatusCode);
    end;

    // ═════════════════════════════════════════════════════════════════
    // Helper Functions
    // ═════════════════════════════════════════════════════════════════

    local procedure EncodeBase64(InputText: Text): Text
    var
        Base64Convert: Codeunit "Base64 Convert";
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
        InStream: InStream;
    begin
        TempBlob.CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(InputText);
        TempBlob.CreateInStream(InStream, TextEncoding::UTF8);
        exit(Base64Convert.ToBase64(InStream));
    end;

    local procedure CalculateSHA256Hash(InputText: Text): Text
    var
        CryptographyManagement: Codeunit "Cryptography Management";
        HashAlgorithmType: Option MD5,SHA1,SHA256,SHA384,SHA512;
    begin
        exit(CryptographyManagement.GenerateHash(InputText, HashAlgorithmType::SHA256));
    end;

    local procedure CreateSubmissionLog(
        var SubmissionLog: Record "MY eInv Submission Log";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SubmissionUID: Text;
        DocumentHash: Text;
        Success: Boolean;
        ResponseText: Text)
    begin
        SubmissionLog.Init();
        SubmissionLog."Entry No." := GetNextLogEntryNo();
        SubmissionLog."Document Type" := '01';  // Use code instead of option
        SubmissionLog."Document No." := SalesInvoiceHeader."No.";
        SubmissionLog."Submission Date Time" := CurrentDateTime;
        SubmissionLog."Submission UID" := CopyStr(SubmissionUID, 1, MaxStrLen(SubmissionLog."Submission UID"));
        SubmissionLog."Document Hash" := CopyStr(DocumentHash, 1, MaxStrLen(SubmissionLog."Document Hash"));
        SubmissionLog.Success := Success;
        SubmissionLog."Response Text" := CopyStr(ResponseText, 1, MaxStrLen(SubmissionLog."Response Text"));
        SubmissionLog."User ID" := CopyStr(UserId, 1, MaxStrLen(SubmissionLog."User ID"));
        SubmissionLog.Insert();
    end;


    local procedure UpdateInvoiceHeader(var SalesInvoiceHeader: Record "Sales Invoice Header"; SubmissionUID: Text; DocumentHash: Text)
    begin
        SalesInvoiceHeader."MY eInv Submission UID" := CopyStr(SubmissionUID, 1, MaxStrLen(SalesInvoiceHeader."MY eInv Submission UID"));
        SalesInvoiceHeader."MY eInv Document Hash" := CopyStr(DocumentHash, 1, MaxStrLen(SalesInvoiceHeader."MY eInv Document Hash"));
        SalesInvoiceHeader."MY eInv Submission Date" := Today;
        SalesInvoiceHeader."MY eInv Status" := SalesInvoiceHeader."MY eInv Status"::Submitted;
        SalesInvoiceHeader.Modify();
    end;

    local procedure GetNextLogEntryNo(): Integer
    var
        SubmissionLog: Record "MY eInv Submission Log";
    begin
        if SubmissionLog.FindLast() then
            exit(SubmissionLog."Entry No." + 1);
        exit(1);
    end;

    local procedure LogError(ErrorType: Text; StatusCode: Integer; ErrorMessage: Text; DocumentType: Code[20]; DocumentNo: Code[20]; RequestBody: Text; ResponseBody: Text)
    var
        ErrorLog: Record "MY eInv Error Log";
    begin
        ErrorLog.Init();
        ErrorLog."Entry No." := GetNextErrorLogEntryNo();
        ErrorLog."Error DateTime" := CurrentDateTime;
        ErrorLog."Error Type" := CopyStr(ErrorType, 1, MaxStrLen(ErrorLog."Error Type"));
        ErrorLog."HTTP Status Code" := StatusCode;
        ErrorLog."Error Message" := CopyStr(ErrorMessage, 1, MaxStrLen(ErrorLog."Error Message"));
        ErrorLog."Document Type" := DocumentType;
        ErrorLog."Document No." := DocumentNo;
        ErrorLog."User ID" := CopyStr(UserId, 1, MaxStrLen(ErrorLog."User ID"));

        if RequestBody <> '' then
            ErrorLog.SetRequestBody(RequestBody);

        if ResponseBody <> '' then
            ErrorLog.SetResponseBody(ResponseBody);

        ErrorLog.Insert();
    end;

    local procedure GetNextErrorLogEntryNo(): Integer
    var
        ErrorLog: Record "MY eInv Error Log";
    begin
        if ErrorLog.FindLast() then
            exit(ErrorLog."Entry No." + 1);
        exit(1);
    end;

    // ═════════════════════════════════════════════════════════════════
    // Batch Submission
    // ═════════════════════════════════════════════════════════════════

    procedure SubmitMultipleDocuments(var SalesInvoiceHeader: Record "Sales Invoice Header"): Integer
    var
        Setup: Record "MY eInv Setup";
        XMLGenerator: Codeunit "MY eInv XML Generator";
        DigitalSignature: Codeunit "MY eInv Digital Signature";
        InvoiceXML: Text;
        SignedXML: Text;
        SuccessCount: Integer;
    begin
        Setup.Get();
        SuccessCount := 0;

        if SalesInvoiceHeader.FindSet() then
            repeat
                // Generate XML
                InvoiceXML := XMLGenerator.GenerateInvoiceXML(SalesInvoiceHeader);

                // Sign if Document Version 1.1 is selected (With Signature)
                if Setup."Document Version" = Setup."Document Version"::"1.1" then
                    SignedXML := DigitalSignature.SignDocument(InvoiceXML, Setup)
                else
                    SignedXML := InvoiceXML;

                // Submit
                if SubmitDocument(SignedXML, SalesInvoiceHeader) then
                    SuccessCount += 1;

                Commit();
            until SalesInvoiceHeader.Next() = 0;

        exit(SuccessCount);
    end;

    // ═════════════════════════════════════════════════════════════════
    // Test Connection (now uses existing authentication)
    // ═════════════════════════════════════════════════════════════════

    procedure TestConnection(Setup: Record "MY eInv Setup"): Boolean
    var
        Authentication: Codeunit "MY eInv Authentication";
    begin
        exit(Authentication.TestConnectionAndVerifyTIN(Setup));
    end;
}