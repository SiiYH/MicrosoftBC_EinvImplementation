namespace MYeInvoiceCore.MYeInvoiceCore;

enum 7000012 "Payment Mode EINV"
{
    Extensible = true;

    value(0; " ")
    {
        Caption = ' ';
    }
    value(1; Cash)
    {
        Caption = 'Cash';
    }
    value(2; "Bank Transfer")
    {
        Caption = 'Bank Transfer';
    }
    value(3; Cheque)
    {
        Caption = 'Cheque';
    }
    value(4; "Credit Card")
    {
        Caption = 'Credit Card';
    }
    value(5; "Debit Card")
    {
        Caption = 'Debit Card';
    }
    value(6; "E-Wallet")
    {
        Caption = 'E-Wallet';
    }
    value(7; "Direct Debit")
    {
        Caption = 'Direct Debit';
    }
    value(8; Other)
    {
        Caption = 'Other';
    }
}
