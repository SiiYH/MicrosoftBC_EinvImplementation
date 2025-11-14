namespace MYeInvoiceCore.MYeInvoiceCore;

enum 7000018 "Billing Frequency EINV"
{
    Extensible = true;

    value(0; " ")
    {
        Caption = ' ';
    }
    value(1; Daily)
    {
        Caption = 'Daily';
    }
    value(2; Weekly)
    {
        Caption = 'Weekly';
    }
    value(3; Monthly)
    {
        Caption = 'Monthly';
    }
    value(4; Quarterly)
    {
        Caption = 'Quarterly';
    }
    value(5; "Half-Yearly")
    {
        Caption = 'Half-Yearly';
    }
    value(6; Yearly)
    {
        Caption = 'Yearly';
    }
    value(7; "One-Time")
    {
        Caption = 'One-Time';
    }
}
