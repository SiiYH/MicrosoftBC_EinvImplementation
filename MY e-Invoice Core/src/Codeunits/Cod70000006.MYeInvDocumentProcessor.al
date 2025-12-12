// ═════════════════════════════════════════════════════════════════
// USAGE EXAMPLE: Complete Flow
// ═════════════════════════════════════════════════════════════════
codeunit 70000006 "MY eInv Document Processor"
{
    procedure ProcessSalesInvoice(SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        InvoiceDoc: Codeunit "MY eInv Sales Invoice Doc";
        Document: Interface "MY eInv Document";
    begin
        InvoiceDoc.SetDocument(SalesInvoiceHeader);
        Document := InvoiceDoc;
        ProcessDocument(Document);
    end;

    procedure ProcessSalesCreditMemo(SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        CrMemoDoc: Codeunit "MY eInv Sales CrMemo Doc";
        Document: Interface "MY eInv Document";
    begin
        CrMemoDoc.SetDocument(SalesCrMemoHeader);
        Document := CrMemoDoc;
        ProcessDocument(Document);
    end;

    local procedure ProcessDocument(Document: Interface "MY eInv Document")
    var
        Setup: Record "MY eInv Setup";
        eInvAuth: Codeunit "MY eInv Authentication";
        XMLGenerator: Codeunit "MY eInv XML Generator";
        DigitalSignature: Codeunit "MY eInv Digital Signature";
        Submission: Codeunit "MY eInv Submission";
        DocumentXML: Text;
        SignedXML: Text;
        SubmissionResult: Boolean;
        RecordVariant: Variant;
        ErrorMessage: Text;
        SigningErrorMessage: Text;
        MaxRetries: Integer;
        RetryCount: Integer;
        WaitTime: Integer;
        AzureFunctionKey: Text;
    begin
        Setup.Get();
        Document.GetDocumentRecord(RecordVariant);

        // Step 1: Generate XML
        DocumentXML := XMLGenerator.GenerateDocumentXML(RecordVariant, Document.GetDocumentType());
        if DocumentXML = '' then
            Error('Failed to generate document XML');

        // Step 2: Sign if needed (version 1.1 requires signature)
        if Setup."Document Version" = Setup."Document Version"::"1.1" then begin
            // Validate signing configuration
            if Setup."Azure Function URL" = '' then
                Error('Signing Service URL is not configured. Please configure in MY eInv Setup.');

            AzureFunctionKey := eInvAuth.GetAzureFunctionKey(Setup);
            if AzureFunctionKey = '' then
                Error('Azure Function Key is not configured.Please configure in MY eInv Setup.');

            // Attempt signing with retry logic
            MaxRetries := 2;
            RetryCount := 0;

            repeat
                if DigitalSignature.SignDocumentWithError(DocumentXML, Setup, SignedXML, SigningErrorMessage) then begin
                    // Signing successful
                    LogSigningSuccess(RecordVariant, Document.GetDocumentType());
                    break;
                end else begin
                    // Signing failed
                    RetryCount += 1;

                    if RetryCount < MaxRetries then begin
                        // Retry after short delay
                        Sleep(2000); // 2 seconds
                        LogSigningRetry(RecordVariant, Document.GetDocumentType(), RetryCount, SigningErrorMessage);
                    end else begin
                        // Max retries reached, fail with error
                        LogSigningError(RecordVariant, Document.GetDocumentType(), SigningErrorMessage);
                        Error('Document signing failed after %1 attempts:\%2\' +
                              'Please check your signing service configuration and certificate.',
                              MaxRetries, SigningErrorMessage);
                    end;
                end;
            until RetryCount >= MaxRetries;
        end else begin
            // No signature required for version 1.0
            SignedXML := DocumentXML;
        end;

        // Step 3: Submit to LHDN
        SubmissionResult := Submission.SubmitDocument(SignedXML, RecordVariant, Document.GetDocumentType(), ErrorMessage);

        if not SubmissionResult then begin
            LogSubmissionError(RecordVariant, Document.GetDocumentType(), ErrorMessage);
            Error('Document submission failed:\%1', ErrorMessage);
        end;

        LogSubmissionSuccess(RecordVariant, Document.GetDocumentType());
    end;

    local procedure LogSigningSuccess(RecordVariant: Variant; DocumentType: Text)
    var
        ActivityLog: Record "Activity Log";
        RecRef: RecordRef;
    begin
        RecRef.GetTable(RecordVariant);
        ActivityLog.LogActivity(
            RecRef,
            ActivityLog.Status::Success,
            'SIGN',
            'Document signed successfully',
            StrSubstNo('Document type: %1', DocumentType));
    end;

    local procedure LogSigningRetry(RecordVariant: Variant; DocumentType: Text; RetryCount: Integer; ErrorMessage: Text)
    var
        ActivityLog: Record "Activity Log";
        RecRef: RecordRef;
    begin
        RecRef.GetTable(RecordVariant);
        ActivityLog.LogActivity(
            RecRef,
            ActivityLog.Status::Failed,
            'SIGN',
            StrSubstNo('Signing attempt %1 failed, retrying...', RetryCount),
            CopyStr(ErrorMessage, 1, 250));
    end;

    local procedure LogSigningError(RecordVariant: Variant; DocumentType: Text; ErrorMessage: Text)
    var
        ActivityLog: Record "Activity Log";
        RecRef: RecordRef;
    begin
        RecRef.GetTable(RecordVariant);
        ActivityLog.LogActivity(
            RecRef,
            ActivityLog.Status::Failed,
            'SIGN',
            'Document signing failed',
            CopyStr(ErrorMessage, 1, 250));
    end;

    local procedure LogSubmissionSuccess(RecordVariant: Variant; DocumentType: Text)
    var
        ActivityLog: Record "Activity Log";
        RecRef: RecordRef;
    begin
        RecRef.GetTable(RecordVariant);
        ActivityLog.LogActivity(
            RecRef,
            ActivityLog.Status::Success,
            'SUBMIT',
            'Document submitted successfully',
            StrSubstNo('Document type: %1', DocumentType));
    end;

    local procedure LogSubmissionError(RecordVariant: Variant; DocumentType: Text; ErrorMessage: Text)
    var
        ActivityLog: Record "Activity Log";
        RecRef: RecordRef;
    begin
        RecRef.GetTable(RecordVariant);
        ActivityLog.LogActivity(
            RecRef,
            ActivityLog.Status::Failed,
            'SUBMIT',
            'Document submission failed',
            CopyStr(ErrorMessage, 1, 250));
    end;
}
