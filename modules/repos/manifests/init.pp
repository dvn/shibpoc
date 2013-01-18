class repos {

  file { '/etc/yum.repos.d/shibboleth.repo' :
    source  => 'puppet:///modules/shibpoc/etc/yum.repos.d/shibboleth.repo',
  }

}
