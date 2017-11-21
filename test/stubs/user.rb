# frozen_string_literal: true

class User
  attr_reader :id

  def initialize(id)
    @id = id
  end

  def to_global_id
    GlobalID.new("gid://dummy/User/#{id}")
  end

  def to_gid_param
    to_global_id.to_param
  end
end
