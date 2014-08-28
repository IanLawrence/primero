caafag_profile_fields = [
  Field.new({"name" => "un_ddr_no",
             "type" => "text_field",
             "display_name_all" => "UN DDR Number"
            }),
  Field.new({"name" => "cafaag_name_armed_group",
             "type" => "select_box",
             "display_name_all" => "With which Armed Force or Armed Group was the child associated?",
             "option_strings_text_all" =>
                                  ["Government Force",
                                   "LTTE",
                                   "Ml24",
                                   "Non government forces",
                                   "None",
                                   "Other Paramilitary group",
                                   "SF",
                                   "SLA",
                                   "SPLA",
                                   "TMVP",
                                   "Unknown"].join("\n"),
            }),
  Field.new({"name" => "cafaag_enrollment_reason_not_forced",
             "type" => "select_box",
             "display_name_all" => "If not forced, what was the main reason why the child became involved in the Armed Force or Armed Group? (type of recruitment)",
             "option_strings_text_all" =>
                                  ["Voluntary enrollment",
                                   "Family problems/abuse",
                                   "Financial reasons",
                                   "Lack of access to essential services",
                                   "Poverty",
                                   "Wanted to fight for their beliefs",
                                   "Wanted to follow friends",
                                   "Other"].join("\n"),
            }),
  Field.new({"name" => "cafaag_enrollment_reason_not_forced_text",
             "type" => "text_field",
             "display_name_all" => "Other reason for enrollment"
            }),
  Field.new({"name" => "cafaag_name_militaryunit",
             "type" => "text_field",
             "display_name_all" => "Name of Military Unit"
            }),
  Field.new({"name" => "cafaag_name_commander",
             "type" => "text_field",
             "display_name_all" => "Commander's Name"
            }),
  Field.new({"name" => "address_cafaag_militaryunit",
             "type" => "text_field",
             "display_name_all" => "Area of Military Unit"
            }),
  Field.new({"name" => "location_cafaag_militaryunit",
             "type" => "text_field",
             "display_name_all" => "Location of Military Unit"
            }),
  Field.new({"name" => "cafaag_child_role",
             "type" => "select_box",
             "display_name_all" => "What was the main role of the child?",
             "option_strings_text_all" =>
                                  ["Combat",
                                   "Combat support",
                                   "Combattant",
                                   "Commander/Ranked position",
                                   "Girlfriend",
                                   "Girlfriend/""Wife""/Forced Sexual Activity",
                                   "Non-Combat",
                                   "Non-Combat (cook, guide, porter, etc.)",
                                   "Other"].join("\n"),
            }),
  Field.new({"name" => "cafaag_child_owned_weapon",
             "type" => "select_box",
             "display_name_all" => "Did the child own/use a weapon",
             "option_strings_text_all" => "Don't know\nNo\nYes",
            }),
  Field.new({"name" => "cafaag_weapon_type",
             #TODO (get values from MRM)
             "type" => "text_field",
             "display_name_all" => "Type of Weapon"
            }),
  Field.new({"name" => "cafaag_date_child_join",
             "type" => "date_range",
             "display_name_all" => "When did the child join the Armed Force or Armed Group?"
            }),
  Field.new({"name" => "address_cafaag_registration",
             "type" => "text_field",
             "display_name_all" => "Place of registration (Village/Address/Area) - Address"
            }),
  Field.new({"name" => "address_cafaag_mobilization",
             "type" => "text_field",
             "display_name_all" => "Area of Mobilization"
            }),
  Field.new({"name" => "location_cafaag_mobilization",
             "type" => "text_field",
             "display_name_all" => "Location of Mobilization"
            }),
  Field.new({"name" => "cafaag_date_child_leave",
             "type" => "date_range",
             "display_name_all" => "When did the child leave the Armed Force or Armed Group?"
            }),
  Field.new({"name" => "cafaag_how_did_child_leave_armed_group",
             "type" => "select_box",
             "display_name_all" => "How did the child leave the Armed Force or Armed Group?",
             "option_strings_text_all" =>
                                  ["Captured",
                                   "Deceased",
                                   "Dissolution of the group",
                                   "Escape/Runaway",
                                   "Formal DDR program",
                                   "Locally negotiated demobilization",
                                   "Normal",
                                   "Other (Please specify)",
                                   "Released/Handover to family",
                                   "Released/Handover to government",
                                   "Released/Handover to Organization",
                                   "Runaway",
                                   "Surrendered",
                                   "UNICEF DDR"].join("\n"),
            }),
  Field.new({"name" => "address_cafaag_demobilization",
             "type" => "text_field",
             "display_name_all" => "Address of Demobilization"
            }),
  Field.new({"name" => "location_cafaag_demobilization",
             "type" => "text_field",
             "display_name_all" => "Location of Demobilization"
            }),
  Field.new({"name" => "cafaag_demobilization_papers_served",
             "type" => "select_box",
             "display_name_all" => "Has the Child been served any demobilization papers?",
             "option_strings_text_all" => "Don't know\nNo\nYes",
            }),
  Field.new({"name" => "cafaag_reason_for_release_from_military",
             "type" => "select_box",
             "display_name_all" => "Reason for release from Military",
             "option_strings_text_all" =>
                                  ["Captured",
                                   "Deceased",
                                   "Dissolution of the group",
                                   "Formal DDR program",
                                   "Released/Handover to government",
                                   "Released/Handover to organization",
                                   "Released/Handover to family",
                                   "Runaway",
                                   "Surrendered"].join("\n"),
            })
]

FormSection.create_or_update_form_section({
  :unique_id => "caafag_profile",
  :parent_form=>"case",
  "visible" => true,
  :order_form_group => 70,
  :order => 50,
  :order_subform => 0,
  :form_group_name => "Assessment",
  :fields => caafag_profile_fields,
  :perm_visible => true,
  "editable" => true,
  "name_all" => "CAAFAG Profile",
  "description_all" => "CAAFAG Profile"
})