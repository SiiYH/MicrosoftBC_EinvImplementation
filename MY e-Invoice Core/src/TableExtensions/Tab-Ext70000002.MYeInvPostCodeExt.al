tableextension 70000002 "MY eInv Post Code Ext" extends "Post Code"
{
    fields
    {
        field(70000000; "MY eInv State Code"; Code[20])
        {
            Caption = 'MY eInv State Code';
            TableRelation = "MY eInv LHDN Code".Code where("Code Type" = const(State));
        }
        field(70000001; "MY eInv State Description"; Text[250])
        {
            Caption = 'MY eInv State Description';
            FieldClass = FlowField;
            CalcFormula = Lookup("MY eInv LHDN Code".Description WHERE(Code = FIELD("MY eInv State Code"), "Code Type" = CONST("State")));
            Editable = false;
        }
    }

    procedure GetStateCodeFromPostCode(PostCode: Code[20]): Code[20]
    var
        MyInvLHDNCode: Record "MY eInv LHDN Code";
        PostCodePrefix: Text[2];
    begin
        if PostCode = '' then
            exit('');

        // Get first 2 digits of post code
        PostCodePrefix := CopyStr(PostCode, 1, 2);

        // Map post code ranges to state descriptions
        case PostCodePrefix of
            '01' .. '02':
                exit(FindStateCode('Perlis'));
            '05' .. '06':
                exit(FindStateCode('Kedah'));
            '10' .. '14':
                exit(FindStateCode('Pulau Pinang'));
            '30' .. '36':
                exit(FindStateCode('Perak'));
            '15' .. '18':
                exit(FindStateCode('Kelantan'));
            '20' .. '24':
                exit(FindStateCode('Terengganu'));
            '25' .. '28', '39':
                exit(FindStateCode('Pahang'));
            '40' .. '48', '63' .. '68':
                exit(FindStateCode('Selangor'));
            '50' .. '60':
                exit(FindStateCode('Wilayah Persekutuan Kuala Lumpur'));
            '70' .. '73':
                exit(FindStateCode('Negeri Sembilan'));
            '75' .. '78':
                exit(FindStateCode('Melaka'));
            '79' .. '86':
                exit(FindStateCode('Johor'));
            '87':
                exit(FindStateCode('Wilayah Persekutuan Labuan'));
            '88' .. '91':
                exit(FindStateCode('Sabah'));
            '93' .. '98':
                exit(FindStateCode('Sarawak'));
            '62':
                exit(FindStateCode('Wilayah Persekutuan Putrajaya'));
            else
                exit(FindStateCode('Not Applicable'));
        end;
    end;

    local procedure FindStateCode(StateName: Text): Code[20]
    var
        MyInvLHDNCode: Record "MY eInv LHDN Code";
    begin
        MyInvLHDNCode.SetRange("Code Type", MyInvLHDNCode."Code Type"::State);
        MyInvLHDNCode.SetFilter(Description, '@' + StateName + '*'); // Using @ for case-insensitive
        if MyInvLHDNCode.FindFirst() then
            exit(MyInvLHDNCode.Code);

        exit('');
    end;
}
