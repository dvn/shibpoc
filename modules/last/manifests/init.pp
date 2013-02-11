class last {

  exec { 'mkshibconf':
    command => '/usr/bin/curl -s "https://www.testshib.org/cgi-bin/sp2config.cgi?dist=Others&hostname=$HOSTNAME" > /etc/shibboleth/shibboleth2.xml',
  }

  exec { 'restart_apache':
    command => '/sbin/service httpd restart',
    require => Exec['mkshibconf'],
  }

  exec { 'restart_shibd':
    command => '/sbin/service shibd restart',
    require => Exec['restart_apache'],
  }

}
