codeunit 70000008 "MY eInv Submission"
{
    var
        AccessToken: Text;
        TokenExpiry: DateTime;

    procedure SubmitDocument(DocumentXML: Text; DocumentVariant: Variant; DocumentType: Text): Boolean
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        case DocumentType of
            'Invoice':
                begin
                    SalesInvoiceHeader := DocumentVariant;
                    exit(SubmitInvoice(DocumentXML, SalesInvoiceHeader));
                end;
            'CreditMemo':
                begin
                    SalesCrMemoHeader := DocumentVariant;
                    exit(SubmitCreditMemo(DocumentXML, SalesCrMemoHeader));
                end;
            else
                Error('Unsupported document type: %1', DocumentType);
        end;
    end;

    procedure SubmitInvoice(DocumentXML: Text; SalesInvoiceHeader: Record "Sales Invoice Header"): Boolean
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

        // Get valid access token
        AccessToken := Authentication.GetValidToken(Setup);
        if AccessToken = '' then
            Error('Failed to obtain access token from MyInvois API.');

        // Submit the document
        Success := SubmitToMyInvois(DocumentXML, Setup, AccessToken, SalesInvoiceHeader."No.", SubmissionUID, DocumentHash, ResponseText);

        // Create submission log
        CreateInvoiceSubmissionLog(SubmissionLog, SalesInvoiceHeader, SubmissionUID, DocumentHash, Success, ResponseText);

        // Update invoice header
        if Success then
            UpdateInvoiceHeader(SalesInvoiceHeader, SubmissionUID, DocumentHash);

        exit(Success);
    end;

    procedure SubmitCreditMemo(DocumentXML: Text; SalesCrMemoHeader: Record "Sales Cr.Memo Header"): Boolean
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

        // Get valid access token
        AccessToken := Authentication.GetValidToken(Setup);
        if AccessToken = '' then
            Error('Failed to obtain access token from MyInvois API.');

        // Submit the document
        Success := SubmitToMyInvois(DocumentXML, Setup, AccessToken, SalesCrMemoHeader."No.", SubmissionUID, DocumentHash, ResponseText);

        // Create submission log
        CreateCreditMemoSubmissionLog(SubmissionLog, SalesCrMemoHeader, SubmissionUID, DocumentHash, Success, ResponseText);

        // Update credit memo header
        if Success then
            UpdateCreditMemoHeader(SalesCrMemoHeader, SubmissionUID, DocumentHash);

        exit(Success);
    end;


    // SHARED METHOD - Used by both Invoice and Credit Memo
    local procedure SubmitToMyInvois(DocumentXML: Text; Setup: Record "MY eInv Setup"; AccessToken: Text; DocumentNo: Code[20]; var SubmissionUID: Text; var DocumentHash: Text; var ResponseText: Text): Boolean
    var
        Client: HttpClient;
        RequestMessage: HttpRequestMessage;
        ResponseMessage: HttpResponseMessage;
        RequestHeaders: HttpHeaders;
        Content: HttpContent;
        ContentHeaders: HttpHeaders;
        JsonResponse: JsonObject;
        JsonToken: JsonToken;
        DocumentsArray: JsonArray;
        JsonBody: JsonObject;
        JsonDocuments: JsonArray;
        JsonDocument: JsonObject;
        RequestBody: Text;
        ApiUrl: Text;
    begin
        // Build API URL
        ApiUrl := Setup."API Base URL" + '/api/v1.0/documentsubmissions';

        // Build JSON request body
        JsonDocument.Add('format', 'XML');
        JsonDocument.Add('documentHash', ComputeDocumentHash(DocumentXML));
        JsonDocument.Add('codeNumber', DocumentNo);
        JsonDocument.Add('document', EncodeBase64(DocumentXML));

        JsonDocuments.Add(JsonDocument);
        JsonBody.Add('documents', JsonDocuments);
        JsonBody.WriteTo(RequestBody);

        // Setup HTTP request
        Content.WriteFrom(RequestBody);
        Content.GetHeaders(ContentHeaders);
        ContentHeaders.Remove('Content-Type');
        ContentHeaders.Add('Content-Type', 'application/json');

        RequestMessage.Method := 'POST';
        RequestMessage.SetRequestUri(ApiUrl);
        RequestMessage.Content := Content;

        RequestMessage.GetHeaders(RequestHeaders);
        RequestHeaders.Add('Authorization', 'Bearer ' + AccessToken);
        RequestHeaders.Add('Accept', 'application/json');
        RequestHeaders.Add('Accept-Language', 'en');

        // Send request
        if not Client.Send(RequestMessage, ResponseMessage) then begin
            ResponseText := 'Failed to connect to MyInvois API.';
            exit(false);
        end;

        // Read response
        ResponseMessage.Content.ReadAs(ResponseText);

        if not ResponseMessage.IsSuccessStatusCode then begin
            ResponseText := StrSubstNo('HTTP %1: %2', ResponseMessage.HttpStatusCode, ResponseText);
            exit(false);
        end;

        // Parse response
        if not JsonResponse.ReadFrom(ResponseText) then begin
            ResponseText := 'Invalid JSON response from MyInvois API.';
            exit(false);
        end;

        // Extract submission UID
        if JsonResponse.Get('submissionUid', JsonToken) then
            SubmissionUID := JsonToken.AsValue().AsText()
        else begin
            ResponseText := 'Response missing submissionUid.';
            exit(false);
        end;

        // Extract document hash from response (if available)
        if JsonResponse.Get('acceptedDocuments', JsonToken) then begin
            DocumentsArray := JsonToken.AsArray();
            if DocumentsArray.Count > 0 then begin
                DocumentsArray.Get(0, JsonToken);
                if JsonToken.AsObject().Get('documentHash', JsonToken) then
                    DocumentHash := JsonToken.AsValue().AsText();
            end;
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



    // INVOICE-SPECIFIC METHODS
    local procedure CreateInvoiceSubmissionLog(var SubmissionLog: Record "MY eInv Submission Log"; SalesInvoiceHeader: Record "Sales Invoice Header"; SubmissionUID: Text; DocumentHash: Text; Success: Boolean; ResponseText: Text)
    begin
        SubmissionLog.Init();
        SubmissionLog."Entry No." := GetNextEntryNo();
        SubmissionLog."Document Type" := '01';
        SubmissionLog."Document No." := SalesInvoiceHeader."No.";
        SubmissionLog."Submission Date Time" := CurrentDateTime;
        SubmissionLog."Submission UID" := CopyStr(SubmissionUID, 1, MaxStrLen(SubmissionLog."Submission UID"));
        SubmissionLog."Document Hash" := CopyStr(DocumentHash, 1, MaxStrLen(SubmissionLog."Document Hash"));
        SubmissionLog.Status := GetSubmissionStatus(Success);
        SubmissionLog."Response Text" := CopyStr(ResponseText, 1, MaxStrLen(SubmissionLog."Response Text"));
        SubmissionLog.Insert(true);
    end;

    local procedure UpdateInvoiceHeader(var SalesInvoiceHeader: Record "Sales Invoice Header"; SubmissionUID: Text; DocumentHash: Text)
    begin
        // Assuming you have these fields in your Sales Invoice Header extension
        SalesInvoiceHeader."MY eInv Submission UID" := CopyStr(SubmissionUID, 1, 50);
        SalesInvoiceHeader."MY eInv Document Hash" := CopyStr(DocumentHash, 1, 100);
        SalesInvoiceHeader."MY eInv Submitted" := true;
        SalesInvoiceHeader."MY eInv Submission Date" := Today;
        SalesInvoiceHeader.Modify(true);
    end;

    // CREDIT MEMO-SPECIFIC METHODS
    local procedure CreateCreditMemoSubmissionLog(var SubmissionLog: Record "MY eInv Submission Log"; SalesCrMemoHeader: Record "Sales Cr.Memo Header"; SubmissionUID: Text; DocumentHash: Text; Success: Boolean; ResponseText: Text)
    begin
        SubmissionLog.Init();
        SubmissionLog."Entry No." := GetNextEntryNo();
        SubmissionLog."Document Type" := '02';
        SubmissionLog."Document No." := SalesCrMemoHeader."No.";
        SubmissionLog."Submission Date Time" := CurrentDateTime;
        SubmissionLog."Submission UID" := CopyStr(SubmissionUID, 1, MaxStrLen(SubmissionLog."Submission UID"));
        SubmissionLog."Document Hash" := CopyStr(DocumentHash, 1, MaxStrLen(SubmissionLog."Document Hash"));
        SubmissionLog.Status := GetSubmissionStatus(Success);
        SubmissionLog."Response Text" := CopyStr(ResponseText, 1, MaxStrLen(SubmissionLog."Response Text"));
        SubmissionLog.Insert(true);
    end;

    local procedure UpdateCreditMemoHeader(var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; SubmissionUID: Text; DocumentHash: Text)
    begin
        // Assuming you have these fields in your Sales Cr.Memo Header extension
        SalesCrMemoHeader."MY eInv Submission UID" := CopyStr(SubmissionUID, 1, 50);
        SalesCrMemoHeader."MY eInv Document Hash" := CopyStr(DocumentHash, 1, 100);
        SalesCrMemoHeader."MY eInv Submitted" := true;
        SalesCrMemoHeader."MY eInv Submission Date" := Today;
        SalesCrMemoHeader.Modify(true);
    end;

    // SHARED HELPER METHODS
    local procedure GetNextEntryNo(): Integer
    var
        SubmissionLog: Record "MY eInv Submission Log";
    begin
        if SubmissionLog.FindLast() then
            exit(SubmissionLog."Entry No." + 1);
        exit(1);
    end;

    // ═════════════════════════════════════════════════════════════════
    // Helper Functions
    // ═════════════════════════════════════════════════════════════════

    local procedure GetSubmissionStatus(Success: Boolean): Enum "MY eInv Status"
    var
        SubmissionStatus: Enum "MY eInv Status";
    begin
        if Success then
            exit(SubmissionStatus::Submitted)
        else
            exit(SubmissionStatus::Rejected);
    end;

    local procedure ComputeDocumentHash(DocumentXML: Text): Text
    var
        CryptographyManagement: Codeunit "Cryptography Management";
        HashAlgorithmType: Option MD5,SHA1,SHA256,SHA384,SHA512;
    begin
        exit(CryptographyManagement.GenerateHash(DocumentXML, HashAlgorithmType::SHA256));
    end;

    local procedure EncodeBase64(InputText: Text): Text
    var
        Base64Convert: Codeunit "Base64 Convert";
        TempBlob: Codeunit "Temp Blob";
        InStream: InStream;
        OutStream: OutStream;
    begin
        TempBlob.CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(InputText);
        TempBlob.CreateInStream(InStream, TextEncoding::UTF8);
        exit(Base64Convert.ToBase64(InStream));
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
                if SubmitInvoice(SignedXML, SalesInvoiceHeader) then
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