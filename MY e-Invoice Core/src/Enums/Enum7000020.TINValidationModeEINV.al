namespace MYeInvoiceCore.MYeInvoiceCore;

enum 7000020 "TIN Validation Mode EINV"
{
    Extensible = true;

    value(0; "Format Only")
    {
        Caption = 'Format Only';
    }
    value(1; "Auto API")
    {
        Caption = 'Auto API Validation';
    }
    value(2; "Manual")
    {
        Caption = 'Manual Button Only';
    }

}
