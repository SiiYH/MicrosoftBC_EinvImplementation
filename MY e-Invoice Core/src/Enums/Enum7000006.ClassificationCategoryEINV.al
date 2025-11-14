namespace MYeInvoiceCore.MYeInvoiceCore;

enum 7000006 "Classification Category EINV"
{
    Extensible = true;

    value(0; " ")
    {
        Caption = ' ';
    }
    value(1; Goods)
    {
        Caption = 'Goods';
    }
    value(2; Services)
    {
        Caption = 'Services';
    }
    value(3; "Capital Goods")
    {
        Caption = 'Capital Goods';
    }
    value(4; "Medical Equipment")
    {
        Caption = 'Medical Equipment';
    }
    value(5; Others)
    {
        Caption = 'Others';
    }

}
