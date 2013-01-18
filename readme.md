# Shibboleth Proof of Concept

## What is this?

This git repo contains a [Vagrant][] environment for standing up a proof of concept for a Shibboleth Service Provider ([SP][]).

[Vagrant]: http://vagrantup.com
[SP]: http://shibboleth.net/products/service-provider.html

So far, all it does is install the `shibboleth.x86_64` RPM.

See also https://redmine.hmdc.harvard.edu/issues/2657

    murphy:shibpoc pdurbin$ vagrant up
    [default] Importing base box 'centos'...
    [default] The guest additions on this VM do not match the install version of
    VirtualBox! This may cause things such as forwarded ports, shared
    folders, and more to not work properly. If any of those things fail on
    this machine, please update the guest additions and repackage the
    box.

    Guest Additions Version: 4.1.18
    VirtualBox Version: 4.2.4
    [default] Matching MAC address for NAT networking...
    [default] Clearing any previously set forwarded ports...
    [default] Forwarding ports...
    [default] -- 22 => 2222 (adapter 1)
    [default] Creating shared folders metadata...
    [default] Clearing any previously set network interfaces...
    [default] Running any VM customizations...
    [default] Booting VM...
    [default] Waiting for VM to boot. This can take a few minutes.
    [default] VM booted and ready for use!
    [default] Mounting shared folders...
    [default] -- v-root: /vagrant
    [default] -- manifests: /tmp/vagrant-puppet/manifests
    [default] -- v-pp-m0: /tmp/vagrant-puppet/modules-0
    [default] Running provisioner: Vagrant::Provisioners::Puppet...
    [default] Running Puppet with /tmp/vagrant-puppet/manifests/init.pp...
    notice: /Stage[repos]/Repos/File[/etc/yum.repos.d/shibboleth.repo]/ensure: defined content as '{md5}cc1f5e77daa5ad7b23bc87f0a6d716e6'

    notice: /Stage[packages]/Packages/Package[shibboleth.x86_64]/ensure: created
    notice: /Stage[packages]/Packages/Package[httpd]/ensure: created
    notice: /Stage[main]/Shibpoc/File[/usr/local/dvn]/ensure: created

    notice: /Stage[main]/Shibpoc/File[/usr/local/dvn/sbin]/ensure: created

    notice: /Stage[main]/Shibpoc/File[/usr/local/dvn/sbin/dvn-puppet-apply]/ensure: defined content as '{md5}c1bce8e2c5063bb113744ad3f19a3c53'

    notice: /Stage[main]/Shibpoc/File[/var/www/shibpoc]/ensure: created

    notice: /Stage[main]/Shibpoc/File[/etc/httpd/conf.d/shibpoc.iq.harvard.edu.conf]/ensure: defined content as '{md5}a8becae909ce8296ab6b15d03aed0e1d'

    notice: /Stage[last]/Last/Service[httpd]/ensure: ensure changed 'stopped' to 'running'
    notice: /Stage[last]/Last/Service[httpd]: Triggered 'refresh' from 1 events
    notice: Finished catalog run in 76.08 seconds

    murphy:shibpoc pdurbin$ 
