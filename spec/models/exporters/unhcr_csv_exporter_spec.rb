require 'rails_helper'

module Exporters
  describe UnhcrCSVExporter do
    before :each do
      FormSection.all.all.each { |form| form.destroy }
      fields = [
          Field.new({"name" => "registration_date",
                     "type" => "date_field",
                     "display_name_all" => "Registration Date"
                    })
        ]
      form = FormSection.new(
        :unique_id => "form_section_test_for_risk_level_follow_up",
        :parent_form=>"case",
        "visible" => true,
        :order_form_group => 50,
        :order => 15,
        :order_subform => 0,
        :form_group_name => "Form Section Test",
        "editable" => true,
        "name_all" => "Form Section Test",
        "description_all" => "Form Section Test",
        :fields => fields
          )
      form.save!
      Child.any_instance.stub(:field_definitions).and_return(fields)
      Child.refresh_form_properties
      Child.all.each { |form| form.destroy }

      @child_cls = Child.clone
      @child_cls.class_eval do
        property :unhcr_needs_codes, [String]
        property :nationality, [String]
        property :ethnicity, [String]
        property :protection_concerns, [String]
        property :language, [String]
        property :family_details_section, [Class.new do
          include CouchRest::Model::Embeddable
          property :relation_name, String
          property :relation, String
        end]
      end
      @test_child = Child.new()
    end

    after :each do
      property_index = @child_cls.properties.find_index{|p| p.name == "family_details_section"}
      @child_cls.properties.delete_at(property_index)
    end

    it "converts unhcr_needs_codes to comma separated string" do
      @test_child.unhcr_needs_codes = ['abc', 'def']

      data = UnhcrCSVExporter.export([@test_child])

      parsed = CSV.parse(data)
      expect(parsed[1][parsed[0].index("Secondary Protection Concerns")]).to eq('abc, def')
    end

    describe 'export configuration' do
      before do
        ExportConfiguration.all.each &:destroy
        SystemSettings.all.each &:destroy
        SystemSettings.create(default_locale: "en")
      end

      context 'when no export configuration' do
        it 'exports all defined properties' do
          data = UnhcrCSVExporter.export([@test_child])
          parsed = CSV.parse(data)
          expect(parsed[0]).to eq(["ID",
                                   "Individual Progress ID",
                                   "CPIMS Code",
                                   "Date of Identification",
                                   "Primary Protection Concerns",
                                   "Secondary Protection Concerns",
                                   "Governorate - Country",
                                   "Sex",
                                   "Date of Birth",
                                   "Age",
                                   "Causes of Separation",
                                   "Country of Origin",
                                   "Current Care Arrangement",
                                   "Reunification Status",
                                   "Case Status"])
        end
      end

      context 'when export configuration is the same as properties defined in the exporter' do
        before do
          ExportConfiguration.create(id: "export-test-same", name: "Test Same Properties", export_id: "unhcr_csv",
            property_keys: [
              "individual_progress_id",
              "cpims_code",
              "date_of_identification",
              "primary_protection_concerns",
              "secondary_protection_concerns",
              "governorate_country",
              "sex",
              "date_of_birth",
              "age",
              "causes_of_separation",
              "country_of_origin",
              "current_care_arrangement",
              "reunification_status",
              "case_status"
            ]
          )

          SystemSettings.any_instance.stub(:unhcr_export_config_id).and_return('export-test-same')
        end

        it 'exports all defined properties' do
          data = UnhcrCSVExporter.export([@test_child])
          parsed = CSV.parse(data)
          expect(parsed[0]).to eq(["ID",
                                   "Individual Progress ID",
                                   "CPIMS Code",
                                   "Date of Identification",
                                   "Primary Protection Concerns",
                                   "Secondary Protection Concerns",
                                   "Governorate - Country",
                                   "Sex",
                                   "Date of Birth",
                                   "Age",
                                   "Causes of Separation",
                                   "Country of Origin",
                                   "Current Care Arrangement",
                                   "Reunification Status",
                                   "Case Status"])
        end
      end

      context 'when export configuration is different than properties defined in the exporter' do
        context 'and the configuration is in a different order' do
          before do
            ExportConfiguration.create(id: "export-test-different-order", name: "Test Properties Order", export_id: "unhcr_csv",
               property_keys: [
                 "case_status",
                 "reunification_status",
                 "current_care_arrangement",
                 "country_of_origin",
                 "governorate_country",
                 "date_of_identification",
                 "individual_progress_id",
                 "cpims_code",
                 "primary_protection_concerns",
                 "secondary_protection_concerns",
                 "sex",
                 "date_of_birth",
                 "age",
                 "causes_of_separation"
               ]
            )

            SystemSettings.any_instance.stub(:unhcr_export_config_id).and_return('export-test-different-order')
          end

          it 'exports properties in the same order as the config' do
            data = UnhcrCSVExporter.export([@test_child])
            parsed = CSV.parse(data)
            expect(parsed[0]).to eq(["ID",
                                     "Case Status",
                                     "Reunification Status",
                                     "Current Care Arrangement",
                                     "Country of Origin",
                                     "Governorate - Country",
                                     "Date of Identification",
                                     "Individual Progress ID",
                                     "CPIMS Code",
                                     "Primary Protection Concerns",
                                     "Secondary Protection Concerns",
                                     "Sex",
                                     "Date of Birth",
                                     "Age",
                                     "Causes of Separation"])
          end
        end

        context 'and the configuration has less property keys than defined in the exporter' do
          before do
            ExportConfiguration.create(id: "export-test-less", name: "Test Less Properties", export_id: "unhcr_csv",
              property_keys: [
                "individual_progress_id",
                "cpims_code",
                "date_of_identification",
                "current_care_arrangement",
                "reunification_status",
                "case_status"
              ]
            )

            SystemSettings.any_instance.stub(:unhcr_export_config_id).and_return('export-test-less')
          end

          it 'exports only properties defined in the config' do
            data = UnhcrCSVExporter.export([@test_child])
            parsed = CSV.parse(data)
            expect(parsed[0]).to eq(["ID",
                                     "Individual Progress ID",
                                     "CPIMS Code",
                                     "Date of Identification",
                                     "Current Care Arrangement",
                                     "Reunification Status",
                                     "Case Status"])
          end
        end

        context 'and the configuration has more property keys than defined in the exporter' do
          before do
            ExportConfiguration.create(id: "export-test-more", name: "Test More Properties", export_id: "unhcr_csv",
              property_keys: [
                "individual_progress_id",
                "cpims_code",
                "extra_1",
                "date_of_identification",
                "primary_protection_concerns",
                "extra_2",
                "secondary_protection_concerns",
                "governorate_country",
                "sex",
                "extra_3",
                "date_of_birth",
                "age",
                "causes_of_separation",
                "country_of_origin",
                "extra_4",
                "current_care_arrangement",
                "reunification_status",
                "extra_5",
                "case_status"
              ]
            )

            SystemSettings.any_instance.stub(:unhcr_export_config_id).and_return('export-test-more')
          end

          it 'exports only the properties defined in the exporter' do
            data = UnhcrCSVExporter.export([@test_child])
            parsed = CSV.parse(data)
            expect(parsed[0]).to eq(["ID",
                                     "Individual Progress ID",
                                     "CPIMS Code",
                                     "Date of Identification",
                                     "Primary Protection Concerns",
                                     "Secondary Protection Concerns",
                                     "Governorate - Country",
                                     "Sex",
                                     "Date of Birth",
                                     "Age",
                                     "Causes of Separation",
                                     "Country of Origin",
                                     "Current Care Arrangement",
                                     "Reunification Status",
                                     "Case Status"])
          end
        end

        context 'and the configuration is missing some properties and has some extra property keys than defined in the exporter' do
          before do
            ExportConfiguration.create(id: "export-test-mixture", name: "Test Some More Some Less Properties", export_id: "unhcr_csv",
               property_keys: [
                 "individual_progress_id",
                 "date_of_birth",
                 "age",
                 "cpims_code",
                 "extra_1",
                 "extra_2",
                 "secondary_protection_concerns",
                 "governorate_country",
                 "sex",
                 "extra_3",
                 "current_care_arrangement",
                 "reunification_status",
                 "extra_4",
                 "case_status"
               ]
            )

            SystemSettings.any_instance.stub(:unhcr_export_config_id).and_return('export-test-mixture')
          end

          it 'exports only properties defined in the config and in the exporter' do
            data = UnhcrCSVExporter.export([@test_child])
            parsed = CSV.parse(data)
            expect(parsed[0]).to eq(["ID",
                                     "Individual Progress ID",
                                     "Date of Birth",
                                     "Age",
                                     "CPIMS Code",
                                     "Secondary Protection Concerns",
                                     "Governorate - Country",
                                     "Sex",
                                     "Current Care Arrangement",
                                     "Reunification Status",
                                     "Case Status"])
          end
        end
      end
    end
  end
end
