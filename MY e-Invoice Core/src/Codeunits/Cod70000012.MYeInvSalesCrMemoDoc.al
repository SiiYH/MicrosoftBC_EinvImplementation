codeunit 70000012 "MY eInv Sales CrMemo Doc" implements "MY eInv Document"
{

    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";

    procedure SetDocument(var SalesCrMemoHdr: Record "Sales Cr.Memo Header")
    begin
        SalesCrMemoHeader := SalesCrMemoHdr;
    end;

    procedure GetDocumentNo(): Code[20]
    begin
        exit(SalesCrMemoHeader."No.");
    end;

    procedure GetDocumentType(): Text
    begin
        exit('CreditMemo');
    end;

    procedure GetDocumentRecord(var RecordVariant: Variant)
    begin
        RecordVariant := SalesCrMemoHeader;
    end;

}
