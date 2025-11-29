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
        XMLGenerator: Codeunit "MY eInv XML Generator 02";
        DigitalSignature: Codeunit "MY eInv Digital Signature";
        Submission: Codeunit "MY eInv Submission";
        DocumentXML: Text;
        SignedXML: Text;
        SubmissionResult: Boolean;
        RecordVariant: Variant;
        ErrorMessage: Text;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        MaxRetries: Integer;
        RetryCount: Integer;
        WaitTime: Integer;
    begin
        Setup.Get();
        Document.GetDocumentRecord(RecordVariant);

        // Step 1: Generate XML
        DocumentXML := XMLGenerator.GenerateDocumentXML(RecordVariant, Document.GetDocumentType());

        // Step 2: Sign if needed
        if Setup."Document Version" = Setup."Document Version"::"1.1" then
            SignedXML := DigitalSignature.SignDocument(DocumentXML, Setup)
        else
            SignedXML := DocumentXML;

        // Step 3: Submit
        SubmissionResult := Submission.SubmitDocument(SignedXML, RecordVariant, Document.GetDocumentType(), ErrorMessage);

        /* if not SubmissionResult then
            Error('Failed to submit %1 %2:\%3', Document.GetDocumentType(), Document.GetDocumentNo(), ErrorMessage);

        Message('%1 %2 submitted successfully.', Document.GetDocumentType(), Document.GetDocumentNo()); */

        // Step 4: Wait and poll for validation
        /* SalesInvoiceHeader := RecordVariant;

        MaxRetries := 10;  // Try 10 times
        WaitTime := 2000;  // 2 seconds between retries

        for RetryCount := 1 to MaxRetries do begin
            Sleep(WaitTime);  // Wait before checking

            if Submission.GetDocumentDetails(SalesInvoiceHeader) then begin
                Message('Document validated!\IRBM Unique ID: %1\Ready to print.',
                        SalesInvoiceHeader."MY eInv IRBM Unique ID");
                exit;
            end;

            if RetryCount < MaxRetries then
                Message('Validation pending, checking again... (Attempt %1 of %2)', RetryCount, MaxRetries);
        end;

        Message('Document submitted but validation is taking longer than expected.\Use "Check MyInvois Status" action to check manually later.'); */
    end;
}
