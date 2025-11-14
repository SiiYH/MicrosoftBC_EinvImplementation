namespace MYeInvoiceCore.MYeInvoiceCore;

enum 7000009 "Error Category EINV"
{
    Extensible = true;

    value(0; " ")
    {
        Caption = ' ';
    }
    value(1; Authentication)
    {
        Caption = 'Authentication';
    }
    value(2; Validation)
    {
        Caption = 'Validation';
    }
    value(3; "Business Rule")
    {
        Caption = 'Business Rule';
    }
    value(4; "Rate Limit")
    {
        Caption = 'Rate Limit';
    }
    value(5; "Server Error")
    {
        Caption = 'Server Error';
    }
    value(6; Network)
    {
        Caption = 'Network';
    }
    value(7; "Data Error")
    {
        Caption = 'Data Error';
    }
}
