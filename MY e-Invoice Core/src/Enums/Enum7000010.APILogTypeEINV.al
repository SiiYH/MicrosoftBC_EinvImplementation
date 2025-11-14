namespace MYeInvoiceCore.MYeInvoiceCore;

enum 7000010 "API Log Type EINV"
{
    Extensible = true;

    value(0; Information)
    {
        Caption = 'Information';
    }
    value(1; Warning)
    {
        Caption = 'Warning';
    }
    value(2; Error)
    {
        Caption = 'Error';
    }
    value(3; Debug)
    {
        Caption = 'Debug';
    }
}
