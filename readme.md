# Shibboleth Proof of Concept

## What is this?

This git repo contains a [Vagrant][] environment for preparing a proof of concept Shibboleth Service Provider ([SP][]) on CentOS 6 to register with https://testshib.org for some basic testing.

[Vagrant]: http://vagrantup.com
[SP]: http://shibboleth.net/products/service-provider.html

It installs Apache and the `shibboleth.x86_64` RPM from http://download.opensuse.org/repositories/security:/shibboleth/RHEL_6/

Then in configures /etc/shibboleth/shibboleth2.xml and restarts Apache and `shibd` per https://www.testshib.org/configure.html

**You will need to register with TestShib** by following https://www.testshib.org/metadata.html

Then, you can start testing per https://www.testshib.org/test.html 

## Example deployment to dvn-vm2.hmdc.harvard.edu

    [root@dvn-vm2 ~]# git clone https://github.com/dvn/shibpoc
    [root@dvn-vm2 ~]# cd shibpoc
    [root@dvn-vm2 shibpoc]# yum install puppet
    [root@dvn-vm2 shibpoc]# modules/shibpoc/files/usr/local/dvn/sbin/dvn-puppet-apply 
    notice: /File[/etc/yum.repos.d/shibboleth.repo]/ensure: defined content as '{md5}cc1f5e77daa5ad7b23bc87f0a6d716e6'
    notice: /Stage[packages]/Packages/Package[httpd]/ensure: created
    notice: /Stage[packages]/Packages/Package[shibboleth.x86_64]/ensure: created
    notice: /Stage[packages]/Packages/Package[mod_ssl]/ensure: created
    notice: /File[/usr/local/dvn]/ensure: created
    notice: /File[/usr/local/dvn/sbin]/ensure: created
    notice: /File[/usr/local/dvn/sbin/dvn-puppet-apply]/ensure: defined content as '{md5}c1bce8e2c5063bb113744ad3f19a3c53'
    notice: /Stage[main]/Shibpoc/Service[shibd]/ensure: ensure changed 'stopped' to 'running'
    notice: /File[/var/www/html/secure]/ensure: created
    notice: /File[/var/www/html/secure/index.html]/ensure: defined content as '{md5}ff3fbbc974d677773f008e58854d9eba'
    notice: /File[/var/www/html/open]/ensure: created
    notice: /File[/var/www/html/open/index.html]/ensure: defined content as '{md5}1f0bcb77b667e5647bace69eb94a2ee2'
    notice: /Stage[main]/Shibpoc/Service[httpd]/ensure: ensure changed 'stopped' to 'running'
    notice: /Stage[last]/Last/Exec[mkshibconf]/returns: executed successfully
    notice: /Stage[last]/Last/Exec[restart_apache]/returns: executed successfully
    notice: /Stage[last]/Last/Exec[restart_shibd]/returns: executed successfully
    notice: Finished catalog run in 33.92 seconds
    [root@dvn-vm2 shibpoc]# 

From a client machine, we download the metadata...

    [pdurbin@tabby tmp]$ curl -s -k https://dvn-vm2.hmdc.harvard.edu/Shibboleth.sso/Metadata > dvn-vm2.hmdc.harvard.edu

... and then upload is via https://www.testshib.org/metadata.html

https://dvn-vm2.hmdc.harvard.edu/open/ should say "Wide open area"

https://dvn-vm2.hmdc.harvard.edu/secure/ should redirect you to https://idp.testshib.org/idp/Authn/UserPassword where you can log in with a username and password of "myself" and which point your browser should take you back to https://dvn-vm2.hmdc.harvard.edu/secure/ where you'll see the text "Secure area" (which is the contents of `/var/www/html/secure/index.html`). 

## See also

- http://shibboleth.net/pipermail/users/2013-February/008056.html
- https://redmine.hmdc.harvard.edu/issues/2657
