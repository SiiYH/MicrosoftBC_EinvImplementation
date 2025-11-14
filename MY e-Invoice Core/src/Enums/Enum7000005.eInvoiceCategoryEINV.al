namespace MYeInvoiceCore.MYeInvoiceCore;

/// <summary>
/// e-Invoice Category
/// </summary>

enum 7000005 "e-Invoice Category EINV"
{
    Extensible = false;

    value(0; " ")
    {
        Caption = ' ';
    }
    value(1; Individual)
    {
        Caption = 'Individual';
    }
    value(2; Consolidated)
    {
        Caption = 'Consolidated';
    }
}
