interface "MY eInv Document"
{
    procedure GetDocumentNo(): Code[20];
    procedure GetDocumentType(): Text;
    procedure GetDocumentRecord(var RecordVariant: Variant);
}