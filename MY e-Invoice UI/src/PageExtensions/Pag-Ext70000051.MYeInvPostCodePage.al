pageextension 70000051 "MY eInv Post Code Page" extends "Post Codes"
{
    layout
    {
        addafter(City)
        {

            field("MY eInv State Code"; Rec."MY eInv State Code")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the MY eInv State Code field.', Comment = '%';
            }
        }
    }

    actions
    {
        addlast(Processing)
        {
            action(UpdateMYeInvStateCode)
            {
                Caption = 'Update MY e-Inv State Code';
                ApplicationArea = all;
                trigger OnAction()
                var
                    PostCodePrefix: Text;
                begin
                    PostCodePrefix := CopyStr(Rec.Code, 1, 2);

                    case PostCodePrefix of
                        '01' .. '02':
                            begin

                            end;
                            exit('01'); // Johor
                        '10' .. '14':
                            exit('02'); // Kedah
                        '15' .. '16':
                            exit('03'); // Kelantan
                                        // ... etc
                    end;
                end;
            }
        }
        addafter(Category_Process)
        {

        }
    }
}
