codeunit 70000008 "MY eInv Submission"
{
    Permissions = tabledata "Sales Invoice Header" = RM, tabledata "Sales Cr.Memo Header" = RM, tabledata "Purch. Inv. Header" = RM, tabledata "Purch. Cr. Memo Hdr." = RM;

    var
        AccessToken: Text;
        TokenExpiry: DateTime;
        LastErrorMessage: Text;

    procedure GetLastErrorMessage(): Text
    begin
        exit(LastErrorMessage);
    end;

    procedure SubmitDocument(DocumentXML: Text; RecordVariant: Variant; DocumentType: Text; var ErrorMessage: Text): Boolean
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        RecRef: RecordRef;
    begin
        RecRef.GetTable(RecordVariant);

        case DocumentType of
            'Invoice':
                begin
                    RecRef.SetTable(SalesInvoiceHeader);
                    exit(SubmitInvoice(DocumentXML, SalesInvoiceHeader, ErrorMessage));
                end;
            'Credit Note', 'Refund Note':
                begin
                    RecRef.SetTable(SalesCrMemoHeader);
                    exit(SubmitCreditMemo(DocumentXML, SalesCrMemoHeader, ErrorMessage));
                end;
        end;

        ErrorMessage := 'Unknown document type';
        exit(false);
    end;

    procedure SubmitInvoice(DocumentXML: Text; SalesInvoiceHeader: Record "Sales Invoice Header"; var ErrorMessage: Text): Boolean
    var
        Setup: Record "MY eInv Setup";
        Authentication: Codeunit "MY eInv Authentication";
        SubmissionLog: Record "MY eInv Submission Log";
        SubmissionUID: Text;
        DocumentHash: Text;
        DocumentUUID: Text;
        ResponseText: Text;
        AccessToken: Text;
        Success: Boolean;
        StatusEnum: Enum "MY eInv Status";
    begin
        Setup.Get();

        AccessToken := Authentication.GetValidToken(Setup);
        if AccessToken = '' then begin
            ErrorMessage := 'Failed to obtain access token from MyInvois API.';
            StatusEnum := StatusEnum::Invalid;
            UpdateInvoiceHeader(SalesInvoiceHeader, '', '', '', StatusEnum, ErrorMessage);
            exit(false);
        end;

        Success := SubmitToMyInvois(DocumentXML, Setup, AccessToken, SalesInvoiceHeader."No.", SubmissionUID, DocumentHash, DocumentUUID, ResponseText);

        CreateInvoiceSubmissionLog(SubmissionLog, SalesInvoiceHeader, SubmissionUID, DocumentHash, Success, ResponseText);

        if Success then begin
            StatusEnum := StatusEnum::Submitted;
            UpdateInvoiceHeader(SalesInvoiceHeader, SubmissionUID, DocumentHash, DocumentUUID, StatusEnum, '');
            ErrorMessage := '';
        end else begin
            if ResponseText.Contains('Document rejected:') then
                StatusEnum := StatusEnum::Rejected
            else
                StatusEnum := StatusEnum::Invalid;

            ErrorMessage := ResponseText;
            UpdateInvoiceHeader(SalesInvoiceHeader, SubmissionUID, DocumentHash, DocumentUUID, StatusEnum, ErrorMessage);
        end;

        exit(Success);
    end;

    procedure SubmitCreditMemo(DocumentXML: Text; SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var ErrorMessage: Text): Boolean
    var
        Setup: Record "MY eInv Setup";
        Authentication: Codeunit "MY eInv Authentication";
        SubmissionLog: Record "MY eInv Submission Log";
        SubmissionUID: Text;
        DocumentHash: Text;
        DocumentUUID: Text;
        ResponseText: Text;
        AccessToken: Text;
        Success: Boolean;
        StatusEnum: Enum "MY eInv Status";

    begin
        Setup.Get();

        // Get valid access token
        AccessToken := Authentication.GetValidToken(Setup);
        if AccessToken = '' then begin
            ErrorMessage := 'Failed to obtain access token from MyInvois API.';
            StatusEnum := StatusEnum::Invalid;
            UpdateCreditMemoHeader(SalesCrMemoHeader, '', '', StatusEnum, ErrorMessage);
            exit(false);
        end;

        // Submit the document
        Success := SubmitToMyInvois(DocumentXML, Setup, AccessToken, SalesCrMemoHeader."No.", SubmissionUID, DocumentHash, DocumentUUID, ResponseText);

        // Create submission log
        CreateCreditMemoSubmissionLog(SubmissionLog, SalesCrMemoHeader, SubmissionUID, DocumentHash, Success, ResponseText);

        // Update credit memo header
        if Success then begin
            StatusEnum := StatusEnum::Submitted;
            UpdateCreditMemoHeader(SalesCrMemoHeader, SubmissionUID, DocumentHash, StatusEnum, '');
            ErrorMessage := '';
        end else begin
            if ResponseText.Contains('Document rejected:') then
                StatusEnum := StatusEnum::Rejected
            else
                StatusEnum := StatusEnum::Invalid;

            ErrorMessage := ResponseText;
            UpdateCreditMemoHeader(SalesCrMemoHeader, SubmissionUID, DocumentHash, StatusEnum, ErrorMessage);
        end;

        exit(Success);
    end;


    // SHARED METHOD - Used by both Invoice and Credit Memo
    local procedure SubmitToMyInvois(DocumentXML: Text; Setup: Record "MY eInv Setup"; AccessToken: Text; DocumentNo: Code[20]; var SubmissionUID: Text; var DocumentHash: Text; var DocumentUUID: Text; var ResponseText: Text): Boolean
    var
        Client: HttpClient;
        RequestMessage: HttpRequestMessage;
        ResponseMessage: HttpResponseMessage;
        RequestHeaders: HttpHeaders;
        Content: HttpContent;
        ContentHeaders: HttpHeaders;
        JsonResponse: JsonObject;
        JsonToken: JsonToken;
        AcceptedArray: JsonArray;
        AcceptedDoc: JsonObject;
        RejectedArray: JsonArray;
        JsonBody: JsonObject;
        JsonDocuments: JsonArray;
        JsonDocument: JsonObject;
        RequestBody: Text;
        ApiUrl: Text;
        HttpStatusCode: Integer;
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
            ResponseText := 'Network Error: Failed to connect to MyInvois API. Please check your internet connection and try again.';
            exit(false);
        end;

        // Get HTTP status code
        HttpStatusCode := ResponseMessage.HttpStatusCode;

        // Read response
        ResponseMessage.Content.ReadAs(ResponseText);

        // Handle different HTTP status codes
        if not ResponseMessage.IsSuccessStatusCode then begin
            ResponseText := GetHttpErrorMessage(HttpStatusCode, ResponseText);
            exit(false);
        end;

        // Parse response
        if not JsonResponse.ReadFrom(ResponseText) then begin
            ResponseText := 'Invalid JSON response from MyInvois API.';
            exit(false);
        end;

        // Check submissionUid - it can be null if validation failed
        if JsonResponse.Get('submissionUid', JsonToken) and not JsonToken.AsValue().IsNull then
            SubmissionUID := JsonToken.AsValue().AsText()
        else
            SubmissionUID := ''; // Clear it if null

        // Get acceptedDocuments array
        if JsonResponse.Get('acceptedDocuments', JsonToken) then begin
            AcceptedArray := JsonToken.AsArray();

            if AcceptedArray.Count > 0 then begin
                // Document was accepted - extract UUID and hash
                AcceptedArray.Get(0, JsonToken);
                AcceptedDoc := JsonToken.AsObject();

                // Extract UUID
                if AcceptedDoc.Get('uuid', JsonToken) and not JsonToken.AsValue().IsNull then
                    DocumentUUID := JsonToken.AsValue().AsText()
                else begin
                    ResponseText := 'Document accepted but missing UUID.';
                    exit(false);
                end;

                // Extract document hash (if provided)
                if AcceptedDoc.Get('documentHash', JsonToken) and not JsonToken.AsValue().IsNull then
                    DocumentHash := JsonToken.AsValue().AsText()
                else
                    DocumentHash := ComputeDocumentHash(DocumentXML);

                exit(true);
            end;
        end;

        // If we get here, document was rejected - extract detailed error messages
        ResponseText := ExtractRejectionErrors(JsonResponse);
        exit(false);
    end;

    local procedure ExtractRejectionErrors(JsonResponse: JsonObject): Text
    var
        JsonToken: JsonToken;
        RejectedArray: JsonArray;
        RejectedDoc: JsonObject;
        ErrorObj: JsonObject;
        DetailsArray: JsonArray;
        DetailObj: JsonObject;
        ErrorMessage: Text;
        ErrorCode: Text;
        Target: Text;
        PropertyPath: Text;
        DetailCode: Text;
        DetailMessage: Text;
        DetailTarget: Text;
        DetailPropertyPath: Text;
        i: Integer;
    begin
        ErrorMessage := 'Document submission failed:';

        // Get rejectedDocuments array
        if not JsonResponse.Get('rejectedDocuments', JsonToken) then
            exit(ErrorMessage + ' No rejection details available.');

        RejectedArray := JsonToken.AsArray();
        if RejectedArray.Count = 0 then
            exit(ErrorMessage + ' No rejection details available.');

        // Process first rejected document (you can loop through all if needed)
        RejectedArray.Get(0, JsonToken);
        RejectedDoc := JsonToken.AsObject();

        // Get error object
        if RejectedDoc.Get('error', JsonToken) then begin
            ErrorObj := JsonToken.AsObject();

            // Get main error info
            if ErrorObj.Get('code', JsonToken) and not JsonToken.AsValue().IsNull then
                ErrorCode := JsonToken.AsValue().AsText();

            if ErrorObj.Get('message', JsonToken) and not JsonToken.AsValue().IsNull then
                ErrorMessage += ' ' + JsonToken.AsValue().AsText();

            if ErrorObj.Get('target', JsonToken) and not JsonToken.AsValue().IsNull then begin
                Target := JsonToken.AsValue().AsText();
                ErrorMessage += ' (Document: ' + Target + ')';
            end;

            // Get detailed errors
            if ErrorObj.Get('details', JsonToken) then begin
                DetailsArray := JsonToken.AsArray();

                if DetailsArray.Count > 0 then
                    ErrorMessage += '\Details:';

                for i := 0 to DetailsArray.Count - 1 do begin
                    DetailsArray.Get(i, JsonToken);
                    DetailObj := JsonToken.AsObject();

                    // Extract detail fields
                    DetailCode := '';
                    DetailMessage := '';
                    DetailTarget := '';
                    DetailPropertyPath := '';

                    if DetailObj.Get('code', JsonToken) and not JsonToken.AsValue().IsNull then
                        DetailCode := JsonToken.AsValue().AsText();

                    if DetailObj.Get('message', JsonToken) and not JsonToken.AsValue().IsNull then
                        DetailMessage := JsonToken.AsValue().AsText();

                    if DetailObj.Get('target', JsonToken) and not JsonToken.AsValue().IsNull then
                        DetailTarget := JsonToken.AsValue().AsText();

                    if DetailObj.Get('propertyPath', JsonToken) and not JsonToken.AsValue().IsNull then
                        DetailPropertyPath := JsonToken.AsValue().AsText();

                    // Build detailed error line
                    ErrorMessage += '\- [' + DetailCode + '] ' + DetailMessage;

                    if DetailPropertyPath <> '' then
                        ErrorMessage += ' (Path: ' + DetailPropertyPath + ')';

                    if DetailTarget <> '' then
                        ErrorMessage += ' (Field: ' + DetailTarget + ')';
                end;
            end;
        end;

        exit(ErrorMessage);
    end;

    //enhanced error messages

    local procedure GetHttpErrorMessage(HttpStatusCode: Integer; RawResponse: Text): Text
    var
        JsonResponse: JsonObject;
        JsonToken: JsonToken;
        ErrorMessage: Text;
    begin
        case HttpStatusCode of
            400:
                begin
                    ErrorMessage := 'Bad Request (400): The request was invalid. ';
                    // Try to extract error details from response
                    if JsonResponse.ReadFrom(RawResponse) then begin
                        if JsonResponse.Get('error', JsonToken) then begin
                            if JsonToken.IsObject() then begin
                                if JsonToken.AsObject().Get('message', JsonToken) then
                                    ErrorMessage += JsonToken.AsValue().AsText();
                            end else
                                ErrorMessage += JsonToken.AsValue().AsText();
                        end;
                    end else
                        ErrorMessage += RawResponse;
                end;
            401:
                ErrorMessage := 'Authentication Error (401): Access token is invalid or expired. Please check your credentials and try again.';
            403:
                ErrorMessage := 'Authorization Error (403): You do not have permission to submit documents. Please verify your MyInvois account permissions.';
            404:
                ErrorMessage := 'Not Found (404): The MyInvois API endpoint was not found. Please check your API Base URL configuration.';
            408:
                ErrorMessage := 'Request Timeout (408): The request took too long to complete. Please try again.';
            429:
                ErrorMessage := 'Rate Limit Exceeded (429): Too many requests sent to MyInvois API. Please wait a few minutes and try again.';
            500:
                ErrorMessage := 'Server Error (500): MyInvois API encountered an internal server error. Please try again later or contact support.';
            502:
                ErrorMessage := 'Bad Gateway (502): MyInvois API is temporarily unavailable. Please try again in a few minutes.';
            503:
                ErrorMessage := 'Service Unavailable (503): MyInvois API is temporarily down for maintenance. Please try again later.';
            504:
                ErrorMessage := 'Gateway Timeout (504): MyInvois API did not respond in time. Please try again.';
            else
                ErrorMessage := StrSubstNo('HTTP Error (%1): %2', HttpStatusCode, RawResponse);
        end;

        exit(ErrorMessage);
    end;

    local procedure GetDateTimeDebugInfo(): Text
    var
        TypeHelper: Codeunit "Type Helper";
        LocalDT: DateTime;
        UTCDT: DateTime;
        LocalDate: Date;
        LocalTime: Time;
        UTCDate: Date;
        UTCTime: Time;
        DebugInfo: Text;
    begin
        LocalDT := CurrentDateTime;
        UTCDT := TypeHelper.GetCurrUTCDateTime();

        LocalDate := DT2Date(LocalDT);
        LocalTime := DT2Time(LocalDT);
        UTCDate := DT2Date(UTCDT);
        UTCTime := DT2Time(UTCDT);

        DebugInfo := '\  → Server Local Time: ' + Format(LocalDate) + ' ' + Format(LocalTime);
        DebugInfo += '\  → Current UTC Time: ' + Format(UTCDate) + ' ' + Format(UTCTime);
        DebugInfo += '\  → Time Difference: ' + Format((LocalDT - UTCDT) / 3600000, 0, '<Integer>') + ' hours';
        DebugInfo += '\  → Check if your IssueDate/IssueTime in XML is using UTC timezone';

        exit(DebugInfo);
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

    procedure CancelInMyInvois(SalesInvHeader: Record "Sales Invoice Header")
    var
        Setup: Record "MY eInv Setup";
        Submission: Codeunit "MY eInv Submission";
        CancellationReason: Text;
        Selection: Integer;
    begin
        if SalesInvHeader."MY eInv Submission UID" = '' then
            Error('This invoice has not been submitted to MyInvois yet.');

        if SalesInvHeader."MY eInv Cancelled" then
            Error('This invoice is already cancelled in MyInvois.');

        // Prompt for cancellation reason
        CancellationReason := '';

        // Use StrMenu for predefined reasons or plain assignment for free text
        Selection := StrMenu(
        'Wrong Invoice Details,Duplicate Invoice,Customer Request,Pricing Error,Data Entry Error,Other',
        1,
        'Select cancellation reason:');

        case Selection of
            0:
                exit; // User cancelled
            1:
                CancellationReason := 'Wrong Invoice Details';
            2:
                CancellationReason := 'Duplicate Invoice';
            3:
                CancellationReason := 'Customer Request';
            4:
                CancellationReason := 'Pricing Error';
            5:
                CancellationReason := 'Data Entry Error';
            6:
                CancellationReason := 'Other';
        end;

        if CancellationReason = '' then
            Error('Cancellation reason is required.');

        Setup.Get();

        if Submission.CancelDocument(SalesInvHeader, CancellationReason, Setup) then begin
            SalesInvHeader."MY eInv Status" := "MY eInv Status"::Cancelled;
            SalesInvHeader."MY eInv Cancelled" := true;
            SalesInvHeader.Modify();
            Message('Invoice cancelled successfully in MyInvois.');
        end else
            Error('Failed to cancel invoice in MyInvois.');
    end;

    procedure CancelDocument(var SalesInvoiceHeader: Record "Sales Invoice Header"; Reason: Text; Setup: Record "MY eInv Setup"): Boolean
    var
        Authentication: Codeunit "MY eInv Authentication";
        SubmissionLog: Record "MY eInv Submission Log";
        Client: HttpClient;
        RequestMessage: HttpRequestMessage;
        ResponseMessage: HttpResponseMessage;
        Headers: HttpHeaders;
        Content: HttpContent;
        ContentHeaders: HttpHeaders;
        RequestJson: JsonObject;
        StatusJson: JsonObject;
        RequestBody: Text;
        ResponseBody: Text;
        ApiUrl: Text;
        AccessToken: Text;
        Success: Boolean;
    begin
        // Get valid token
        AccessToken := Authentication.GetValidToken(Setup);
        if AccessToken = '' then begin
            CreateCancellationLog(SubmissionLog, SalesInvoiceHeader, SalesInvoiceHeader."MY eInv IRBM Unique ID",
                Reason, false, 'Failed to get access token');
            exit(false);
        end;

        // Build API URL
        ApiUrl := Setup."API Base URL";
        if not ApiUrl.EndsWith('/') then
            ApiUrl += '/';
        ApiUrl += 'api/v1.0/documents/state/' + SalesInvoiceHeader."MY eInv IRBM Unique ID" + '/state';

        // Build request
        StatusJson.Add('status', 'cancelled');
        StatusJson.Add('reason', Reason);
        /* RequestJson.Add('status', StatusJson);
        RequestJson.WriteTo(RequestBody); */
        StatusJson.WriteTo(RequestBody);

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
        Success := Client.Send(RequestMessage, ResponseMessage);

        if Success then begin
            Success := ResponseMessage.IsSuccessStatusCode;
            ResponseMessage.Content.ReadAs(ResponseBody);
        end else
            ResponseBody := 'Failed to send HTTP request';

        // Log the cancellation attempt
        CreateCancellationLog(SubmissionLog, SalesInvoiceHeader, SalesInvoiceHeader."MY eInv Submission UID",
            Reason, Success, ResponseBody);

        // Update invoice header
        if Success then
            UpdateInvoiceHeaderForCancellation(SalesInvoiceHeader, '')
        else
            UpdateInvoiceHeaderForCancellation(SalesInvoiceHeader, ResponseBody);

        exit(Success);
    end;

    local procedure CreateCancellationLog(var SubmissionLog: Record "MY eInv Submission Log"; SalesInvoiceHeader: Record "Sales Invoice Header"; SubmissionUID: Text; Reason: Text; Success: Boolean; ResponseText: Text)
    begin
        SubmissionLog.Init();
        SubmissionLog."Entry No." := GetNextEntryNo();
        SubmissionLog."Document Type" := '01';
        SubmissionLog."Document No." := SalesInvoiceHeader."No.";
        SubmissionLog."Customer No." := SalesInvoiceHeader."Sell-to Customer No.";
        SubmissionLog."Customer Name" := SalesInvoiceHeader."Sell-to Customer Name";
        SubmissionLog."Submission Date Time" := CurrentDateTime;
        SubmissionLog."Submission UID" := CopyStr(SubmissionUID, 1, MaxStrLen(SubmissionLog."Submission UID"));
        SubmissionLog."Cancellation Reason" := CopyStr(Reason, 1, MaxStrLen(SubmissionLog."Cancellation Reason"));
        SubmissionLog.Status := GetCancellationStatus(Success);  // Will set to Cancelled or Cancellation Failed
        SubmissionLog."Response Text" := CopyStr(ResponseText, 1, MaxStrLen(SubmissionLog."Response Text"));
        SubmissionLog.Insert(true);
    end;

    local procedure GetCancellationStatus(Success: Boolean): Enum "MY eInv Status"
    var
        EInvStatus: Enum "MY eInv Status";
    begin
        if Success then
            exit(EInvStatus::Cancelled)
        else
            exit(EInvStatus::"Cancellation Failed");
    end;

    local procedure UpdateInvoiceHeaderForCancellation(var SalesInvoiceHeader: Record "Sales Invoice Header"; ErrorMessage: Text)
    var
        EInvStatus: Enum "MY eInv Status";
    begin
        if ErrorMessage = '' then
            SalesInvoiceHeader."MY eInv Status" := EInvStatus::Cancelled
        else
            SalesInvoiceHeader."MY eInv Status" := EInvStatus::"Cancellation Failed";

        SalesInvoiceHeader."MY eInv Cancellation Date" := Today;
        SalesInvoiceHeader."MY eInv Cancellation Time" := Time;

        if ErrorMessage <> '' then
            SalesInvoiceHeader."MY eInv Error Message" := CopyStr(ErrorMessage, 1, 250)
        else
            SalesInvoiceHeader."MY eInv Error Message" := '';

        SalesInvoiceHeader.Modify(true);
    end;

    local procedure UpdateInvoiceWithCancellationData(var SalesInvoiceHeader: Record "Sales Invoice Header"; CancellationDateTime: DateTime; CancellationReason: Text)
    var
        EInvStatus: Enum "MY eInv Status";
    begin
        SalesInvoiceHeader."MY eInv Status" := EInvStatus::Cancelled;
        SalesInvoiceHeader."MY eInv Cancelled" := true;

        if CancellationDateTime <> 0DT then begin
            SalesInvoiceHeader."MY eInv Cancellation Date" := DT2Date(CancellationDateTime);
            SalesInvoiceHeader."MY eInv Cancellation Time" := DT2Time(CancellationDateTime);
        end;

        if CancellationReason <> '' then
            SalesInvoiceHeader."MY eInv Error Message" := CopyStr(CancellationReason, 1, MaxStrLen(SalesInvoiceHeader."MY eInv Error Message"));

        SalesInvoiceHeader."MY eInv Error Message" := '';
        SalesInvoiceHeader.Modify(true);
    end;



    // INVOICE-SPECIFIC METHODS
    local procedure CreateInvoiceSubmissionLog(var SubmissionLog: Record "MY eInv Submission Log"; SalesInvoiceHeader: Record "Sales Invoice Header"; SubmissionUID: Text; DocumentHash: Text; Success: Boolean; ResponseText: Text)
    begin
        SubmissionLog.Init();
        SubmissionLog."Entry No." := GetNextEntryNo();
        SubmissionLog."Document Type" := '01';
        SubmissionLog."Document No." := SalesInvoiceHeader."No.";
        SubmissionLog."Customer No." := SalesInvoiceHeader."Sell-to Customer No.";
        SubmissionLog."Customer Name" := SalesInvoiceHeader."Sell-to Customer Name";
        SubmissionLog."Submission Date Time" := CurrentDateTime;
        SubmissionLog."Submission UID" := CopyStr(SubmissionUID, 1, MaxStrLen(SubmissionLog."Submission UID"));
        SubmissionLog."Document Hash" := CopyStr(DocumentHash, 1, MaxStrLen(SubmissionLog."Document Hash"));
        SubmissionLog.Status := GetSubmissionStatus(Success);
        SubmissionLog."Response Text" := CopyStr(ResponseText, 1, MaxStrLen(SubmissionLog."Response Text"));
        SubmissionLog.Insert(true);
    end;

    local procedure UpdateInvoiceHeader(var SalesInvoiceHeader: Record "Sales Invoice Header"; SubmissionUID: Text; DocumentHash: Text; DocumentUUID: Text; Status: Enum "MY eInv Status"; ErrorMessage: Text)
    var
        Setup: Record "MY eInv Setup";
        PortalURL: Text;
    begin
        SalesInvoiceHeader."MY eInv Submission UID" := CopyStr(SubmissionUID, 1, 50);
        SalesInvoiceHeader."MY eInv Document Hash" := CopyStr(DocumentHash, 1, 100);
        SalesInvoiceHeader."MY eInv Document UUID" := CopyStr(DocumentUUID, 1, 50);
        SalesInvoiceHeader."MY eInv Status" := Status;
        SalesInvoiceHeader."MY eInv Error Message" := CopyStr(ErrorMessage, 1, 250);
        SalesInvoiceHeader."MY eInv Submission Date" := Today;
        SalesInvoiceHeader.Modify(false);
    end;

    local procedure UpdateInvoiceStatus(var SalesInvoiceHeader: Record "Sales Invoice Header"; StatusText: Text; ErrorMessage: Text)
    var
        EInvStatus: Enum "MY eInv Status";
    begin
        EInvStatus := ConvertTextToStatus(StatusText);
        SalesInvoiceHeader."MY eInv Status" := EInvStatus;
        SalesInvoiceHeader."MY eInv Error Message" := CopyStr(ErrorMessage, 1, MaxStrLen(SalesInvoiceHeader."MY eInv Error Message"));
        SalesInvoiceHeader.Modify(true);
    end;

    local procedure UpdateInvoiceWithValidationData(var SalesInvoiceHeader: Record "Sales Invoice Header"; IRBMUniqueId: Text; LongId: Text; ValidationDateTime: DateTime; ValidationURL: Text)
    begin
        if SalesInvoiceHeader.Get(SalesInvoiceHeader."No.") then begin
            SalesInvoiceHeader."MY eInv IRBM Unique ID" := CopyStr(IRBMUniqueId, 1, 50);
            SalesInvoiceHeader."MY eInv Long ID" := CopyStr(LongId, 1, 100);
            SalesInvoiceHeader."MY eInv Validation Date" := ValidationDateTime;
            SalesInvoiceHeader."MY eInv Validation URL" := CopyStr(ValidationURL, 1, 250);
            SalesInvoiceHeader.Modify(true);
        end;
    end;

    local procedure ConvertTextToStatus(StatusText: Text): Enum "MY eInv Status"
    begin
        case StatusText of
            'Valid':
                exit("MY eInv Status"::Valid);
            'Invalid':
                exit("MY eInv Status"::Invalid);
            'Submitted', 'Processing':
                exit("MY eInv Status"::Submitted);
            'Cancelled':
                exit("MY eInv Status"::Cancelled);
            'Rejected':
                exit("MY eInv Status"::Rejected);
            else
                exit("MY eInv Status"::" "); // or whatever your default/blank value is
        end;
    end;

    procedure GetDocumentDetails(var SalesInvoiceHeader: Record "Sales Invoice Header"): Boolean
    var
        Setup: Record "MY eInv Setup";
        Authentication: Codeunit "MY eInv Authentication";
        AccessToken: Text;
        ResponseText: Text;
    begin
        if SalesInvoiceHeader."MY eInv Document UUID" = '' then
            Error('Document has not been submitted to MyInvois yet.');

        Setup.Get();
        AccessToken := Authentication.GetValidToken(Setup);

        if AccessToken = '' then
            Error('Failed to obtain access token.');

        exit(GetDocumentDetailsAPI(SalesInvoiceHeader, Setup, AccessToken, ResponseText));
    end;

    local procedure GetDocumentDetailsAPI(var SalesInvoiceHeader: Record "Sales Invoice Header"; Setup: Record "MY eInv Setup"; AccessToken: Text; var ResponseText: Text): Boolean
    var
        Client: HttpClient;
        RequestMessage: HttpRequestMessage;
        ResponseMessage: HttpResponseMessage;
        RequestHeaders: HttpHeaders;
        JsonResponse: JsonObject;
        JsonToken: JsonToken;
        ApiUrl: Text;
        DocumentStatus: Text;
        LongId: Text;
        IRBMUniqueId: Text;
        ValidationDateTime: DateTime;
        ValidationURL: Text;
        CancellationDateTime: DateTime;
        CancellationReason: Text;
    begin
        ApiUrl := Setup."API Base URL" + '/api/v1.0/documents/' + SalesInvoiceHeader."MY eInv Document UUID" + '/details';

        RequestMessage.Method := 'GET';
        RequestMessage.SetRequestUri(ApiUrl);

        RequestMessage.GetHeaders(RequestHeaders);
        RequestHeaders.Add('Authorization', 'Bearer ' + AccessToken);
        RequestHeaders.Add('Accept', 'application/json');
        RequestHeaders.Add('Accept-Language', 'en');

        if not Client.Send(RequestMessage, ResponseMessage) then begin
            ResponseText := 'Failed to connect to MyInvois API.';
            exit(false);
        end;

        ResponseMessage.Content.ReadAs(ResponseText);

        if not ResponseMessage.IsSuccessStatusCode then begin
            ResponseText := GetHttpErrorMessage(ResponseMessage.HttpStatusCode, ResponseText);
            exit(false);
        end;

        if not JsonResponse.ReadFrom(ResponseText) then begin
            ResponseText := 'Invalid JSON response.';
            exit(false);
        end;

        // Extract status
        if JsonResponse.Get('status', JsonToken) and not JsonToken.AsValue().IsNull then
            DocumentStatus := JsonToken.AsValue().AsText()
        else
            DocumentStatus := '';

        // Extract long ID
        if JsonResponse.Get('longId', JsonToken) and not JsonToken.AsValue().IsNull then
            LongId := JsonToken.AsValue().AsText()
        else
            LongId := '';

        // Extract validation date/time
        if JsonResponse.Get('dateTimeValidated', JsonToken) and not JsonToken.AsValue().IsNull then
            ValidationDateTime := EvaluateDateTime(JsonToken.AsValue().AsText());

        // Check document status
        case DocumentStatus of
            'Valid':
                begin
                    // Document is valid - extract UUID as IRBM Unique ID
                    if JsonResponse.Get('uuid', JsonToken) and not JsonToken.AsValue().IsNull then
                        IRBMUniqueId := JsonToken.AsValue().AsText();

                    // Build validation URL
                    ValidationURL := BuildValidationURL(Setup, SalesInvoiceHeader."MY eInv Document UUID", LongId);
                    ResponseText := StrSubstNo('Document validated successfully.\IRBM Unique ID: %1\Validation Date: %2', IRBMUniqueId, ValidationDateTime);

                    // Update invoice header with validation data
                    UpdateInvoiceWithValidationData(SalesInvoiceHeader, IRBMUniqueId, LongId, ValidationDateTime, ValidationURL);
                    UpdateInvoiceStatus(SalesInvoiceHeader, DocumentStatus, '');

                    exit(true);
                end;

            'Invalid':
                begin
                    // Document has validation errors
                    ResponseText := ExtractValidationErrors(JsonResponse, DocumentStatus, ValidationDateTime);
                    UpdateInvoiceStatus(SalesInvoiceHeader, DocumentStatus, ResponseText);

                    exit(false);
                end;

            'Cancelled':
                begin
                    // Document has been cancelled
                    // Extract cancellation date/time - use "cancelDateTime" field
                    if JsonResponse.Get('cancelDateTime', JsonToken) and not JsonToken.AsValue().IsNull then
                        CancellationDateTime := EvaluateDateTime(JsonToken.AsValue().AsText());

                    // Extract cancellation reason - use "documentStatusReason" field
                    if JsonResponse.Get('documentStatusReason', JsonToken) and not JsonToken.AsValue().IsNull then
                        CancellationReason := JsonToken.AsValue().AsText()
                    else
                        CancellationReason := 'No reason provided';

                    ResponseText := StrSubstNo('Document has been cancelled.\Cancellation Date: %1\Reason: %2',
                        CancellationDateTime, CancellationReason);

                    // Update invoice header with cancellation data
                    UpdateInvoiceWithCancellationData(SalesInvoiceHeader, CancellationDateTime, CancellationReason);

                    exit(true); // Cancellation is successful, not an error
                end;

            'Submitted', 'Processing':
                begin
                    // Document is still being processed
                    ResponseText := StrSubstNo('Document status: %1\The document is still being validated by MyInvois. Please check again later.', DocumentStatus);
                    UpdateInvoiceStatus(SalesInvoiceHeader, DocumentStatus, '');
                    exit(false);
                end;

            'Rejected':
                begin
                    // Document has been rejected
                    ResponseText := StrSubstNo('Document has been rejected.\Validation Date: %1', ValidationDateTime);
                    UpdateInvoiceStatus(SalesInvoiceHeader, DocumentStatus, ResponseText);
                    exit(false);
                end;

            else begin
                // Unknown or other status
                ResponseText := StrSubstNo('Document status: %1\Validation Date: %2', DocumentStatus, ValidationDateTime);
                UpdateInvoiceStatus(SalesInvoiceHeader, DocumentStatus, ResponseText);
                exit(false);
            end;
        end;
    end;

    local procedure ExtractValidationErrors(JsonResponse: JsonObject; DocumentStatus: Text; ValidationDateTime: DateTime): Text
    var
        JsonToken: JsonToken;
        ValidationResults: JsonObject;
        ValidationSteps: JsonArray;
        StepObj: JsonObject;
        ErrorObj: JsonObject;
        InnerErrorArray: JsonArray;
        InnerErrorObj: JsonObject;
        ErrorMessage: Text;
        StepStatus: Text;
        ErrorCode: Text;
        ErrorText: Text;
        i: Integer;
        j: Integer;
        ErrorCount: Integer;
    begin
        ErrorMessage := 'Validation failed: ';
        ErrorCount := 0;

        // Get validationResults
        if not JsonResponse.Get('validationResults', JsonToken) then
            exit(ErrorMessage + 'No validation details available.');

        ValidationResults := JsonToken.AsObject();

        // Get validationSteps array
        if not ValidationResults.Get('validationSteps', JsonToken) then
            exit(ErrorMessage + 'No validation steps found.');

        ValidationSteps := JsonToken.AsArray();

        // Loop through validation steps
        for i := 0 to ValidationSteps.Count - 1 do begin
            ValidationSteps.Get(i, JsonToken);
            StepObj := JsonToken.AsObject();

            // Get step status
            if StepObj.Get('status', JsonToken) and not JsonToken.AsValue().IsNull then
                StepStatus := JsonToken.AsValue().AsText();

            // Only process invalid steps
            if StepStatus = 'Invalid' then begin
                if StepObj.Get('error', JsonToken) then begin
                    ErrorObj := JsonToken.AsObject();

                    // Get innerError array with detailed errors
                    if ErrorObj.Get('innerError', JsonToken) then begin
                        InnerErrorArray := JsonToken.AsArray();

                        for j := 0 to InnerErrorArray.Count - 1 do begin
                            InnerErrorArray.Get(j, JsonToken);
                            InnerErrorObj := JsonToken.AsObject();

                            // Extract error code and message
                            if InnerErrorObj.Get('errorCode', JsonToken) and not JsonToken.AsValue().IsNull then
                                ErrorCode := JsonToken.AsValue().AsText();

                            if InnerErrorObj.Get('error', JsonToken) and not JsonToken.AsValue().IsNull then
                                ErrorText := JsonToken.AsValue().AsText();

                            // Add error to message (with separator if not first)
                            if ErrorCount > 0 then
                                ErrorMessage += '; ';

                            ErrorMessage += '[' + ErrorCode + '] ' + ErrorText;
                            ErrorCount += 1;

                            // Stop if message is getting too long (leave room for potential more errors indicator)
                            if StrLen(ErrorMessage) > 200 then begin
                                if j < InnerErrorArray.Count - 1 then
                                    ErrorMessage += '... +' + Format(InnerErrorArray.Count - j - 1) + ' more';
                                exit(ErrorMessage);
                            end;
                        end;
                    end;
                end;
            end;
        end;

        if ErrorCount = 0 then
            ErrorMessage += 'Unknown validation error.';

        exit(ErrorMessage);
    end;

    local procedure EvaluateDateTime(DateTimeText: Text): DateTime
    var
        ResultDateTime: DateTime;
    begin
        if Evaluate(ResultDateTime, DateTimeText, 9) then // Format 9 is ISO 8601
            exit(ResultDateTime);

        exit(0DT); // Return blank datetime if parsing fails
    end;

    local procedure BuildValidationURL(Setup: Record "MY eInv Setup"; DocumentUUID: Text; LongId: Text): Text
    var
        BaseURL: Text;
    begin
        // MyInvois validation URL pattern (adjust based on actual portal structure)
        BaseURL := Setup."Portal Base URL";

        // Format: {baseURL}/{uuid}/share/{longId}
        exit(StrSubstNo('%1/%2/share/%3', BaseURL, DocumentUUID, LongId));
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

    local procedure UpdateCreditMemoHeader(var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; SubmissionUID: Text; DocumentHash: Text; Status: Enum "MY eInv Status"; ErrorMessage: Text)
    begin
        // Assuming you have these fields in your Sales Cr.Memo Header extension
        SalesCrMemoHeader."MY eInv Submission UID" := CopyStr(SubmissionUID, 1, 50);
        SalesCrMemoHeader."MY eInv Document Hash" := CopyStr(DocumentHash, 1, 100);
        SalesCrMemoHeader."MY eInv Submitted" := true;
        SalesCrMemoHeader."MY eInv Status" := Status;
        SalesCrMemoHeader."MY eInv Error Message" := CopyStr(ErrorMessage, 1, 250);
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
    local procedure GetJsonValueAsText(JObject: JsonObject; PropertyName: Text; var Value: Text): Boolean
    var
        JToken: JsonToken;
    begin
        if not JObject.Get(PropertyName, JToken) then
            exit(false);

        if not JToken.IsValue() then
            exit(false);

        Value := Format(JToken.AsValue());
        exit(true);
    end;

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
        ErrorMsg: Text;
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
                if SubmitInvoice(SignedXML, SalesInvoiceHeader, ErrorMsg) then
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