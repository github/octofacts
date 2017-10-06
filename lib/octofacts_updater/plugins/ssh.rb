# This file is part of the octofacts updater fact manipulation plugins. This plugin provides
# methods to update facts that are SSH keys, since we do not desire to commit SSH keys from
# actual hosts into the source code repository.

# sshfp. This method randomizes the secret key for sshfp formatted keys. Each key is replaced
# by a randomized (yet consistent) string the same length as the input key.
# The input looks like this:
#  sshfp_ecdsa: |-
#    SSHFP 3 1 xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
#    SSHFP 3 2 xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
OctofactsUpdater::Plugin.register(:sshfp_randomize) do |fact, args = {}|
  blk = Proc.new do |val|
    lines = val.split("\n").map(&:strip)
    result = lines.map do |line|
      unless line =~ /\ASSHFP (\d+) (\d+) (\w+)/
        raise "Unparseable pattern: #{line}"
      end
      "SSHFP #{Regexp.last_match(1)} #{Regexp.last_match(2)} #{OctofactsUpdater::Plugin.randomize_long_string(Regexp.last_match(3))}"
    end
    result.join("\n")
  end
  fact.set_value(blk, args["structure"])
end
