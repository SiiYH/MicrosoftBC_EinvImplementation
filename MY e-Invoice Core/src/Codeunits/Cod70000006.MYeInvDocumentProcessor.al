// ═════════════════════════════════════════════════════════════════
// USAGE EXAMPLE: Complete Flow
// ═════════════════════════════════════════════════════════════════
codeunit 70000006 "MY eInv Document Processor"
{
    procedure ProcessSalesInvoice(SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        Setup: Record "MY eInv Setup";
        XMLGenerator: Codeunit "MY eInv XML Generator";
        DigitalSignature: Codeunit "MY eInv Digital Signature";
        Submission: Codeunit "MY eInv Submission";
        InvoiceXML: Text;
        SignedXML: Text;
        SubmissionResult: Boolean;
    begin
        // Get setup
        Setup.Get();

        // Step 1: Generate UBL XML
        InvoiceXML := XMLGenerator.GenerateInvoiceXML(SalesInvoiceHeader);

        // Step 2: Sign if version 1.1
        if Setup."Document Version" = Setup."Document Version"::"1.1" then begin
            SignedXML := DigitalSignature.SignDocument(InvoiceXML, Setup);

            // Step 3: Submit signed document
            SubmissionResult := Submission.SubmitDocument(SignedXML, SalesInvoiceHeader);
        end else begin
            // Submit unsigned for v1.0
            SubmissionResult := Submission.SubmitDocument(InvoiceXML, SalesInvoiceHeader);
        end;

        if SubmissionResult then
            Message('Invoice %1 submitted successfully to MyInvois.', SalesInvoiceHeader."No.")
        else
            Error('Failed to submit invoice %1.', SalesInvoiceHeader."No.");
    end;
}
