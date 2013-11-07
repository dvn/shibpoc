# Shibboleth SP Proof of Concept

In this demo app we show how to print some attributes from the TestShib IdP at http://testshib.org from a Java servlet using Shibboleth SP.

https://wiki.shibboleth.net/confluence/display/SHIB2/NativeSPJavaInstall describes the plan:

> In the setup described here, requests from browsers are intercepted first by Apache httpd. The Shibboleth SP then checks these requests to enforce authentication requirements. After an assertion is received and a Shibboleth session is established, the SP or Apache httpd can enforce access control rules, or it can just pass attributes to the application. The request is then forwarded to the servlet through the use of the AJP13 protocol.

In the example below, we use CentOS 6 and Glassfish 3.

## Configure Apache httpd 

We use ProxyPass to reverse proxy our Glassfish application using AJP. When users click "shib.jsp" AuthType shibboleth will be used.

    [root@dvn-vm2 ~]# cat /etc/httpd/conf.d/shibsppoc.conf 
    ProxyPass /shibsppoc ajp://localhost:8009/shibsppoc

    <Location /shibsppoc/shib.jsp>
      AuthType shibboleth
      ShibRequestSetting requireSession 1
      require valid-user
    </Location>
    [root@dvn-vm2 ~]# 

## Enable attributePrefix="AJP_" in Shibboleth SP config

Please note: `/etc/shibboleth/shibboleth2.xml` was already previously set up to work with the TestShib Idp as described at https://github.com/dvn/shibpoc

Change

`<ApplicationDefaults entityID="https://dvn-vm2.hmdc.harvard.edu/shibboleth" REMOTE_USER="eppn">`

to

`<ApplicationDefaults entityID="https://dvn-vm2.hmdc.harvard.edu/shibboleth" REMOTE_USER="eppn" attributePrefix="AJP_">`

in `/etc/shibboleth/shibboleth2.xml` and restart `shibd`.

## Enable mod_proxy_ajp in Glassfish

`asadmin create-network-listener --protocol http-listener-1 --listenerport 8009 --jkenabled true jk-connector`

See also http://docs.oracle.com/cd/E26576_01/doc.312/e24928/webapps.htm#CIHJDAJD

## Deploy the war file

`asadmin deploy /tmp/shibsppoc.war`

## Show the attributes

Visit https://dvn-vm2.hmdc.harvard.edu/shibsppoc and click the link to show attributes.

If you see "Error Message: No peer endpoint available to which to send SAML response" you will probably also see "A valid session was not found." at https://dvn-vm2.hmdc.harvard.edu/Shibboleth.sso/Session

For now the work around is to visit https://dvn-vm2.hmdc.harvard.edu/secure/ which will populate https://dvn-vm2.hmdc.harvard.edu/Shibboleth.sso/Session with a valid session. Then you should be able to click the link from https://dvn-vm2.hmdc.harvard.edu/shibsppoc to display the attributes.

Now you should see something like this:

---

Attributes from https://idp.testshib.org/idp/shibboleth

Shib-Identity-Provider: https://idp.testshib.org/idp/shibboleth

eppn: myself@testshib.org

affiliation: Member@testshib.org;Staff@testshib.org

unscoped-affiliation: Member;Staff

entitlement: urn:mace:dir:entitlement:common-lib-terms

persistent-id: https://idp.testshib.org/idp/shibboleth!https://dvn-vm2.hmdc.harvard.edu/shibboleth!r6xcY8nP2sLOi+ugf8GLtz3wQws=

---
