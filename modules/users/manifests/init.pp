class users {

#  user { 'iqlogbot':
#    ensure     => 'present',
#    managehome => true,
#  }
#
#  file { '/home/iqlogbot':
#    ensure => 'directory',
#    owner  => 'iqlogbot',
#    group  => 'root',
#    mode   => '0755',
#    require => User['iqlogbot'],
#  }

}
