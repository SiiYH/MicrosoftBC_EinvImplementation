codeunit 70000011 "MY eInv Sales Invoice Doc" implements "MY eInv Document"
{
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";

    /// <summary>
    /// posted sales invoice
    /// </summary>
    /// <param name="SalesInvHeader"></param>

    procedure SetDocument(var SalesInvHeader: Record "Sales Invoice Header")
    begin
        SalesInvoiceHeader := SalesInvHeader;
    end;

    procedure GetDocumentNo(): Code[20]
    begin
        exit(SalesInvoiceHeader."No.");
    end;

    procedure GetDocumentType(): Text
    begin
        exit('Invoice');
    end;

    procedure GetDocumentRecord(var RecordVariant: Variant)
    begin
        RecordVariant := SalesInvoiceHeader;
    end;


}
