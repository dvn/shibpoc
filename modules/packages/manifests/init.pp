class packages {

  $shib_packages = [
    'httpd',
    'mod_ssl',
    'shibboleth.x86_64',
    'java-1.6.0-openjdk-devel',
    'unzip',
    'vim-enhanced',
  ]

  package { $shib_packages:
    ensure => installed,
  }

}
