namespace MYeInvoiceCore.MYeInvoiceCore;

enum 7000000 "LHDN Environment EINV"
{
    Extensible = false;

    value(0; Sandbox)
    {
        Caption = 'Sandbox (Pre-Production)';
    }
    value(1; Production)
    {
        Caption = 'Production';
    }

}
