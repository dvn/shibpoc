class packages {

  $shib_packages = [
    'httpd',
    'mod_ssl',
    'shibboleth.x86_64',
  ]

  package { $shib_packages:
    ensure => installed,
  }

}
