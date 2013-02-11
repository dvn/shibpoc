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

  file { '/var/www/html/open' :
    ensure => directory,
    owner  => 'root',
    mode   => '0755',
  }

  file { '/var/www/html/open/index.html' :
    content => 'Wide open area',
    require => File['/var/www/html/open'],
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

  file { '/etc/sysconfig/iptables':
    source => 'puppet:///modules/shibpoc/etc/sysconfig/iptables',
    owner  => 'root',
    group  => 'root',
    mode   => '0600',
  }

  service { 'iptables':
    ensure    => running,
    enable    => true,
    subscribe => File['/etc/sysconfig/iptables'],
  }

}
