namespace MYeInvoiceCore.MYeInvoiceCore;

enum 7000007 "Tax Type EINV"
{
    Extensible = true;

    value(0; " ")
    {
        Caption = ' ';
    }
    value(1; "Standard Rate")
    {
        Caption = 'Standard Rate (6%)';
    }
    value(2; "Zero Rate")
    {
        Caption = 'Zero Rate (0%)';
    }
    value(3; Exempt)
    {
        Caption = 'Exempt';
    }
    value(4; "Out of Scope")
    {
        Caption = 'Out of Scope';
    }
    value(5; "Service Tax")
    {
        Caption = 'Service Tax';
    }
    value(6; "Tourism Tax")
    {
        Caption = 'Tourism Tax';
    }

}
