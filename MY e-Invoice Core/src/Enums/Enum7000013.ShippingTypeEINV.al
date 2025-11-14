namespace MYeInvoiceCore.MYeInvoiceCore;

enum 7000013 "Shipping Type EINV"
{
    Extensible = true;

    value(0; " ")
    {
        Caption = ' ';
    }
    value(1; Courier)
    {
        Caption = 'Courier';
    }
    value(2; "Postal Service")
    {
        Caption = 'Postal Service';
    }
    value(3; "Own Transport")
    {
        Caption = 'Own Transport';
    }
    value(4; "Third Party")
    {
        Caption = 'Third Party';
    }
    value(5; "Air Freight")
    {
        Caption = 'Air Freight';
    }
    value(6; "Sea Freight")
    {
        Caption = 'Sea Freight';
    }
    value(7; Other)
    {
        Caption = 'Other';
    }
}
