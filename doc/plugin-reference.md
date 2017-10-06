# Plugin refeerence for octofacts-updater

Please refer to the [octofacts-updater documentation](/doc/octofacts-updater.md) for general instructions to configure the system.

This document is a reference to all available plugins for fact manipulation. All of the distributed plugins are found in the [/lib/octofacts_updater/plugins](/lib/octofacts_updater/plugins) directory.

## delete

Source: [static.rb](/lib/octofacts_updater/plugins/static.rb)

Description: Deletes a fact or component of a structured fact.

Parameters: (None)

Supports structured facts: Yes

Example usage:

```
facts:
  some_fact_to_delete:
    plugin: delete
  some_structured_fact:
    structure:
      - regexp: .+
      - regexp: _key$
    plugin: delete
```

## ipv4_anonymize

Source: [ip.rb](/lib/octofacts_updater/plugins/ip.rb)

Description: Choose a random IP address from the specified IPv4 subnet. The original IP address is used to seed the random number generator, so as long as that IP address does not change, the randomized IP address will remain constant.

Parameters:

| Parameter | Required? | Description |
| --------- | --------- | ----------- |
| `subnet` | Yes | CIDR notation of subnet from which random IP is to be chosen |

Supports structured facts: Yes

Example usage:

```
ipaddress:
  plugin: ipv4_randomize
  subnet: 10.1.0.0/24
```

## ipv6_anonymize

Source: [ip.rb](/lib/octofacts_updater/plugins/ip.rb)

Description: Choose a random IP address from the specified IPv6 subnet. The original IP address is used to seed the random number generator, so as long as that IP address does not change, the randomized IP address will remain constant.

Parameters:

| Parameter | Required? | Description |
| --------- | --------- | ----------- |
| `subnet` | Yes | CIDR notation of subnet from which random IP is to be chosen |

Supports structured facts: Yes

Example usage:

```
ipaddress:
  plugin: ipv6_randomize
  subnet: "fd00::/8"
```

## noop

Source: [static.rb](/lib/octofacts_updater/plugins/static.rb)

Description: Does nothing at all.

Parameters: (None)

Supports structured facts: Yes

Example usage:

```
facts:
  ec2_userdata:
    plugin: noop
```

## randomize_long_string

Source: [static.rb](/lib/octofacts_updater/plugins/static.rb)

Description: Given a string of length N, this generates a random string of length N using the original string to seed the random number generator. This ensures that the random string is consistent between runs of octofacts-updater. It is not possible to use the random string to reconstruct the original string (although for sufficiently short strings, it may be possible to brute-force guess the original string, much like brute-force password cracking).

Parameters: (None)

Supports structured facts: Yes

Example usage:

```
facts:
  some_fact_to_modify:
    plugin: randomize_long_string
  some_structured_fact:
    structure:
      - regexp: .+
      - regexp: _key$
    plugin: randomize_long_string
```

Example result:

```
some_fact_to_modify: randomrandomrandom
some_structured_fact:
  foo:
    ssl_cert: ABCDEF...
    ssl_key: randomrandomrandom
  bar:
    ssl_cert: 012345...
    ssl_key: randomrandomrandom
```

## remove_from_delimited_string

Source: [static.rb](/lib/octofacts_updater/plugins/static.rb)

Description: Given a string that is delimited, remove all elements from that string that match the provided regular expression.

Parameters:

| Parameter | Required? | Description |
| --------- | --------- | ----------- |
| `delimiter`  | Yes | Character that is the delimiter |
| `regexp`  | Yes | Remove all items from the string matching this regexp |

Supports structured facts: Yes

Example usage:

```
facts:
  interfaces:
    plugin: remove_from_delimited_string
    delimiter: ,
    regexp: ^tun\d+
```

Example result:

```
# Before
interfaces: eth0,eth1,bond0,tun0,tun1,tun2,lo

# After
interfaces: eth0,eth1,bond0,lo
```

## set

Source: [static.rb](/lib/octofacts_updater/plugins/static.rb)

Description: Sets the value of a fact or component of a structured fact to a pre-determined value.

Parameters:

| Parameter | Required? | Description |
| --------- | --------- | ----------- |
| `value`   | Yes       | Static value to set |

Supports structured facts: Yes

Example usage:

```
facts:
  some_fact_to_modify:
    plugin: set
    value: new_value_of_fact
  some_structured_fact:
    structure:
      - regexp: .+
      - regexp: _key$
    plugin: set
    value: we_dont_include_keys
```

Example result:

```
some_fact_to_modify: new_value_of_fact
some_structured_fact:
  foo:
    ssl_cert: ABCDEF...
    ssl_key: we_dont_include_keys
  bar:
    ssl_cert: 012345...
    ssl_key: we_dont_include_keys
```

## sshfp_randomize

Source: [ssh.rb](/lib/octofacts_updater/plugins/ssh.rb)

Description: Sets the SSH fingerprint portion of a fact to a random string, while preserving the numeric portion and other structure.

Parameters: (None)

Supports structured facts: Yes

Example usage:

```
facts:
  ssh:
    plugin: sshfp_randomize
    structure:
      - regexp: .*
      - regexp: ^fingerprints$
      - regexp: ^sha\d+
```

Example result:

```
# Before
ssh:
  rsa:
    fingerprints:
      sha1: SSHFP 1 1 abcdefabcdefabcdefabcdefabcdefabcdefabcd
      sha256: SSHFP 1 2 abcdefabcdefabcdefabcdefabcdefabcdefabcdabcdefabcdefabcdefabcdef
    key: AAAA0123456012345601234560123456

# After
ssh:
  rsa:
    fingerprints:
      sha1: SSHFP 1 1 randomrandomrandomrandomrandomrandomrand
      sha256: SSHFP 1 2 randomrandomrandomrandomrandomrandomrandomrandomrandomrandomrand
    key: AAAA0123456012345601234560123456
```
