class shibpoc {

  file { '/var/www/html/secure' :
    ensure => directory,
    owner  => 'root',
    mode   => '0755',
  }

  file { '/var/www/html/secure/index.html' :
    content => 'Secure area',
    require => File['/var/www/html/secure'],
  }

  file { '/usr/local/dvn/sbin/dvn-puppet-apply':
    source  => 'puppet:///modules/shibpoc/usr/local/dvn/sbin/dvn-puppet-apply',
    mode    => '0755',
    require => File['/usr/local/dvn/sbin'],
  }

  file { '/usr/local/dvn/sbin' :
    ensure  => directory,
    require => File['/usr/local/dvn'],
  }

  file { '/usr/local/dvn' :
    ensure  => directory,
  }

  service { 'httpd':
    ensure    => running,
    enable    => true,
  }

  service { 'shibd':
    ensure    => running,
    enable    => true,
  }

}
