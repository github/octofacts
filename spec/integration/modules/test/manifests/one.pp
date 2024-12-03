class test::one {
  file { '/tmp/system-info.txt':
    ensure  => file,
    owner   => $facts['identity']['user'],
    group   => $facts['identity']['group'],
    content => template('test/one/system-info.txt'),
  }

  file { '/etc/hosts':
    content => "127.0.0.1 localhost ${facts['networking']['hostname']}",
  }
}
