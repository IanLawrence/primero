# -*- coding: utf-8 -*-
require 'spec_helper'

describe FormSection do
  before do
    FormSection.all.each &:destroy
    PrimeroModule.all.each &:destroy
    Role.all.each &:destroy
    @form_section_a = FormSection.create!(unique_id: "A", name: "A", parent_form: 'case', form_group_name: "M")
    @form_section_b = FormSection.create!(unique_id: "B", name: "B", parent_form: 'case', form_group_name: "X")
    @form_section_c = FormSection.create!(unique_id: "C", name: "C", parent_form: 'case', form_group_name: "Y")
    @primero_module = PrimeroModule.create!(program_id: "some_program", name: "Test Module", associated_record_types: ['case'], associated_form_ids: ["A", "B"])
    @permission_case_read = Permission.new(resource: Permission::CASE, actions: [Permission::READ])
    @role = Role.create!(permitted_form_ids: ["B", "C"], name: "Test Role", permissions_list: [@permission_case_read])
    @user = User.new(user_name: "test_user", role_ids: [@role.id], module_ids: [@primero_module.id])
  end

  def create_formsection(stubs={})
    stubs.reverse_merge!(:fields=>[], :save => true, :editable => true, :base_language => "en")
    @create_formsection = FormSection.new stubs
  end

  def new_field(fields = {})
    fields.reverse_merge!(:name=>random_string)
    Field.new fields
  end

  def random_string(length=10)
    #hmmm
    chars = 'abcdefghjkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789'
    password = ''
    length.times { password << chars[rand(chars.size)] }
    password
  end

  def new_should_be_called_with (name, value)
    FormSection.should_receive(:new) { |form_section_hash|
      form_section_hash[name].should == value
    }
  end

  it "should return all the searchable fields" do
    text_field = Field.new(:name => "text_field", :type => Field::TEXT_FIELD)
    text_area = Field.new(:name => "text_area", :type => Field::TEXT_AREA)
    select_box = Field.new(:name => "select_box", :type => Field::SELECT_BOX)
    radio_button = Field.new(:name => "radio_button", :type => Field::RADIO_BUTTON)
    f = FormSection.new(:fields => [text_field, text_area, select_box, radio_button])
    f.all_searchable_fields.should == [text_area]
  end

  describe "get_permitted_form_sections" do
    it "returns all FormSection objects that are bound to the case's module that the user has access to" do
      child = Child.new(unique_identifier: "123", module_id: @primero_module.id)
      expect(FormSection.get_permitted_form_sections(child.module, child.class.parent_form, @user)).to eq([@form_section_b])
    end

    it "returns no FormSection objects if the user cannot view the permitted module forms" do
      role = Role.create!(permitted_form_ids: ["C"], name: "Test Role 2", permissions_list: [@permission_case_read])
      user = User.new(user_name: "test_user_2", role_ids: [role.id], module_ids: [@primero_module.id])
      child = Child.new(unique_identifier: "123", module_id: @primero_module.id)
      expect(FormSection.get_permitted_form_sections(child.module, child.class.parent_form, user)).to eq([])
    end

    it "returns the FormSection objects that correspond to the record's type" do
      form_section_d = FormSection.create!(unique_id: "D", name: "D", parent_form: 'incident')
      primero_module = PrimeroModule.create!(program_id: "some_program", name: "Test Module With different records", associated_record_types: ['case', 'incident'], associated_form_ids: ["A", "B", "D"])
      user = User.new(user_name: "test_user", role_ids: [@role.id], module_ids: [primero_module.id])
      child = Child.new(unique_identifier: "123", module_id: primero_module.id)

      expect(FormSection.get_permitted_form_sections(child.module, child.class.parent_form, user)).to eq([@form_section_b])
    end
  end

  describe "mobile forms" do
    before do
      @form_section_mobile_1_nested = FormSection.create!(unique_id: "MOBILE_1_NESTED", name: "Mobile 1 Nested",
                                                          parent_form: "case", mobile_form: false, is_nested: true, visible: false,
                                                          fields: [Field.new(name: "field1", type: "text_field", display_name_all: "field1")])
      @form_section_mobile_1 = FormSection.create!(unique_id: "MOBILE_1", name: "Mobile 1", parent_form: "case", mobile_form: true,
                                                   fields: [Field.new(name: "mobile_1_nested", type: "subform",
                                                                      subform_section_id: "MOBILE_1_NESTED", display_name_all: "Mobile 1 Nested")])
      @mobile_field1 = Field.new(name: "field1", type: "text_field", display_name_all: "field1")
      @mobile_field2 = Field.new(name: "field2", type: "text_field", display_name_all: "field2", mobile_visible: true)
      @mobile_field3 = Field.new(name: "field3", type: "text_field", display_name_all: "field3", mobile_visible: false)
      @mobile_field4 = Field.new(name: "field4", type: "text_field", display_name_all: "field4", mobile_visible: false)
      @mobile_field5 = Field.new(name: "field5", type: "text_field", display_name_all: "field5")
      @form_section_mobile_2 = FormSection.create!(unique_id: "MOBILE_2", name: "Mobile 2", parent_form: "case", mobile_form: true,
                                                   fields: [@mobile_field1, @mobile_field2, @mobile_field3, @mobile_field4,
                                                            @mobile_field5])
      @mobile_module = PrimeroModule.create!(program_id: "some_program", name: "Mobile Module", associated_record_types: ['case'],
                                             associated_form_ids: ["A", "B", "MOBILE_1"])
      @roleM = Role.create!(permitted_form_ids: ["B", "C", "MOBILE_1"], name: "Test Role Mobile", permissions_list: [@permission_case_read])
      @userM = User.new(user_name: "test_user_m", role_ids: [@roleM.id], module_ids: [@primero_module.id])
    end

    describe "get_permitted_mobile_form_sections" do
      it "returns mobile forms" do
        expect(FormSection.get_permitted_mobile_form_sections(@mobile_module, 'case', @userM)).to include(@form_section_mobile_1)
      end

      it "returns subforms for mobile forms" do
        expect(FormSection.get_permitted_mobile_form_sections(@mobile_module, 'case', @userM)).to include(@form_section_mobile_1_nested)
      end

      it "does not return non mobile forms" do
        expect(FormSection.get_permitted_mobile_form_sections(@mobile_module, 'case', @userM)).not_to include(@form_section_b)
      end

      it "does not return forms that the user does not have access to" do
        expect(FormSection.get_permitted_mobile_form_sections(@mobile_module, 'case', @userM)).not_to include(@form_section_mobile_2)
      end
    end

    describe 'format_forms_for_mobile' do
      it 'formats for moble' do
        expected = {"Children"=>
                        [{"unique_id"=>"MOBILE_1",
                          :name=>{"en"=>"Mobile 1", "fr"=>"", "ar"=>"", "es"=>""},
                          "order"=>0,
                          :help_text=>{"en"=>"", "fr"=>"", "ar"=>"", "es"=>""},
                          "base_language"=>"en",
                          "fields"=>
                              [{"name"=>"mobile_1_nested",
                                "editable"=>true,
                                "multi_select"=>false,
                                "type"=>"subform",
                                "required"=>false,
                                "show_on_minify_form"=>false,
                                "mobile_visible"=>true,
                                :display_name=>{"en"=>"Mobile 1 Nested", "fr"=>"Mobile 1 Nested", "ar"=>"Mobile 1 Nested", "es"=>"Mobile 1 Nested"},
                                :help_text=>{"en"=>"", "fr"=>"", "ar"=>"", "es"=>""},
                                :option_strings_text=>{"en"=>[], "fr"=>[], "ar"=>[], "es"=>[]}}]}]}
        form_sections = FormSection.group_forms([@form_section_mobile_1], true)
        expect(FormSection.format_forms_for_mobile(form_sections, :en, 'case')).to eq(expected)
      end
    end

    describe 'all_mobile_fields' do
      it 'returns the mobile visible fields' do
        #NOTE: The default of mobile_visible is true.
        expect(@form_section_mobile_2.all_mobile_fields).to include(@mobile_field1, @mobile_field2, @mobile_field5)
      end

      it 'does not return fields that are not mobile visible' do
        expect(@form_section_mobile_2.all_mobile_fields).not_to include(@mobile_field3, @mobile_field4)
      end
    end

  end

  describe "list_form_group_names" do
    it "return form group name that correspond to the current module" do
      form_group_names = FormSection.list_form_group_names(@primero_module, 'case', @user)
      expect(form_group_names).to match_array(["X"])
    end

    it "add new form group and ensure group order" do
      @form_section_d = FormSection.create!(unique_id: "D", name: "D", parent_form: 'case', form_group_name: "G")
      @form_section_e = FormSection.create!(unique_id: "E", name: "E", parent_form: 'case', form_group_name: "K")
      @primero_module.associated_form_ids << "E"
      @primero_module.associated_form_ids << "D"
      @primero_module.save!
      @role.permitted_form_ids << "D"
      @role.permitted_form_ids << "E"
      @role.save!
      form_group_names = FormSection.list_form_group_names(@primero_module, 'case', @user)
      expect(form_group_names).to match_array(["G", "K", "X"])
    end
  end

  describe "group_forms" do
    it "groups forms by the group name" do
      form_section_a = FormSection.new(unique_id: "A", name: "A", form_group_name: "X")
      form_section_b = FormSection.new(unique_id: "B", name: "B", form_group_name: "X")
      form_section_c = FormSection.new(unique_id: "C", name: "C", form_group_name: "Y")

      result = FormSection.group_forms([form_section_a, form_section_b, form_section_c])

      expect(result).to be_a Hash
      expect(result.keys).to match_array(["X", "Y"])
      expect(result["X"]).to match_array([form_section_a, form_section_b])
      expect(result["Y"]).to match_array([form_section_c])
    end
  end

  describe "link_subforms" do
    it "links forms to subforms if both are provided in the input list" do

      fields_a = [
        Field.new(name: "a_0", type: Field::TEXT_FIELD),
        Field.new(name: "a_1", type: Field::TEXT_FIELD)
      ]
      form_section_a = FormSection.new(unique_id: "A", name: "A", fields: fields_a, visible: false)

      fields_b = [
        Field.new(name: "b_0", type: Field::TEXT_FIELD),
        Field.new(name: "b_1", type: Field::TEXT_FIELD)
      ]
      form_section_b = FormSection.new(unique_id: "B", name: "B", fields: fields_b)

      fields_c = [
        Field.new(name: "c_0", type: Field::TEXT_FIELD),
        Field.new(name: "c_1", type: Field::SUBFORM, subform_section_id: "A")
      ]
      form_section_c = FormSection.new(unique_id: "C", name: "C", fields: fields_c)

      result = FormSection.link_subforms([form_section_a, form_section_b, form_section_c])
      result_subform_field = result.select{|f|f.unique_id=='C'}.first.fields.select{|f|f.name=='c_1'}.first

      expect(result).to be_an Array
      expect(result_subform_field.subform).to be_a FormSection
      expect(result_subform_field.subform.unique_id).to eq("A")
    end
  end


  describe '#unique_id' do
    it "should be generated when not provided" do
      f = FormSection.new
      f.unique_id.should_not be_empty
    end

    it "should not be generated when provided" do
      f = FormSection.new :unique_id => 'test_form'
      f.unique_id.should == 'test_form'
    end

    it "should not allow duplicate unique ids" do
      FormSection.new(:unique_id => "test", :name => "test").save!

      expect {
        FormSection.new(:unique_id => "test").save!
      }.to raise_error

      expect {
        FormSection.get_by_unique_id("test").save!
      }.to_not raise_error
    end
  end

  describe "repository methods" do
    before { FormSection.all.each &:destroy }

    describe "enabled_by_order" do
      it "should bring back sections in order" do
        second = FormSection.create! :name => 'Second', :order => 2, :unique_id => 'second'
        first = FormSection.create! :name => 'First', :order => 1, :unique_id => 'first'
        third = FormSection.create! :name => 'Third', :order => 3, :unique_id => 'third'
        FormSection.enabled_by_order.map(&:name).should == %w( First Second Third )
      end

      it "should exclude disabled sections" do
        expected = FormSection.create! :name => 'Good', :order => 1, :unique_id => 'good'
        unwanted = FormSection.create! :name => 'Bad', :order => 2, :unique_id => 'bad', :visible => false
        FormSection.enabled_by_order.map(&:name).should == %w(Good)
        FormSection.enabled_by_order.map(&:name).should_not ==  %w(Bad)
      end
    end

    describe "enabled_by_order_without_hidden_fields" do
      it "should exclude hidden fields" do
        visible_field = Field.new(:name => "visible_field", :display_name => "Visible Field", :visible => true)
        hidden_field = Field.new(:name => "hidden_field", :display_name => "Hidden Field", :visible => false)

        section = FormSection.new :name => 'section', :order => 1, :unique_id => 'section'
        section.fields = [visible_field, hidden_field]
        section.save!

        form_section = FormSection.enabled_by_order_without_hidden_fields.first
        form_section.fields.should == [visible_field]
      end
    end

  end

  describe "mobile forms" do
    before do
      FormSection.all.each &:destroy
      @form_section_a = FormSection.create!(unique_id: "A", name: "A", parent_form: 'case')
      @form_section_b = FormSection.create!(unique_id: "B", name: "B", parent_form: 'case')
      @form_section_c = FormSection.create!(unique_id: "C", name: "C", parent_form: 'case')
      @form_section_d = FormSection.create!(unique_id: "D", name: "D", parent_form: 'case', mobile_form: true)
      @form_section_e = FormSection.create!(unique_id: "E", name: "E", parent_form: 'incident')
      @form_section_f = FormSection.create!(unique_id: "F", name: "F", parent_form: 'incident', mobile_form: true)
    end

    it "should create new form with default mobile_form value false" do
      expect(@form_section_a.mobile_form).to be_false
    end

    it "should find all mobile case forms" do
      expect(FormSection.find_mobile_forms_by_parent_form('case')).to include(@form_section_d)
      expect(FormSection.find_mobile_forms_by_parent_form('case')).not_to include(@form_section_f)
      expect(FormSection.find_mobile_forms_by_parent_form('case').count).to eq(1)
    end

    it "should find all mobile incident forms" do
      expect(FormSection.find_mobile_forms_by_parent_form('incident')).not_to include(@form_section_d)
      expect(FormSection.find_mobile_forms_by_parent_form('incident')).to include(@form_section_f)
      expect(FormSection.find_mobile_forms_by_parent_form('incident').count).to eq(1)
    end
  end

  describe "get_by_unique_id" do
    it "should retrieve formsection by unique id" do
      expected = FormSection.new
      unique_id = "fred"
      FormSection.stub(:by_unique_id).with(:key=>unique_id).and_return([expected])
      FormSection.get_by_unique_id(unique_id).should == expected
    end

    it "should save fields" do
      section = FormSection.new :name => 'somename', :unique_id => "someform"
      section.save!

      section.fields = [Field.new(:name => "a_field", :type => "text_field", :display_name => "A Field")]
      section.save!

      field = section.fields.first
      field.name = "kev"
      section.save!

      section = FormSection.get_by_unique_id("someform")
      section.name.should == 'somename'
    end

  end

  describe "add_field_to_formsection" do

    it "adds the field to the formsection" do
      field = Field.new_text_field("name")
      formsection = create_formsection :fields => [new_field(), new_field()], :save => true
      FormSection.add_field_to_formsection formsection, field
      formsection.fields.length.should == 3
      formsection.fields[2].should == field
    end

    it "adds base_language to fields in formsection" do
      field = Field.new_textarea("name")
      formsection = create_formsection :fields => [new_field(), new_field()], :save=>true
      FormSection.add_field_to_formsection formsection, field
      formsection.fields[2].should have_key("base_language")
    end

    it "saves the formsection" do
      field = Field.new_text_field("name")
      formsection = create_formsection
      formsection.should_receive(:save)
      FormSection.add_field_to_formsection formsection, field
    end

    it "should raise an error if adding a field to a non editable form section" do
      field = new_field :name=>'field_one'
      formsection = FormSection.new :editable => false
      lambda { FormSection.add_field_to_formsection formsection, field }.should raise_error
    end

  end


  describe "add_textarea_field_to_formsection" do

    it "adds the textarea to the formsection" do
      field = Field.new_textarea("name")
      formsection = create_formsection :fields => [new_field(), new_field()], :save=>true
      FormSection.add_field_to_formsection formsection, field
      formsection.fields.length.should == 3
      formsection.fields[2].should == field
    end

    it "saves the formsection with textarea field" do
      field = Field.new_textarea("name")
      formsection = create_formsection
      formsection.should_receive(:save)
      FormSection.add_field_to_formsection formsection, field
    end

  end

  describe "add_select_drop_down_field_to_formsection" do

    it "adds the select drop down to the formsection" do
      field = Field.new_select_box("name", ["some", ""])
      formsection = create_formsection :fields => [new_field(), new_field()], :save=>true
      FormSection.add_field_to_formsection formsection, field
      formsection.fields.length.should == 3
      formsection.fields[2].should == field
    end

    it "saves the formsection with select drop down field" do
      field = Field.new_select_box("name", ["some", ""])
      formsection = create_formsection
      formsection.should_receive(:save)
      FormSection.add_field_to_formsection formsection, field
    end

  end

  describe "editable" do

    it "should be editable by default" do
      formsection = FormSection.new
      formsection.editable?.should be_true
    end

  end

  describe "perm_visible" do
    it "should not be perm_enabled by default" do
      formsection = FormSection.new
      formsection.perm_visible?.should be_false
    end

    it "should be perm_visible when set" do
      formsection = FormSection.new(:perm_visible => true)
      formsection.perm_visible?.should be_true
    end
  end

  describe "fixed_order" do
    it "should not be fixed)order by default" do
      formsection = FormSection.new
      formsection.fixed_order?.should be_false
    end

    it "should be fixed_order when set" do
      formsection = FormSection.new(:fixed_order => true)
      formsection.fixed_order?.should be_true
    end
  end

  describe "perm_enabled" do
    it "should not be perm_enabled by default" do
      formsection = FormSection.new
      formsection.perm_enabled?.should be_false
    end

    it "should be perm_enabled when set" do
      formsection = FormSection.create!(:name => "test", :uniq_id => "test_id", :perm_enabled => true)
      formsection.perm_enabled?.should be_true
      formsection.perm_visible?.should be_true
      formsection.fixed_order?.should be_true
      formsection.visible?.should be_true
    end
  end

  describe "delete_field" do
    it "should delete editable fields" do
      @field = new_field(:name=>"field3")
      form_section = FormSection.new :fields=>[@field]
      form_section.delete_field(@field.name)
      form_section.fields.should be_empty
    end

    it "should not delete uneditable fields" do
      @field = new_field(:name=>"field3", :editable => false)
      form_section = FormSection.new :fields=>[@field]
      lambda {form_section.delete_field(@field.name)}.should raise_error("Uneditable field cannot be deleted")
    end
  end

  describe "save fields in given order" do
    it "should save the fields in the given field name order" do
      @field_1 = new_field(:name => "orderfield1", :display_name => "orderfield1")
      @field_2 = new_field(:name => "orderfield2", :display_name => "orderfield2")
      @field_3 = new_field(:name => "orderfield3", :display_name => "orderfield3")
      form_section = FormSection.create! :name => "some_name", :fields => [@field_1, @field_2, @field_3]
      form_section.order_fields([@field_2.name, @field_3.name, @field_1.name])
      form_section.fields.should == [@field_2, @field_3, @field_1]
      form_section.fields.first.should == @field_2
      form_section.fields.last.should == @field_1
    end
  end

  describe "new_custom" do
    it "should create a new form section" do
      form_section = FormSection.new_custom({:name => "basic"}, "GBV")
      expect(form_section.unique_id).to eq("gbv_basic")
    end

    #TODO - This needs to be tweaked and added back when the order and group order is fixed
    xit "should set the order to one plus maximum order value" do
      FormSection.stub(:by_order).and_return([FormSection.new(:order=>20), FormSection.new(:order=>10), FormSection.new(:order=>40)])
      new_should_be_called_with :order, 41
      FormSection.new_custom({:name => "basic"})
    end
  end

  describe "valid?" do
    it "should validate name is filled in" do
      form_section = FormSection.new()
      form_section.should_not be_valid
      form_section.errors["name_#{I18n.default_locale}"].should be_present
    end

    it "should not allows empty form names in form base_language " do
     form_section = FormSection.new(:name_en => 'English', :name_zh=>'Chinese')
     I18n.default_locale='zh'
     expect {
       form_section[:name_en]=''
       form_section.save!
     }.to raise_error
    end

    it "should validate name is alpha_num" do
      form_section = FormSection.new(:name=> "r@ndom name!")
      form_section.should_not be_valid
      form_section.errors[:name].should be_present
    end

    it "should not allow name with white spaces only" do
      form_section = FormSection.new(:name=> "     ")
      form_section.should_not be_valid
      form_section.errors[:name].should be_present
    end

    it "should allow arabic names" do
      form_section = FormSection.new(:name=>"العربية")
      form_section.should be_valid
      form_section.errors[:name].should_not be_present
    end

    it "should validate name is unique" do
      same_name = 'Same Name'
      valid_attributes = {:name => same_name, :unique_id => same_name.dehumanize, :description => '', :visible => true, :order => 0}
      FormSection.create! valid_attributes.dup
      form_section = FormSection.new valid_attributes.dup
      form_section.should_not be_valid
      form_section.errors[:name].should be_present
      form_section.errors[:unique_id].should be_present
    end

    it "should not occur error  about the name is not unique  when the name is not filled in" do
      form_section = FormSection.new(:name=>"")
      form_section.should_not be_valid
      form_section.errors[:unique_id].should_not be_present
    end

    it "should not trip the unique name validation on self" do
      form_section = FormSection.new(:name => 'Unique Name', :unique_id => 'unique_name')
      form_section.create!
    end
  end

  describe "highlighted_fields" do
    describe "get highlighted fields" do
      before :each do
        high_attr = [{ :order => "1", :highlighted => true }, { :order => "2", :highlighted => true }, { :order => "10", :highlighted => true }]
        @high_fields = [ Field.new(:name => "h1", :highlight_information => high_attr[0]),
                         Field.new(:name => "h2", :highlight_information => high_attr[1]),
                         Field.new(:name => "h3", :highlight_information => high_attr[2]) ]
        field = Field.new :name => "regular_field"
        form_section1 = FormSection.new( :name => "Highlight Form1", :fields => [@high_fields[0], @high_fields[2], field] )
        form_section2 = FormSection.new( :name => "Highlight Form2", :fields => [@high_fields[1]] )
        FormSection.stub(:all).and_return([form_section1, form_section2])
      end

      it "should get fields that have highlight information" do
        highlighted_fields = FormSection.highlighted_fields
        highlighted_fields.size.should == @high_fields.size
        highlighted_fields.map do |field| field.highlight_information end.should
          include @high_fields.map do |field| field.highlight_information end
      end

      it "should sort the highlighted fields by highlight order" do
        sorted_highlighted_fields = FormSection.sorted_highlighted_fields
        sorted_highlighted_fields.map do |field| field.highlight_information.order end.should ==
          @high_fields.map do |field| field.highlight_information.order end
      end
    end

    describe "highlighted fields" do

      it "should update field as highlighted" do
        attrs = { :field_name => "h1", :form_id => "highlight_form" }
        existing_field = Field.new :name => attrs[:field_name]
        form = FormSection.new(:name => "Some Form",
                               :unique_id => attrs[:form_id],
                               :fields => [existing_field])
        FormSection.stub(:all).and_return([form])
        form.update_field_as_highlighted attrs[:field_name]
        existing_field.highlight_information.order.should == 1
        existing_field.is_highlighted?.should be_true
      end

      it "should increment order of the field to be highlighted" do
        attrs = { :field_name => "existing_field", :form_id => "highlight_form"}
        existing_field = Field.new :name => attrs[:field_name]
        existing_highlighted_field = Field.new :name => "highlighted_field"
        existing_highlighted_field.highlight_with_order 3
        form = FormSection.new(:name => "Some Form",
                               :unique_id => attrs[:form_id],
                               :fields => [existing_field, existing_highlighted_field])
        FormSection.stub(:all).and_return([form])
        form.update_field_as_highlighted attrs[:field_name]
        existing_field.is_highlighted?.should be_true
        existing_field.highlight_information.order.should == 4
      end

      it "should un-highlight a field" do
        existing_highlighted_field = Field.new :name => "highlighted_field"
        existing_highlighted_field.highlight_with_order 1
        form = FormSection.new(:name => "Some Form", :unique_id => "form_id",
                               :fields => [existing_highlighted_field])
        FormSection.stub(:all).and_return([form])
        form.remove_field_as_highlighted existing_highlighted_field.name
        existing_highlighted_field.is_highlighted?.should be_false
      end
    end

    describe "formatted hash" do
      it "should combine the translations into a hash" do
        fs = FormSection.new(:name_en => "english name", :name_fr => "french name", :unique_id => "unique id",
                             :fields => [Field.new(:display_name_en => "dn in english", :display_name_es => "dn in spanish", :name => "name")])
        form_section = fs.formatted_hash
        form_section["name"].should == {"en" => "english name", "fr" => "french name"}
        form_section["unique_id"].should == "unique id"
        form_section["fields"].first["display_name"].should == {"en" => "dn in english", "es" => "dn in spanish"}
        form_section["fields"].first["name"].should == "name"
      end
    end
  end

  describe "Create FormSection Or Add Fields" do

    it "should create the FormSection if it does not exist" do
      form_section = FormSection.create_or_update_form_section(
        {"visible"=>true,
         :order=>11,
         :unique_id=>"tracing",
         :perm_visible => true,
         "editable"=>true,
         "name_all" => "Tracing Name",
         "description_all" => "Tracing Description"
        })
      form_section.new?.should == false
      form_section.fields.length.should == 0
      form_section.visible.should == true
      form_section.order.should == 11
      form_section.perm_visible.should == true
      form_section.editable.should == true
      form_section.name.should == "Tracing Name"
      form_section.description.should == "Tracing Description"
    end

    it "should not update the FormSection because it does exist" do
      #Create a new FormSection should not exists.
      form_section = FormSection.create_or_update_form_section(
        {"visible"=>true,
         :order=>11,
         :unique_id=>"tracing",
         :perm_visible => true,
         "editable"=>true,
         "name_all" => "Tracing Name",
         "description_all" => "Tracing Description"
        })
      form_section.new?.should == false
      form_section.fields.length.should == 0
      form_section.visible.should == true
      form_section.order.should == 11
      form_section.perm_visible.should == true
      form_section.editable.should == true
      form_section.name.should == "Tracing Name"
      form_section.description.should == "Tracing Description"

      #Attempt to create the same FormSection
      #Should not change any property.
      form_section_1 = FormSection.create_or_update_form_section(
        {"visible"=>false,
         :order=>12,
         :unique_id=>"tracing",
         :perm_visible => false,
         "editable"=>false,
         "name_all" => "Tracing Name All",
         "description_all" => "Tracing Description All"
        })
      #Nothing change.
      form_section_1.new?.should == false
      form_section_1.fields.length.should == 0
      form_section_1.visible.should == false
      form_section_1.order.should == 12
      form_section_1.perm_visible.should == false
      form_section_1.editable.should == false
      form_section_1.name.should == "Tracing Name All"
      form_section_1.description.should == "Tracing Description All"
    end

    it "should add fields if does not exist" do
      fields = [
        Field.new({"name" => "date_of_separation",
                   "type" => "date_field",
                   "display_name_all" => "Date of Separation"
                  })
      ]
      #Create a new FormSection should not exists.
      form_section = FormSection.create_or_update_form_section(
        {"visible"=>true,
         :order=>11,
         :unique_id=>"tracing",
          :fields => fields,
         :perm_visible => true,
         "editable"=>true,
         "name_all" => "Tracing Name",
         "description_all" => "Tracing Description"
        })
      form_section.new?.should == false
      form_section.fields.length.should == 1
      form_section.visible.should == true
      form_section.order.should == 11
      form_section.perm_visible.should == true
      form_section.editable.should == true
      form_section.name.should == "Tracing Name"
      form_section.description.should == "Tracing Description"

      fields_1 = [
        Field.new({"name" => "date_of_separation",
                   "type" => "date_field",
                   "display_name_all" => "Date of Separation All"
                  }),
        Field.new({"name" => "separation_cause",
                   "type" => "select_box",
                   "display_name_all" => "What was the main cause of separation?",
                   "option_strings_source" => ["Cause 1", "Cause 2"],
                  })
      ]
      #Attempt to create a new section, no update form section
      #no update the existing field, but add the new field.
      form_section_1 = FormSection.create_or_update_form_section(
        {"visible"=>false,
         :order=>12,
         :unique_id=>"tracing",
          :fields => fields_1,
         :perm_visible => false,
         "editable"=>false,
         "name_all" => "Tracing Name All",
         "description_all" => "Tracing Description All"
        })
      #nothing change
      form_section_1.new?.should == false
      form_section_1.fields.length.should == 2
      form_section_1.visible.should == false
      form_section_1.order.should == 12
      form_section_1.perm_visible.should == false
      form_section_1.editable.should == false
      form_section_1.name.should == "Tracing Name All"
      form_section_1.description.should == "Tracing Description All"

      form_section_1.fields[0].name.should == "date_of_separation"
      form_section_1.fields[0].type.should == "date_field"
      form_section_1.fields[0].display_name.should == "Date of Separation All"

      #Check the new field.
      form_section_1.fields[1].name.should == "separation_cause"
      form_section_1.fields[1].type.should == "select_box"
      form_section_1.fields[1].display_name.should == "What was the main cause of separation?"
    end

    it "should create FormSection" do
      properties = {
        "visible"=>true,
        :order=>11,
        :unique_id=>"tracing",
        :perm_visible => true,
        "editable"=>true,
        "name_all" => "Tracing Name",
        "description_all" => "Tracing Description",
      }
      new_form_section = FormSection.new
      new_form_section.should_not_receive(:save)
      new_form_section.should_not_receive(:attributes)
      FormSection.should_receive(:get_by_unique_id).with("tracing").and_return(nil)
      FormSection.should_receive(:create!).with(properties).and_return(new_form_section)

      form_section = FormSection.create_or_update_form_section(properties)
      form_section.should == new_form_section
    end

    it "should add Field" do
      fields = [
        Field.new({"name" => "date_of_separation",
                   "type" => "text_field",
                   "display_name_all" => "Date of Separation All"
                  }),
        Field.new({"name" => "separation_cause",
                   "type" => "select_box",
                   "display_name_all" => "What was the main cause of separation?",
                   "option_strings_source" => ["Cause 1", "Cause 2"],
                  })
      ]
      properties = {
        "visible"=>false,
        :order=>11,
        :unique_id=>"tracing",
        :fields => fields,
        :perm_visible => false,
        "editable"=>true,
        "name_all" => "Tracing Name",
        "description_all" => "Tracing Description"
      }

      existing_form_section = FormSection.new
      existing_form_section.should_receive(:attributes=).with(properties)
      existing_form_section.should_receive(:save!)
      FormSection.should_receive(:get_by_unique_id).with("tracing").and_return(existing_form_section)

      form_section = FormSection.create_or_update_form_section(properties)
      form_section.should == existing_form_section
    end

  end

  describe "Fields with the same name" do
    before :each do
      FormSection.all.each &:destroy
      subform_fields = [
        Field.new({"name" => "field_name_1",
                   "type" => "text_field",
                   "display_name_all" => "Field name 1"
                  })
      ]
      subform_section = FormSection.new({
          "visible"=>false,
          "is_nested"=>true,
          :order_form_group => 1,
          :order => 1,
          :order_subform => 1,
          :unique_id=>"subform_section_1",
          :parent_form=>"case",
          "editable"=>true,
          :fields => subform_fields,
          :initial_subforms => 1,
          "name_all" => "Nested Subform Section 1",
          "description_all" => "Details Nested Subform Section 1"
      })
      subform_section.save!
  
      fields = [
        Field.new({"name" => "field_name_2",
                   "type" => "text_field",
                   "display_name_all" => "Field Name 2"
                  }),
        Field.new({"name" => "field_name_3",
                   "type" => "subform",
                   "editable" => true,
                   "subform_section_id" => subform_section.unique_id,
                   "display_name_all" => "Subform Section 1"
                  })
      ]
      form = FormSection.new(
        :unique_id => "form_section_test_1",
        :parent_form=>"case",
        "visible" => true,
        :order_form_group => 1,
        :order => 1,
        :order_subform => 0,
        :form_group_name => "Form Section Test",
        "editable" => true,
        "name_all" => "Form Section Test 1",
        "description_all" => "Form Section Test 1",
        :fields => fields
      )
      form.save!
    end

    after :all do
      FormSection.all.each &:destroy
    end

    describe "Create Form Section" do
      it "should not add field with different type" do
        #This field is a text_field in another form.
        fields = [
          Field.new({"name" => "field_name_2",
                     "type" => "textarea",
                     "display_name_all" => "Field Name 2"
                    })
        ]
        form = FormSection.new(
          :unique_id => "form_section_test_2",
          :parent_form=>"case",
          "visible" => true,
          :order_form_group => 1,
          :order => 1,
          :order_subform => 0,
          :form_group_name => "Form Section Test",
          "editable" => true,
          "name_all" => "Form Section Test 2",
          "description_all" => "Form Section Test 2",
          :fields => fields
        )
        form.save

        #Form was not save.
        form.new_record?.should be_true

        #There is other field with the same on other form section
        #so, we can't change the type.
        expect(form.fields.first.errors.messages[:name]).to eq(["Can't change type of existing field on form 'Form Section Test 1'"])
      end

      it "should not add subform with different type" do
        #This field is a subform in another form.
        fields = [
          Field.new({"name" => "field_name_3",
                     "type" => "textarea",
                     "display_name_all" => "Field Name 3"
                    })
        ]
        form = FormSection.new(
          :unique_id => "form_section_test_2",
          :parent_form=>"case",
          "visible" => true,
          :order_form_group => 1,
          :order => 1,
          :order_subform => 0,
          :form_group_name => "Form Section Test",
          "editable" => true,
          "name_all" => "Form Section Test 2",
          "description_all" => "Form Section Test 2",
          :fields => fields
        )
        form.save

        #Form was not save.
        form.new_record?.should be_true

        #There is other field with the same on other form section
        #so, we can't change the type.
        expect(form.fields.first.errors.messages[:name]).to eq(["Can't change type of existing field on form 'Form Section Test 1'"])
      end

      it "should allow fields with the same name on different subforms" do
        #This field exists in a different subforms, but should be possible
        #add with the same name and different type in another subform.
        subform_fields = [
          Field.new({"name" => "field_name_1",
                     "type" => "textarea",
                     "display_name_all" => "Field name 1"
                    })
        ]
        subform_section = FormSection.new({
            "visible"=>false,
            "is_nested"=>true,
            :order_form_group => 1,
            :order => 1,
            :order_subform => 1,
            :unique_id=>"subform_section_2",
            :parent_form=>"case",
            "editable"=>true,
            :fields => subform_fields,
            :initial_subforms => 1,
            "name_all" => "Nested Subform Section 2",
            "description_all" => "Details Nested Subform Section 2"
        })
        subform_section.save

        subform_section.new_record?.should be_false

        expect(subform_section.fields.first.errors.messages[:name]).to eq(nil)
      end
   end

    describe "Edit Form Section" do
      before :each do
        subform_fields = [
          Field.new({"name" => "field_name_5",
                     "type" => "textarea",
                     "display_name_all" => "Field name 5"
                    })
        ]
        @subform_section = FormSection.new({
            "visible"=>false,
            "is_nested"=>true,
            :order_form_group => 1,
            :order => 1,
            :order_subform => 1,
            :unique_id=>"subform_section_3",
            :parent_form=>"case",
            "editable"=>true,
            :fields => subform_fields,
            :initial_subforms => 1,
            "name_all" => "Nested Subform Section 3",
            "description_all" => "Details Nested Subform Section 3"
        })
        @subform_section.save!

        fields = [
          Field.new({"name" => "field_name_4",
                     "type" => "textarea",
                     "display_name_all" => "Field Name 4"
                    })
        ]
        @form = FormSection.new(
          :unique_id => "form_section_test_2",
          :parent_form=>"case",
          "visible" => true,
          :order_form_group => 1,
          :order => 1,
          :order_subform => 0,
          :form_group_name => "Form Section Test",
          "editable" => true,
          "name_all" => "Form Section Test 2",
          "description_all" => "Form Section Test 2",
          :fields => fields
        )
        @form.save!
      end

      it "should not add field with different type" do
        #This field is a text_field in another form.
        @form.fields << Field.new({"name" => "field_name_2",
                                   "type" => "textarea",
                                   "display_name_all" => "Field Name 2"
                                  })
        @form.save.should be_false

        #There is other field with the same on other form section
        #so, we can't change the type.
        expect(@form.fields.last.errors.messages[:name]).to eq(["Can't change type of existing field on form 'Form Section Test 1'"])
      end

      it "should not add subform with different type" do
        #This field is a subform in another form.
        @form.fields << Field.new({"name" => "field_name_3",
                                  "type" => "textarea",
                                  "display_name_all" => "Field Name 3"
                                 })
        @form.save.should be_false

        #There is other field with the same on other form section
        #so, we can't change the type.
        expect(@form.fields.last.errors.messages[:name]).to eq(["Can't change type of existing field on form 'Form Section Test 1'"])
      end

      it "should allow fields with the same name on different subforms" do
        field = @subform_section.fields.first
        #Match the name with this field on different subforms
        field.name = "field_name_1"

        #Save the record and check the status
        @subform_section.save.should be_true

        expect(@subform_section.fields.first.errors.messages[:name]).to eq(nil)
      end
   end

  end

  describe "Finding locations by parent form" do
    before do
      FormSection.all.each &:destroy

      fields = [
          Field.new({"name" => "field_name_1",
                     "type" => "text_field",
                     "display_name_all" => "Field Name 1"
                    }),
          Field.new({"name" => "field_name_2",
                     "type" => "text_field",
                     "display_name_all" => "Field Name 2"
                    })
      ]
      @form_0 = FormSection.create(
          :unique_id => "form_section_no_locations",
          :parent_form=>"case",
          "visible" => true,
          :order_form_group => 1,
          :order => 1,
          :order_subform => 0,
          :form_group_name => "Form Section Test",
          "editable" => true,
          "name_all" => "Form Section No Locations",
          "description_all" => "Form Section No Locations",
          :fields => fields
      )

      fields = [
          Field.new({"name" => "test_location",
                     "type" => "select_box",
                     "display_name_all" => "Test Location 1",
                     "option_strings_source" => "Location"
                    }),
          Field.new({"name" => "field_name_1",
                     "type" => "text_field",
                     "display_name_all" => "Field Name 1"
                    }),
          Field.new({"name" => "field_name_2",
                     "type" => "text_field",
                     "display_name_all" => "Field Name 2"
                    }),
          Field.new({"name" => "test_country",
                     "type" => "select_box",
                     "display_name_all" => "My Test Country",
                     "option_strings_source" => "lookup Country"
                    })
      ]
      @form_1 = FormSection.create(
          :unique_id => "form_section_one_location",
          :parent_form=>"case",
          "visible" => true,
          :order_form_group => 1,
          :order => 1,
          :order_subform => 0,
          :form_group_name => "Form Section Test",
          "editable" => true,
          "name_all" => "Form Section One Location",
          "description_all" => "Form Section One Location",
          :fields => fields
      )

      fields = [
          Field.new({"name" => "test_location_2",
                     "type" => "select_box",
                     "display_name_all" => "Test Location 2",
                     "option_strings_source" => "Location"
                    }),
          Field.new({"name" => "test_location_3",
                     "type" => "select_box",
                     "display_name_all" => "Test Location 3",
                     "option_strings_source" => "Location"
                    }),
          Field.new({"name" => "field_name_1",
                     "type" => "text_field",
                     "display_name_all" => "Field Name 1"
                    }),
          Field.new({"name" => "field_name_2",
                     "type" => "text_field",
                     "display_name_all" => "Field Name 2"
                    }),
          Field.new({"name" => "test_yes_no",
                     "type" => "select_box",
                     "display_name_all" => "My Test Field",
                     "option_strings" => "yes\nno"
                    }),
          Field.new({"name" => "test_country",
                     "type" => "select_box",
                     "display_name_all" => "My Test Country",
                     "option_strings_source" => "lookup Country"
                    })
      ]
      @form_2 = FormSection.create(
          :unique_id => "form_section_two_locations",
          :parent_form=>"tracing_request",
          "visible" => true,
          :order_form_group => 1,
          :order => 1,
          :order_subform => 0,
          :form_group_name => "Form Section Test",
          "editable" => true,
          "name_all" => "Form Section Two Locations",
          "description_all" => "Form Section Two Locations",
          :fields => fields
      )

      fields = [
          Field.new({"name" => "test_location_4",
                     "type" => "select_box",
                     "display_name_all" => "Test Location 4",
                     "option_strings_source" => "Location"
                    }),
          Field.new({"name" => "test_location_5",
                     "type" => "select_box",
                     "display_name_all" => "Test Location 5",
                     "option_strings_source" => "Location"
                    }),
          Field.new({"name" => "field_name_1",
                     "type" => "text_field",
                     "display_name_all" => "Field Name 1"
                    }),
          Field.new({"name" => "field_name_2",
                     "type" => "text_field",
                     "display_name_all" => "Field Name 2"
                    }),
          Field.new({"name" => "test_location_6",
                     "type" => "select_box",
                     "display_name_all" => "Test Location 6",
                     "option_strings_source" => "Location"
                    })
      ]
      @form_3 = FormSection.create(
          :unique_id => "form_section_three_locations",
          :parent_form=>"tracing_request",
          "visible" => true,
          :order_form_group => 1,
          :order => 1,
          :order_subform => 0,
          :form_group_name => "Form Section Test",
          "editable" => true,
          "name_all" => "Form Section Three Locations",
          "description_all" => "Form Section Three Locations",
          :fields => fields
      )

      fields = [
          Field.new({"name" => "test_location_7",
                     "type" => "select_box",
                     "display_name_all" => "Test Location 7",
                     "option_strings_source" => "Location"
                    }),
          Field.new({"name" => "test_location_8",
                     "type" => "select_box",
                     "display_name_all" => "Test Location 8",
                     "option_strings_source" => "Location"
                    }),
          Field.new({"name" => "field_name_1",
                     "type" => "text_field",
                     "display_name_all" => "Field Name 1"
                    }),
          Field.new({"name" => "field_name_2",
                     "type" => "text_field",
                     "display_name_all" => "Field Name 2"
                    }),
          Field.new({"name" => "test_location_9",
                     "type" => "select_box",
                     "display_name_all" => "Test Location 9",
                     "option_strings_source" => "Location"
                    }),
          Field.new({"name" => "test_location_10",
                     "type" => "select_box",
                     "display_name_all" => "Test Location 10",
                     "option_strings_source" => "Location"
                    })
      ]
      @form_4 = FormSection.create(
          :unique_id => "form_section_four_locations",
          :parent_form=>"incident",
          "visible" => true,
          :order_form_group => 1,
          :order => 1,
          :order_subform => 0,
          :form_group_name => "Form Section Test",
          "editable" => true,
          "name_all" => "Form Section Four Locations",
          "description_all" => "Form Section Four Locations",
          :fields => fields
      )
    end

    after :all do
      FormSection.all.each &:destroy
    end

    context "when parent form is not passed in" do
      it "returns the forms for case" do
        expect(FormSection.find_locations_by_parent_form).to match_array [@form_1]
      end
    end

    context "when parent form is case" do
      it "returns the forms" do
        expect(FormSection.find_locations_by_parent_form('case')).to match_array [@form_1]
      end
    end

    context "when parent form is tracing_request" do
      it "returns the forms" do
        expect(FormSection.find_locations_by_parent_form('tracing_request')).to match_array [@form_2, @form_3]
      end
    end

    context "when parent form is incident" do
      it "returns the forms" do
        expect(FormSection.find_locations_by_parent_form('incident')).to match_array [@form_4]
      end
    end

  end

  describe "Violation forms" do
    before do
      FormSection.all.each &:destroy
      @violation = FormSection.create_or_update_form_section({
        unique_id: "sexual_violence",
        name: "sexual_violence",
      })
      fields = [
        Field.new({
          name: "field1",
          display_name_all: 'field1',
          type: "subform",
          subform_section_id: @violation.unique_id
        })
      ]
      @wrapper_form = FormSection.create_or_update_form_section({
        :unique_id => "wrapper",
        :name => "wrapper",
        :fields => fields
      })
      @other_form = FormSection.create_or_update_form_section({
        unique_id: "other_form",
        name: "other_form",
      })
    end

    it "identifies a violation form" do
      expect(@violation.is_violation?).to be_true
      expect(@other_form.is_violation?).to be_false
    end

    it "identifies a violation wrapper" do
      expect(@wrapper_form.is_violation_wrapper?).to be_true
      expect(@other_form.is_violation_wrapper?).to be_false
    end

    after do
      FormSection.all.each &:destroy
    end

  end
end
