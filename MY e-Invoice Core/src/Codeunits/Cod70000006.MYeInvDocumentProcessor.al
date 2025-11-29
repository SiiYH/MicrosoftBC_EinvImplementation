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
    begin
        Setup.Get();
        Document.GetDocumentRecord(RecordVariant);

        // Step 1: Generate UBL XML
        DocumentXML := XMLGenerator.GenerateDocumentXML(RecordVariant, Document.GetDocumentType());

        // Step 2: Sign if version 1.1
        if Setup."Document Version" = Setup."Document Version"::"1.1" then begin
            SignedXML := DigitalSignature.SignDocument(DocumentXML, Setup);
            SubmissionResult := Submission.SubmitDocument(SignedXML, RecordVariant, Document.GetDocumentType(), ErrorMessage);
        end else begin
            SubmissionResult := Submission.SubmitDocument(DocumentXML, RecordVariant, Document.GetDocumentType(), ErrorMessage);
        end;

        // if SubmissionResult then
        //     Message('%1 %2 submitted successfully to MyInvois.', Document.GetDocumentType(), Document.GetDocumentNo())
        // else
        //     Error('Failed to submit %1 %2:\%3', Document.GetDocumentType(), Document.GetDocumentNo(), ErrorMessage);
    end;
}
