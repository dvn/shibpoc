# Shibboleth Proof of Concept

## What is this?

This git repo contains a [Vagrant][] environment for preparing a proof of concept Shibboleth Service Provider ([SP][]) on CentOS 6 to register with https://testshib.org for some basic testing.

[Vagrant]: http://vagrantup.com
[SP]: http://shibboleth.net/products/service-provider.html

It installs Apache and the `shibboleth.x86_64` RPM from http://download.opensuse.org/repositories/security:/shibboleth/RHEL_6/

Then in configures /etc/shibboleth/shibboleth2.xml and restarts Apache and `shibd` per https://www.testshib.org/configure.html

**You will need to register with TestShib** by following https://www.testshib.org/metadata.html

Then, you can start testing per https://www.testshib.org/test.html 

## See also

See also https://redmine.hmdc.harvard.edu/issues/2657
