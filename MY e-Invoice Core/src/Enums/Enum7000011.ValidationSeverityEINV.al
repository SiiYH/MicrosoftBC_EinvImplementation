namespace MYeInvoiceCore.MYeInvoiceCore;

enum 7000011 "Validation Severity EINV"
{
    Extensible = false;

    value(0; Error)
    {
        Caption = 'Error';
    }
    value(1; Warning)
    {
        Caption = 'Warning';
    }
    value(2; Information)
    {
        Caption = 'Information';
    }
}
