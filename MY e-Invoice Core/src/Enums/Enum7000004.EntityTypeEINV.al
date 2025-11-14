namespace MYeInvoiceCore.MYeInvoiceCore;
/// <summary>
/// Customer/Vendor Type for e-Invoice
/// </summary>
/// 
enum 7000004 "Entity Type EINV"
{
    Extensible = false;

    value(0; " ")
    {
        Caption = ' ';
    }
    value(1; "Malaysian Individual")
    {
        Caption = 'Malaysian Individual';
    }
    value(2; "Foreign Individual")
    {
        Caption = 'Foreign Individual';
    }
    value(3; "Malaysian Business")
    {
        Caption = 'Malaysian Business';
    }
    value(4; "Foreign Business")
    {
        Caption = 'Foreign Business';
    }
    value(5; Government)
    {
        Caption = 'Government';
    }
}
