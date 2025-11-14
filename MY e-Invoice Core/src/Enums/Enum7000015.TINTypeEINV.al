namespace MYeInvoiceCore.MYeInvoiceCore;

enum 7000015 "TIN Type EINV"
{
    Extensible = true;

    value(0; " ")
    {
        Caption = ' ';
    }
    value(1; NRIC)
    {
        Caption = 'NRIC (Malaysian IC)';
    }
    value(2; Passport)
    {
        Caption = 'Passport';
    }
    value(3; BRN)
    {
        Caption = 'Business Registration Number';
    }
    value(4; "Army/Police")
    {
        Caption = 'Army/Police ID';
    }

}
