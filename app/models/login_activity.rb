class LoginActivity < CouchRest::Model::Base
  use_database :login_activity

  design do
    view :by_user_name_and_login_timestamp,
         :map => "function(doc) {
                 if (doc['couchrest-type'] == 'LoginActivity') {
                   emit([doc.user_name, doc.login_timestamp], null);
                 }
              }"

    view :loggined_by_past_two_weeks,
         :map => "function(doc) {
                 if (doc['couchrest-type'] == 'LoginActivity') {
                   var twoWeeksAgo = 1000/*ms*/ * 60/*s*/ * 60/*m*/ * 24/*h*/ * 14/*d*/
                   var nowDate = new Date();
                   nowDate.setHours(0, 0, 0, 0);
                   var twoWeeksAgoTimestamp = new Date(nowDate - twoWeeksAgo);
                   var docTimestamp = new Date(doc['login_timestamp']);
                   if (docTimestamp >= twoWeeksAgoTimestamp) {
                     emit(doc['user_name'], null);
                   }
                }
              }",
				:reduce => "function(key, values, rereduce) {
					if (rereduce) {
						return sum(values);
					}
					return values.length
				}"
  end
  
  property :imei
  property :user_name
  property :login_timestamp, DateTime
  property :mobile_number

  include PrimeroModel
  include Primero::CouchRestRailsBackward

  before_save :set_timestamp

  def set_timestamp
    self.login_timestamp = DateTime.now
  end

  def mobile?
    self.imei.present?
  end
end
