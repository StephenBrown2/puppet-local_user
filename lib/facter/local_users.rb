# This custom fact pulls out all active local users from the /etc/shadow file
# and returns the collection as a comma-separated list.

Facter.add(:local_users) do
  setcode do
    users = Array.new
    File.open("/etc/shadow").each do |line|
      next if line.match(/^\s|^#|!|^$/)
      users << line.split(':').first
    end
    users.join(',')
  end
end
