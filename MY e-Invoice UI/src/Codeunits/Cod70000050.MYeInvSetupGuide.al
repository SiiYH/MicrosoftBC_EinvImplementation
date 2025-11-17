codeunit 70000050 "MY eInv Setup Guide"
{
    // This integrates with BC's Assisted Setup framework

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Guided Experience", 'OnRegisterAssistedSetup', '', false, false)]
    local procedure OnRegisterAssistedSetup()
    var
        GuidedExperience: Codeunit "Guided Experience";
        AssistedSetupGroup: Enum "Assisted Setup Group";
        VideoCategory: Enum "Video Category";
    begin
        GuidedExperience.InsertAssistedSetup(
            'LHDN E-Invoice Setup',
            'LHDN E-Invoice Setup',
            'Set up LHDN E-Invoice for Malaysia',
            5,
            ObjectType::Page,
            Page::"MY eInv Setup Card",
            AssistedSetupGroup::Extensions,
            '',
            VideoCategory::Uncategorized,
            '');
    end;
}
