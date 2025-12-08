page 70000002 "MY eInv Password Dialog"
{
    PageType = Card;
    Caption = 'Enter Certificate Password / Azure Function Key';
    Editable = true;

    layout
    {
        area(content)
        {
            group(General)
            {
                field(Password; PasswordTxt)
                {
                    Caption = 'Password / Key';
                    ApplicationArea = All;
                    ExtendedDatatype = Masked; // Masks user input
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(OK)
            {
                Caption = 'OK';
                Image = Approve;
                Promoted = true;
                PromotedCategory = Process;
                ApplicationArea = All;

                trigger OnAction()
                begin
                    if PasswordTxt = '' then
                        Error('Password cannot be empty.');
                    CurrPage.Close();
                end;
            }

            action(Cancel)
            {
                Caption = 'Cancel';
                Image = Cancel;
                Promoted = true;
                PromotedCategory = Process;
                ApplicationArea = All;

                trigger OnAction()
                begin
                    PasswordTxt := '';
                    CurrPage.Close();
                end;
            }
        }
    }

    var
        PasswordTxt: Text;

    procedure GetPassword(): Text
    begin
        exit(PasswordTxt);
    end;
}
