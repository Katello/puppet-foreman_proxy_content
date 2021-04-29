class { 'foreman::repo':
  repo => 'nightly',
}

package { 'policycoreutils':
  ensure => installed,
}

if $facts['os']['release']['major'] == '8' {
  package { 'glibc-langpack-en':
    ensure => installed,
  }

  yumrepo { 'powertools':
    enabled => true,
  }

  yumrepo { 'katello':
    baseurl  => "http://yum.theforeman.org/katello/nightly/katello/el8/x86_64/",
    gpgcheck => 0,
  }
} elsif $facts['os']['release']['major'] == '7' {
  package { 'epel-release':
    ensure => installed,
  }
}
