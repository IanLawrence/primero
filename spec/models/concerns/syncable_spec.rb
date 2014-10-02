require 'spec_helper'

_Child = Class.new(CouchRest::Model::Base) do
  def self.to_s
    'Child'
  end

  use_database :child
  include Syncable

  property :name, String
  property :age, Fixnum
  property :survivor_code, String
  property :gender, String
  property :family_members, [Class.new do
    include CouchRest::Model::Embeddable

    property :unique_id, String
    property :name, String
    property :relation, String
  end]
  property :languages, [String]
  property :birth_day, Date

  property :violations, Class.new do
    include CouchRest::Model::Embeddable
    property :killing, [Class.new do
      include CouchRest::Model::Embeddable
      property :unique_id, String
      property :date, Date
      property :notes, String
    end]

    property :maiming, [Class.new do
      include CouchRest::Model::Embeddable
      property :unique_id, String
      property :date, Date
      property :notes, String
    end]
  end
end

describe Syncable do
  describe "attribute set" do
    before :each do
      @child = _Child.new()
      @child.save!
      @child.attributes = {
        'name' => 'Fred',
        'family_members' => [
          { 'unique_id' => 'aaaa', 'name' => 'Carl', 'relation' => 'father', },
          { 'unique_id' => 'bbbb', 'name' => 'Martha', 'relation' => 'mother', },
        ],
        'languages' => ['Chinese'],
      }
      @child.save!
    end

    it "should delete missing nested elements" do
      proposed_props = {
        'name' => 'Fred',
        'family_members' => [
          { 'unique_id' => 'aaaa', 'name' => 'Carl', 'relation' => 'uncle' },
        ],
      }
      @child.attributes = proposed_props

      @child.family_members.length.should == 1
    end

    it "should ignore missing nested elements if unique id is present" do
      proposed_props = {
        'family_members' => [
          { 'unique_id' => 'aaaa', },
          { 'unique_id' => 'bbbb', 'name' => 'Mary', 'relation' => 'mother' },
        ],
      }
      @child.attributes = proposed_props

      @child.family_members[0].name.should == 'Carl'
    end

    it "doesn't blow up if unique_id is missing" do
      proposed_props = {
        'family_members' => [
          { 'name' => 'Mary', 'relation' => 'mother' },
        ],
      }
      @child.attributes = proposed_props

      @child.family_members[0].name.should == 'Mary'
    end

    it "should handle nested hashes of arrays" do
      @child.attributes = {
        'violations' => {
          'killing' => [
            {'unique_id' => 'aaaa', 'date' => nil, 'notes' => 'test'}
          ],
        }
      }

      @child.violations.killing[0].notes.should == 'test'
    end
  end

  describe "set attribute with conflicts" do
    before :each do
      @child = _Child.new()
      @child.save!
      @child.attributes = {
        'name' => 'Fred',
        'family_members' => [
          { 'unique_id' => 'aaaa', 'name' => 'Carl', 'relation' => 'father', },
          { 'unique_id' => 'bbbb', 'name' => 'Mary', 'relation' => 'mother', },
        ],
        'languages' => ['Chinese'],
        'violations' => {
          'killing' => [
            { 'unique_id' => '1234', 'date' => nil, 'notes' => 'kill1' },
            { 'unique_id' => '9876', 'date' => nil, 'notes' => 'kill2' },
          ],
        },
      }
      @child.save!

      @first_revision = @child.rev

      @child.age = 12
      @child.family_members[1] = @child.family_members[1].clone.tap do |fm|
        fm.name = 'Martha'
      end
      @child.family_members << { 'unique_id' => 'cccc', 'name' => 'Larry', 'relation' => 'uncle' }

      @child.save!
    end

    it "should ignore only nested properties that were updated before" do
      proposed_props = {
        'name' => 'Fred',
        'family_members' => [
          { 'unique_id' => 'bbbb', 'name' => 'Mary', 'relation' => 'mother' },
          { 'unique_id' => 'aaaa', 'name' => 'Carl', 'relation' => 'uncle' },
        ],
        'revision' => @first_revision
      }
      @child.attributes = proposed_props

      @child.family_members[0].name.should == 'Martha'
      @child.family_members[1].relation.should == 'uncle'
    end

    it "should not consider a separate update as stale" do
      @child.attributes = {
        'age' => 14,
        'revision' => @first_revision,
      }

      @child.age.should == 14
    end

    it "should handle additions to nested arrays" do
      @child.attributes = {
        'family_members' => [
          { 'unique_id' => 'aaaa', 'name' => 'Carl', 'relation' => 'father', },
          { 'unique_id' => 'bbbb', 'name' => 'Mary', 'relation' => 'mother', },
          { 'unique_id' => 'dddd', 'name' => 'Loretta', 'relation' => 'aunt', },
        ],
      }

      @child.family_members.length.should == 3
    end

    it "should handle normal arrays without unique_id" do
      proposed_props = {
        'languages' => ['English', 'Chinese'],
        'revision' => @first_revision,
      }
      @child.attributes = proposed_props

      @child.languages.should == ['English', 'Chinese']
    end

    it "should handle nested hashes of arrays" do
      original_kill = @child.violations.killing[0].clone

      @child.violations = @child.violations.clone.tap do |v|
        v.killing = v.killing.clone.tap do |ks|
          ks[0] = ks[0].clone.tap do |k|
            k.notes = 'kill changed'
          end
        end
      end
      @child.save!

      @child.attributes = {
        'violations' => {
          'killing' => [
            original_kill.to_hash,
          ],
        },
        'revision' => @first_revision,
      }

      @child.violations.killing[0].notes.should == 'kill changed'
    end
  end

  describe 'replication conflict resolution' do
    before :each do
      @child = _Child.new({
        :name => 'Test123',
        :created_by => 'me',
        :family_members => [
          {:unique_id => 'f1', :name => 'Arthur', :relation => 'brother'},
        ]
      })
      @child.save

      now = Time.now

      @saved_first = @timestamp_earliest = _Child.get(@child._id).tap do |c|
        c.attributes = {
          :survivor_code => '200',
          :gender => 'male',
          :last_updated_at => now + 5,
          :last_updated_by => 'me',
          :family_members => [
            {:unique_id => 'f1', :name => 'Arthur', :relation => 'father'},
          ],
        }
      end

      @saved_last = @timestamp_latest = _Child.get(@child._id).tap do |c|
        c.attributes = {
          :survivor_code => '123',
          :name => 'Jorge',
          :age => 18,
          :last_updated_at => now + 10,
          :last_updated_by => 'me',
          :family_members => [
            {:unique_id => 'f1', :name => 'Lawrence', :relation => 'brother'},
            {:unique_id => 'f2', :name => 'Anna', :relation => 'mother'},
          ],
        }
        c.update_history
      end

      @saved_first.save
      _Child.database.bulk_save([@saved_last], true, true)
    end

    it 'should select the latest update in a conflict on the same field' do
      @child.reload.resolve_conflicting_revisions

      resolved = _Child.get(@child._id)
      resolved[:survivor_code].should == @timestamp_latest[:survivor_code]
    end

    it 'should merge updates where updates are to a disjoin set of fields' do
      @child.reload.resolve_conflicting_revisions

      resolved = _Child.get(@child._id)
      resolved[:age].should == @saved_last[:age]
      resolved[:gender].should == @saved_first[:gender]
    end

    xit "should merge nested fields" do
      @child.reload.resolve_conflicting_revisions

      resolved = _Child.get(@child._id)
      resolved[:family_members].length.should == 2
    end

    it "should update existing nested fields" do
      @child.reload.resolve_conflicting_revisions

      resolved = _Child.get(@child._id)
      resolved[:family_members][0].name.should == 'Lawrence'
      resolved[:family_members][0].relation.should == 'father'
    end
  end
end