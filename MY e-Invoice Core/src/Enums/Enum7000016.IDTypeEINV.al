namespace MYeInvoiceCore.MYeInvoiceCore;

enum 7000016 "ID Type EINV"
{
    Extensible = true;

    value(0; " ")
    {
        Caption = ' ';
    }
    value(1; NRIC)
    {
        Caption = 'NRIC';
    }
    value(2; Passport)
    {
        Caption = 'Passport';
    }
    value(3; "Army/Police ID")
    {
        Caption = 'Army/Police ID';
    }
    value(4; "Other")
    {
        Caption = 'Other ID';
    }

}
