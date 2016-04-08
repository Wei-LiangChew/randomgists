# This service class is meant to check if the state of a record's associated records
# will change if saved. This is not a perfect (or even completely working)
# implementation, because I have not found a way to only check instances of records
# that are in memory, and avoid querying the database for associated records (which
# would not reveal any changes that are about to be saved)

class CheckAssociatedRecordsChangedService

  def initialize(record)
    @record = record
    @record_class = @record.class
  end

  def changed?(options = {})
    blacklist = options[:except] || []
    whitelist = options[:only] || @record_class.reflect_on_all_associations.map(&:name)
    searchlist = Array(whitelist) - Array(blacklist)

    searchlist.each do |association|
      associated_stuff = @record.send(association)

      if associated_stuff.respond_to?(:each)
        if collection_has_dirty_records?(associated_stuff)
          return true
        end
      else
        if record_dirty?(associated_stuff)
          return true
        end
      end
    end

    false
  end

  private

  def record_dirty?(record)
    return unless record.present?
    record.changed? || record.new_record? || record.marked_for_destruction?
  end

  def collection_has_dirty_records?(collection)
    collection.each do |record|
      return true if record_dirty?(record)
    end

    false
  end

end
