class Relationship < ActiveRecord::Base
  belongs_to :follower, class_name: "User"
  belongs_to :followed, class_name: "User"
  validates :follower_id, presence: true
  validates :followed_id, presence: true
  after_commit :process_relationship_destroyed, on: :destroy
  after_commit :process_relationship_created, on: :create

  private

  def process_relationship_created
    redis_client = Redis.new
    redis_client.publish('relationship_updates', { action: 'create', followed_id: self.followed_id, follower_id: self.follower_id }.to_json)
    redis_client.quit
  end

  def process_relationship_destroyed
    redis_client = Redis.new
    redis_client.publish('relationship_updates', { action: 'destroy', followed_id: self.followed_id, follower_id: self.follower_id }.to_json)
    redis_client.quit
  end
end
