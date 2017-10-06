# This file is part of the octofacts updater fact manipulation plugins. This plugin provides
# methods to update facts that are IP addresses in order to anonymize or randomize them.

require "ipaddr"

# ipv4_anonymize. This method modifies an IP (version 4) address and
# sets it to a randomized (yet consistent) address in the given
# network.
#
# Supported parameters in args:
# - subnet: (Required) The network prefix in CIDR notation
OctofactsUpdater::Plugin.register(:ipv4_anonymize) do |fact, args = {}, facts|
  raise ArgumentError, "ipv4_anonymize requires a subnet" if args["subnet"].nil?

  subnet_range = IPAddr.new(args["subnet"], Socket::AF_INET).to_range
  # Convert the original IP to an integer representation that we can use as seed
  seed = IPAddr.new(fact.value(args["structure"]), Socket::AF_INET).to_i
  srand seed
  random_ip = IPAddr.new(rand(subnet_range.first.to_i..subnet_range.last.to_i), Socket::AF_INET)
  fact.set_value(random_ip.to_s, args["structure"])
end

# ipv6_anonymize. This method modifies an IP (version 6) address and
# sets it to a randomized (yet consistent) address in the given
# network.
#
# Supported parameters in args:
# - subnet: (Required) The network prefix in CIDR notation
OctofactsUpdater::Plugin.register(:ipv6_anonymize) do |fact, args = {}, facts|
  raise ArgumentError, "ipv6_anonymize requires a subnet" if args["subnet"].nil?

  subnet_range = IPAddr.new(args["subnet"], Socket::AF_INET6).to_range
  # Convert the hostname to an integer representation that we can use as seed
  seed = IPAddr.new(fact.value(args["structure"]), Socket::AF_INET6).to_i
  srand seed
  random_ip = IPAddr.new(rand(subnet_range.first.to_i..subnet_range.last.to_i), Socket::AF_INET6)
  fact.set_value(random_ip.to_s, args["structure"])
end
