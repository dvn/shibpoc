class packages {

  $shib_packages = [
    'httpd',
    'shibboleth.x86_64',
  ]

  package { $shib_packages:
    ensure => installed,
  }

}
