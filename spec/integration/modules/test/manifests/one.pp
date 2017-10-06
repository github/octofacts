class test::one {
  file { "/tmp/system-info.txt":
    ensure  => file,
    owner   => $::id,
    group   => $::gid,
    content => template("test/one/system-info.txt"),
  }

  file { "/etc/hosts":
    content => "127.0.0.1 localhost ${::shorthost}",
  }
}
