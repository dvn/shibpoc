class shibpoc {

  file { '/etc/httpd/conf.d/shibpoc.iq.harvard.edu.conf':
    source => 'puppet:///modules/shibpoc/etc/httpd/conf.d/shibpoc.iq.harvard.edu.conf',
    backup => 'true',
  }

  file { '/var/www/shibpoc' :
    ensure => directory,
    owner  => 'root',
    mode   => '0755',
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

}
