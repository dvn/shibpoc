class last {

  service { 'httpd':
    ensure    => running,
    enable    => true,
    subscribe => [
      File['/etc/httpd/conf.d/shibpoc.iq.harvard.edu.conf'],
    ]
  }

}
