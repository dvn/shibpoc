# Shibboleth Proof of Concept

## What is this?

This git repo contains a [Vagrant][] environment for preparing a proof of concept Shibboleth Service Provider ([SP][]) on CentOS 6 to register with https://testshib.org for some basic testing.

[Vagrant]: http://vagrantup.com
[SP]: http://shibboleth.net/products/service-provider.html

It installs Apache and the `shibboleth.x86_64` RPM from http://download.opensuse.org/repositories/security:/shibboleth/RHEL_6/

Then it configures `/etc/shibboleth/shibboleth2.xml` and restarts Apache and `shibd` per http://testshib.org/configure.html

**You will need to register with TestShib** by following http://testshib.org/register.html

Then, you can start testing per http://testshib.org/test.html

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

... and then upload is via http://testshib.org/register.html

https://dvn-vm2.hmdc.harvard.edu/open/ should say "Wide open area"

https://dvn-vm2.hmdc.harvard.edu/secure/ should redirect you to https://idp.testshib.org/idp/Authn/UserPassword where you can log in with a username and password of "myself" and which point your browser should take you back to https://dvn-vm2.hmdc.harvard.edu/secure/ where you'll see the text "Secure area" (which is the contents of `/var/www/html/secure/index.html`). 

Now, you might be wondering what makes that https://dvn-vm2.hmdc.harvard.edu/secure/ URL special... why Shibboleth is involved in that URL but not https://dvn-vm2.hmdc.harvard.edu/open/

The answer is in `/etc/httpd/conf.d/shib.conf`:

    [root@dvn-vm2 ~]# tail -5 /etc/httpd/conf.d/shib.conf 
    <Location /secure>
      AuthType shibboleth
      ShibRequestSetting requireSession 1
      require valid-user
    </Location>

## HTTP headers from login test

Below are the HTTP headers from gaining access to https://dvn-vm2.hmdc.harvard.edu/secure/ as described above.

In short, there is a chain of redirection...

- https://dvn-vm2.hmdc.harvard.edu/secure/ 
- https://idp.testshib.org/idp/profile/SAML2/Redirect/SSO?SAMLRequest...(snip)
- https://idp.testshib.org:443/idp/AuthnEngine
- https://idp.testshib.org:443/idp/Authn/UserPassword

... and at this point you login in with myself/myself. Then the HTTP transaction completes with:

- https://idp.testshib.org:443/idp/profile/SAML2/Redirect/SSO
- https://dvn-vm2.hmdc.harvard.edu/Shibboleth.sso/SAML2/POST
- https://dvn-vm2.hmdc.harvard.edu/secure/

Here are the complete headers:

    https://dvn-vm2.hmdc.harvard.edu/secure/
    GET /secure/ HTTP/1.1
    Host: dvn-vm2.hmdc.harvard.edu
    User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:17.0) Gecko/20100101 Firefox/17.0
    Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8
    Accept-Language: en-US,en;q=0.5
    Accept-Encoding: gzip, deflate
    Connection: keep-alive
    HTTP/1.1 302 Found
    Date: Mon, 11 Feb 2013 20:47:15 GMT
    Server: Apache/2.2.15 (CentOS)
    Expires: Wed, 01 Jan 1997 12:00:00 GMT
    Cache-Control: private,no-store,no-cache,max-age=0
    Location: https://idp.testshib.org/idp/profile/SAML2/Redirect/SSO?SAMLRequest=hZJBU8IwEIX%2FSid3mqYISIYyU%2BEgMygdih68OCFZaGbapGZT1H9voah4wWt233v7vskERVXWPG18Ydbw1gD64KMqDfLTICGNM9wK1MiNqAC5lzxPH5Y8DiNeO%2ButtCUJUkRwXlszswabClwO7qAlPK2XCSm8r5FTqg6md6jisKiUDAvhDsKpEFRD80Jvt7YEX4SIlh79Y5qt8g0J5u1B2oij9a%2BRVnXo2wG2utC6%2FfGBtsfsdAln9RqUdiA9zfMVCRbzhLxGKmaD8UDcyl00FGwMajhkuzjqj5Rkgsl2DbGBhUEvjE9IHLF%2BL4p7jG3iiN%2BMOBu8kCA7d77TRmmzvw5o2y0hv99ssl7X6Bkcntq0C2Q6OWLmp2B3Af66rfimTab%2FssUfthN6kdUF1%2FyxNV%2FMM1tq%2BRmkZWnfZw6Eh4QwQqed5O%2F3mH4B&RelayState=ss%3Amem%3Adb7acd8e62db6649a0ead2287c34e2987ef6323993bd08c171fe2083968ad529
    Content-Length: 898
    Connection: close
    Content-Type: text/html; charset=iso-8859-1
    ----------------------------------------------------------
    http://ocsp.incommon.org/
    POST / HTTP/1.1
    Host: ocsp.incommon.org
    User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:17.0) Gecko/20100101 Firefox/17.0
    Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8
    Accept-Language: en-US,en;q=0.5
    Accept-Encoding: gzip, deflate
    Connection: keep-alive
    Content-Length: 115
    Content-Type: application/ocsp-request
    Cookie: __utma=66252406.1399693357.1357769572.1357769572.1357773346.2; __utmz=66252406.1357773346.2.2.utmcsr=google|utmccn=(organic)|utmcmd=organic|utmctr=(not%20provided)
    0q0o0M0K0I0	
    HTTP/1.1 200 OK
    Date: Mon, 11 Feb 2013 20:49:02 GMT
    Server: Apache
    Last-Modified: Mon, 11 Feb 2013 15:03:11 GMT
    Expires: Fri, 15 Feb 2013 15:03:11 GMT
    Etag: D7B1A69BF20B3942C7E6E0092942186140F8C7CE
    Cache-Control: max-age=324248,public,no-transform,must-revalidate
    Content-Length: 471
    Connection: close
    Content-Type: application/ocsp-response
    ----------------------------------------------------------
    http://ocsp.usertrust.com/
    POST / HTTP/1.1
    Host: ocsp.usertrust.com
    User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:17.0) Gecko/20100101 Firefox/17.0
    Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8
    Accept-Language: en-US,en;q=0.5
    Accept-Encoding: gzip, deflate
    Connection: keep-alive
    Content-Length: 115
    Content-Type: application/ocsp-request
    0q0o0M0K0I0	
    HTTP/1.1 200 OK
    Date: Mon, 11 Feb 2013 20:49:02 GMT
    Server: Apache
    Last-Modified: Mon, 11 Feb 2013 18:37:14 GMT
    Expires: Fri, 15 Feb 2013 18:37:14 GMT
    Etag: 19AC877B9D0B51CE0DC73EF2FB858D1FD8B427AC
    Cache-Control: max-age=337091,public,no-transform,must-revalidate
    Content-Length: 471
    Connection: close
    Content-Type: application/ocsp-response
    ----------------------------------------------------------
    https://idp.testshib.org/idp/profile/SAML2/Redirect/SSO?SAMLRequest=hZJBU8IwEIX%2FSid3mqYISIYyU%2BEgMygdih68OCFZaGbapGZT1H9voah4wWt233v7vskERVXWPG18Ydbw1gD64KMqDfLTICGNM9wK1MiNqAC5lzxPH5Y8DiNeO%2ButtCUJUkRwXlszswabClwO7qAlPK2XCSm8r5FTqg6md6jisKiUDAvhDsKpEFRD80Jvt7YEX4SIlh79Y5qt8g0J5u1B2oij9a%2BRVnXo2wG2utC6%2FfGBtsfsdAln9RqUdiA9zfMVCRbzhLxGKmaD8UDcyl00FGwMajhkuzjqj5Rkgsl2DbGBhUEvjE9IHLF%2BL4p7jG3iiN%2BMOBu8kCA7d77TRmmzvw5o2y0hv99ssl7X6Bkcntq0C2Q6OWLmp2B3Af66rfimTab%2FssUfthN6kdUF1%2FyxNV%2FMM1tq%2BRmkZWnfZw6Eh4QwQqed5O%2F3mH4B&RelayState=ss%3Amem%3Adb7acd8e62db6649a0ead2287c34e2987ef6323993bd08c171fe2083968ad529
    GET /idp/profile/SAML2/Redirect/SSO?SAMLRequest=hZJBU8IwEIX%2FSid3mqYISIYyU%2BEgMygdih68OCFZaGbapGZT1H9voah4wWt233v7vskERVXWPG18Ydbw1gD64KMqDfLTICGNM9wK1MiNqAC5lzxPH5Y8DiNeO%2ButtCUJUkRwXlszswabClwO7qAlPK2XCSm8r5FTqg6md6jisKiUDAvhDsKpEFRD80Jvt7YEX4SIlh79Y5qt8g0J5u1B2oij9a%2BRVnXo2wG2utC6%2FfGBtsfsdAln9RqUdiA9zfMVCRbzhLxGKmaD8UDcyl00FGwMajhkuzjqj5Rkgsl2DbGBhUEvjE9IHLF%2BL4p7jG3iiN%2BMOBu8kCA7d77TRmmzvw5o2y0hv99ssl7X6Bkcntq0C2Q6OWLmp2B3Af66rfimTab%2FssUfthN6kdUF1%2FyxNV%2FMM1tq%2BRmkZWnfZw6Eh4QwQqed5O%2F3mH4B&RelayState=ss%3Amem%3Adb7acd8e62db6649a0ead2287c34e2987ef6323993bd08c171fe2083968ad529 HTTP/1.1
    Host: idp.testshib.org
    User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:17.0) Gecko/20100101 Firefox/17.0
    Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8
    Accept-Language: en-US,en;q=0.5
    Accept-Encoding: gzip, deflate
    Connection: keep-alive
    Cookie: JSESSIONID=24AA89FAB41B6E5ED3C2AB27C7C3D9ED; _idp_authn_lc_key=460a01c0-ccb0-4c3b-9894-878e03f5ed32
    HTTP/1.1 302 Moved Temporarily
    Date: Mon, 11 Feb 2013 20:49:01 GMT
    Expires: 0
    Cache-Control: no-cache, no-store, must-revalidate, max-age=0
    Pragma: no-cache
    Set-Cookie: _idp_authn_lc_key=460a01c0-ccb0-4c3b-9894-878e03f5ed32; Version=1; Max-Age=0; Expires=Thu, 01-Jan-1970 00:00:10 GMT; Path=/idp
    Set-Cookie: _idp_authn_lc_key=2d735741-ebc5-4cc6-a952-70d7af52a10f; Version=1; Path=/idp; Secure
    Location: https://idp.testshib.org:443/idp/AuthnEngine
    Content-Length: 0
    Connection: close
    Content-Type: text/plain; charset=UTF-8
    ----------------------------------------------------------
    https://idp.testshib.org/idp/AuthnEngine
    GET /idp/AuthnEngine HTTP/1.1
    Host: idp.testshib.org
    User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:17.0) Gecko/20100101 Firefox/17.0
    Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8
    Accept-Language: en-US,en;q=0.5
    Accept-Encoding: gzip, deflate
    Connection: keep-alive
    Cookie: JSESSIONID=24AA89FAB41B6E5ED3C2AB27C7C3D9ED; _idp_authn_lc_key=2d735741-ebc5-4cc6-a952-70d7af52a10f
    HTTP/1.1 302 Moved Temporarily
    Date: Mon, 11 Feb 2013 20:49:02 GMT
    Expires: 0
    Cache-Control: no-cache, no-store, must-revalidate, max-age=0
    Pragma: no-cache
    Location: https://idp.testshib.org:443/idp/Authn/UserPassword
    Content-Length: 0
    Connection: close
    Content-Type: text/plain; charset=UTF-8
    ----------------------------------------------------------
    https://idp.testshib.org/idp/Authn/UserPassword
    GET /idp/Authn/UserPassword HTTP/1.1
    Host: idp.testshib.org
    User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:17.0) Gecko/20100101 Firefox/17.0
    Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8
    Accept-Language: en-US,en;q=0.5
    Accept-Encoding: gzip, deflate
    Connection: keep-alive
    Cookie: JSESSIONID=24AA89FAB41B6E5ED3C2AB27C7C3D9ED; _idp_authn_lc_key=2d735741-ebc5-4cc6-a952-70d7af52a10f
    HTTP/1.1 200 OK
    Date: Mon, 11 Feb 2013 20:49:02 GMT
    Expires: 0
    Cache-Control: no-cache, no-store, must-revalidate, max-age=0
    Pragma: no-cache
    Content-Type: text/html; charset=UTF-8
    Content-Length: 1589
    Connection: close
    ----------------------------------------------------------
    https://idp.testshib.org/idp/styles.css
    GET /idp/styles.css HTTP/1.1
    Host: idp.testshib.org
    User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:17.0) Gecko/20100101 Firefox/17.0
    Accept: text/css,*/*;q=0.1
    Accept-Language: en-US,en;q=0.5
    Accept-Encoding: gzip, deflate
    Connection: keep-alive
    Referer: https://idp.testshib.org/idp/Authn/UserPassword
    Cookie: JSESSIONID=24AA89FAB41B6E5ED3C2AB27C7C3D9ED; _idp_authn_lc_key=2d735741-ebc5-4cc6-a952-70d7af52a10f
    HTTP/1.1 404 Not Found
    Date: Mon, 11 Feb 2013 20:49:02 GMT
    Expires: 0
    Cache-Control: no-cache, no-store, must-revalidate, max-age=0
    Pragma: no-cache
    Content-Type: text/html; charset=UTF-8
    Connection: close
    Transfer-Encoding: chunked
    ----------------------------------------------------------
    https://idp.testshib.org/idp/images/logo.jpg
    GET /idp/images/logo.jpg HTTP/1.1
    Host: idp.testshib.org
    User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:17.0) Gecko/20100101 Firefox/17.0
    Accept: image/png,image/*;q=0.8,*/*;q=0.5
    Accept-Language: en-US,en;q=0.5
    Accept-Encoding: gzip, deflate
    Connection: keep-alive
    Referer: https://idp.testshib.org/idp/Authn/UserPassword
    Cookie: JSESSIONID=24AA89FAB41B6E5ED3C2AB27C7C3D9ED; _idp_authn_lc_key=2d735741-ebc5-4cc6-a952-70d7af52a10f
    HTTP/1.1 200 OK
    Date: Mon, 11 Feb 2013 20:49:02 GMT
    Expires: 0
    Cache-Control: no-cache, no-store, must-revalidate, max-age=0
    Pragma: no-cache
    Accept-Ranges: bytes
    Etag: W/"4841-1341783056000"
    Last-Modified: Sun, 08 Jul 2012 21:30:56 GMT
    Content-Type: image/jpeg
    Content-Length: 4841
    Connection: close
    ----------------------------------------------------------
    https://idp.testshib.org/idp/Authn/UserPassword
    POST /idp/Authn/UserPassword HTTP/1.1
    Host: idp.testshib.org
    User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:17.0) Gecko/20100101 Firefox/17.0
    Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8
    Accept-Language: en-US,en;q=0.5
    Accept-Encoding: gzip, deflate
    Connection: keep-alive
    Referer: https://idp.testshib.org/idp/Authn/UserPassword
    Cookie: JSESSIONID=24AA89FAB41B6E5ED3C2AB27C7C3D9ED; _idp_authn_lc_key=2d735741-ebc5-4cc6-a952-70d7af52a10f
    Content-Type: application/x-www-form-urlencoded
    Content-Length: 35
    j_username=myself&j_password=myself
    HTTP/1.1 302 Moved Temporarily
    Date: Mon, 11 Feb 2013 20:49:26 GMT
    Expires: 0
    Cache-Control: no-cache, no-store, must-revalidate, max-age=0
    Pragma: no-cache
    Set-Cookie: _idp_session=OTguMjI5LjEwOS4xMzk%3D%7CNWNlMzYzYjg5MGZjNjhjZDFhMGFlOTg4YjQ1Y2I1YmU3YjFkMmVkYWViYzM1NDM4YTA2YTgwMzA0OTc1NGRmMg%3D%3D%7CCEW23DEYJY16AOz99TVa0UwEhyQ%3D; Version=1; Path=/idp; Secure
    Location: https://idp.testshib.org:443/idp/profile/SAML2/Redirect/SSO
    Content-Length: 0
    Connection: close
    Content-Type: text/plain; charset=UTF-8
    ----------------------------------------------------------
    https://idp.testshib.org/idp/profile/SAML2/Redirect/SSO
    GET /idp/profile/SAML2/Redirect/SSO HTTP/1.1
    Host: idp.testshib.org
    User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:17.0) Gecko/20100101 Firefox/17.0
    Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8
    Accept-Language: en-US,en;q=0.5
    Accept-Encoding: gzip, deflate
    Connection: keep-alive
    Referer: https://idp.testshib.org/idp/Authn/UserPassword
    Cookie: JSESSIONID=24AA89FAB41B6E5ED3C2AB27C7C3D9ED; _idp_authn_lc_key=2d735741-ebc5-4cc6-a952-70d7af52a10f; _idp_session=OTguMjI5LjEwOS4xMzk%3D%7CNWNlMzYzYjg5MGZjNjhjZDFhMGFlOTg4YjQ1Y2I1YmU3YjFkMmVkYWViYzM1NDM4YTA2YTgwMzA0OTc1NGRmMg%3D%3D%7CCEW23DEYJY16AOz99TVa0UwEhyQ%3D
    HTTP/1.1 200 OK
    Date: Mon, 11 Feb 2013 20:49:26 GMT
    Expires: 0
    Cache-Control: no-cache, no-store
    Pragma: no-cache
    Set-Cookie: _idp_authn_lc_key=2d735741-ebc5-4cc6-a952-70d7af52a10f; Version=1; Max-Age=0; Expires=Thu, 01-Jan-1970 00:00:10 GMT; Path=/idp
    Content-Type: text/html;charset=UTF-8
    Connection: close
    Transfer-Encoding: chunked
    ----------------------------------------------------------
    https://dvn-vm2.hmdc.harvard.edu/Shibboleth.sso/SAML2/POST
    POST /Shibboleth.sso/SAML2/POST HTTP/1.1
    Host: dvn-vm2.hmdc.harvard.edu
    User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:17.0) Gecko/20100101 Firefox/17.0
    Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8
    Accept-Language: en-US,en;q=0.5
    Accept-Encoding: gzip, deflate
    Connection: keep-alive
    Referer: https://idp.testshib.org/idp/profile/SAML2/Redirect/SSO
    Content-Type: application/x-www-form-urlencoded
    Content-Length: 17800
    RelayState=ss%3Amem%3Adb7acd8e62db6649a0ead2287c34e2987ef6323993bd08c171fe2083968ad529&SAMLResponse=PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiPz48c2FtbDJwOlJlc3BvbnNlIHhtbG5zOnNhbWwycD0idXJuOm9hc2lzOm5hbWVzOnRjOlNBTUw6Mi4wOnByb3RvY29sIiBEZXN0aW5hdGlvbj0iaHR0cHM6Ly9kdm4tdm0yLmhtZGMuaGFydmFyZC5lZHUvU2hpYmJvbGV0aC5zc28vU0FNTDIvUE9TVCIgSUQ9Il9hYjQ0YzU1NDFlYjU3NmVjNzllYTI2ZmU4ZTU0OGQ5OSIgSW5SZXNwb25zZVRvPSJfMGQyMTU5NWE4Y2YwNmExOWVkNjYxZjIwMzdkYzFhMWMiIElzc3VlSW5zdGFudD0iMjAxMy0wMi0xMVQyMDo0OToyNy4yMzBaIiBWZXJzaW9uPSIyLjAiPjxzYW1sMjpJc3N1ZXIgeG1sbnM6c2FtbDI9InVybjpvYXNpczpuYW1lczp0YzpTQU1MOjIuMDphc3NlcnRpb24iIEZvcm1hdD0idXJuOm9hc2lzOm5hbWVzOnRjOlNBTUw6Mi4wOm5hbWVpZC1mb3JtYXQ6ZW50aXR5Ij5odHRwczovL2lkcC50ZXN0c2hpYi5vcmcvaWRwL3NoaWJib2xldGg8L3NhbWwyOklzc3Vlcj48c2FtbDJwOlN0YXR1cz48c2FtbDJwOlN0YXR1c0NvZGUgVmFsdWU9InVybjpvYXNpczpuYW1lczp0YzpTQU1MOjIuMDpzdGF0dXM6U3VjY2VzcyIvPjwvc2FtbDJwOlN0YXR1cz48c2FtbDI6RW5jcnlwdGVkQXNzZXJ0aW9uIHhtbG5zOnNhbWwyPSJ1cm46b2FzaXM6bmFtZXM6dGM6U0FNTDoyLjA6YXNzZXJ0aW9uIj48eGVuYzpFbmNyeXB0ZWREYXRhIHhtbG5zOnhlbmM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDEvMDQveG1sZW5jIyIgSWQ9Il80YjcwZWI3YTQ4ZDI3MTVkZWZjM2JiMzdiNDhjY2Q1MiIgVHlwZT0iaHR0cDovL3d3dy53My5vcmcvMjAwMS8wNC94bWxlbmMjRWxlbWVudCI%2BPHhlbmM6RW5jcnlwdGlvbk1ldGhvZCBBbGdvcml0aG09Imh0dHA6Ly93d3cudzMub3JnLzIwMDEvMDQveG1sZW5jI2FlczEyOC1jYmMiIHhtbG5zOnhlbmM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDEvMDQveG1sZW5jIyIvPjxkczpLZXlJbmZvIHhtbG5zOmRzPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwLzA5L3htbGRzaWcjIj48eGVuYzpFbmNyeXB0ZWRLZXkgSWQ9Il83YzU1MTIzZjdiOTU0ZTg0MDdjN2QyNDk5ZTM2MTg4ZCIgeG1sbnM6eGVuYz0iaHR0cDovL3d3dy53My5vcmcvMjAwMS8wNC94bWxlbmMjIj48eGVuYzpFbmNyeXB0aW9uTWV0aG9kIEFsZ29yaXRobT0iaHR0cDovL3d3dy53My5vcmcvMjAwMS8wNC94bWxlbmMjcnNhLW9hZXAtbWdmMXAiIHhtbG5zOnhlbmM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDEvMDQveG1sZW5jIyI%2BPGRzOkRpZ2VzdE1ldGhvZCBBbGdvcml0aG09Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvMDkveG1sZHNpZyNzaGExIiB4bWxuczpkcz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC8wOS94bWxkc2lnIyIvPjwveGVuYzpFbmNyeXB0aW9uTWV0aG9kPjxkczpLZXlJbmZvPjxkczpYNTA5RGF0YT48ZHM6WDUwOUNlcnRpZmljYXRlPk1JSUREekNDQWZlZ0F3SUJBZ0lKQVBwVDYzTlBtTytPTUEwR0NTcUdTSWIzRFFFQkJRVUFNQ014SVRBZkJnTlZCQU1UR0dSMmJpMTIKYlRJdWFHMWtZeTVvWVhKMllYSmtMbVZrZFRBZUZ3MHhNekF5TVRFeE9ETXhNekZhRncweU16QXlNRGt4T0RNeE16RmFNQ014SVRBZgpCZ05WQkFNVEdHUjJiaTEyYlRJdWFHMWtZeTVvWVhKMllYSmtMbVZrZFRDQ0FTSXdEUVlKS29aSWh2Y05BUUVCQlFBRGdnRVBBRENDCkFRb0NnZ0VCQUs0eklTWXB6Mkswek1JV3A1MHVrV2pEb3pPUW1nVkpoLzZsWm5heTUrcWhSMXVPak1JTkZWek1VamRIR1ByeEJ4SmwKSlFLcS8rQ1FNV1h6UFFNd3FOUkRidTgvRVAwWjUrMU45L2VCMUFuZjEwNFZINTc3aENGUUxMdm5CMW9scWR5T2NEOG12STFtV0w5aApWZEZZUWFRWXJRamFKeXg1QnNvUitjTVhrVWwyVnpIZi9iOHE1dDExVDN4RlRMU2VUMUVraEZRUmVhYWJ1N3F0ejdWNis1SC9hV2hFCnlzSjNTYnhVUEhadkNRZ2syYmhBdU92SEtyMHNZSEJMRk9iNWtzVjdsUmZWaVpTL1pRQmRRbDd6V2dCRWZqbDJ4bm9rbnpTWjZIdlcKREk1cWRiSEttQkRhUUlpQ0x6VzNHdzRSb2NSNHhmL2JtYldBVkNNTDRyZEpkR0VDQXdFQUFhTkdNRVF3SXdZRFZSMFJCQnd3R29JWQpaSFp1TFhadE1pNW9iV1JqTG1oaGNuWmhjbVF1WldSMU1CMEdBMVVkRGdRV0JCUWI1aGRpS0d0UGNIZWIwY2RNbEh4eE9sUTJxekFOCkJna3Foa2lHOXcwQkFRVUZBQU9DQVFFQVhCaC9hNGtKTWx2ZGR4alppYVp6eHpkWFYvTWFWSUlnWExsM09vMWoydFNzNVl3VUVzNHIKamcyU1JqVE1lKzNHcUhvVEdvczVKYVlnQy9IaUpyZWVqYkVUbnUvYlNuLy9pcXI2dE1FQWl0Uko2S05xR2RQRkliUmxCM3p3K1UwSwppendnaloxaThxUnU0cDcwcS9sMWZ4eXoxbHhCN2hHR2VzMFFQOEhqUFE5MjlGRVN0QUFIUmVxZmJqVVNiazlXa3FkNzdaN1QxZzVkCllFNXVrYXFTRGdhQTBEWTZFRzh2V3NqVjNSazl1a0R2eXd1UFUxRkdPeWxWLytxa1p2aTc5VnVDVjRadHlYMWs1U1djZ1d2Si9FYTMKWUNWVCtZWEhjSi9DN2RRSG1xTi9JNENDOTMxMzk4d085YlE4S3BnN2EvYnJIV2pXRWVZTVEyL1hyNEdPVEE9PTwvZHM6WDUwOUNlcnRpZmljYXRlPjwvZHM6WDUwOURhdGE%2BPC9kczpLZXlJbmZvPjx4ZW5jOkNpcGhlckRhdGEgeG1sbnM6eGVuYz0iaHR0cDovL3d3dy53My5vcmcvMjAwMS8wNC94bWxlbmMjIj48eGVuYzpDaXBoZXJWYWx1ZT5RM3dWU2doMGZ5bGNDeC9nZjNJYnFiNG5VQnZ0TW5PanRRRHhLK3A2Q1FJWGtnMm9ESnFLMzR5aHpMemdPc0pyUlNiOTZ0bHhzcWw4d1poYXNUYzIrdXBkYURtanVmbjlzT25JaGgvdXhUZmlld1JBbVpyeXN0YnpHN3ZKUlhmbDZqZEtqTG5Ea3V5a3o3ZXZtZmtoTkpKMlVJUnFUV2ZZVGRkeko2MmFBK0x4OGRHcjF6ZC9RaGhhN3JPOHFjbkR4R0hham9YK1FiRERVazJFTW9BeVIxdzJUSlNRK2JUUEVZd0YxTHRHdHo5UTB1OVFnVnh3Z3dJb0NEZkJML3JZMGlLd2s0SHFEVUxjR1ZFNXNoT0MvTjdvdUlPMFFaQjBMT09qZEp2RWVoemQyNTcxTDNTL1RvYjllMnFURDdmWFFCMUF3VlN1RW1xb010N2RONjg0M2c9PTwveGVuYzpDaXBoZXJWYWx1ZT48L3hlbmM6Q2lwaGVyRGF0YT48L3hlbmM6RW5jcnlwdGVkS2V5PjwvZHM6S2V5SW5mbz48eGVuYzpDaXBoZXJEYXRhIHhtbG5zOnhlbmM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDEvMDQveG1sZW5jIyI%2BPHhlbmM6Q2lwaGVyVmFsdWU%2BT05BY1NqUDkrR2ZkWkdOczk4a1ZFNU80L2xIMHR4K1MwekU5cUZuSGc4Sy9aV0oxTEREUU1vOGpTdzVpVDJvd2dZcko0UVhaRE5KeXdYMDZpa25JQ09KTW5JdXptNzNpQ1NKdG83SzFsQ0x4ai9kdXloNXJqZ1JZTVJqWmgrdzZRdnEwSXBNVWhmSFZqb1R6R0w1RkhGa3VpTmowYlVlbWVqY25UbnNEbnplZUFXNmJJN2puWXVGU1RQckxwZE1ydmNBU3U2NkhPVC9leklhTnRZWVJGZFdBOGVVRGs2a21QbmNVazZzaFhIZFZCNGM2RHNyZW9WbjJYTmxJcXBtMnNmQWdLcHFzTm4yc0VzWXhDbkJzZVpsUXMzYnBNZVRjZ0FJZDF3NXphVGxKVDVxN1hsQWdSZk11aFRTbTdTMXZ0UDhOdEJZMVA0ZzdRY1JrSWN4ZGl3eDU2b2F6eVdsSEQ3TzEvb0FtK1ZBck10eG9EeVRuRDJxdXBza1orTUJ5L200MGZNS1BpaS9oMVZYalBKaDR0UEQ0WUNKZGVJckYzbU5jTlV0UVR0WURETjJMQm0wNXJoaHB1RU9TVDBMSWp3NjN1eXQ0K2dUcVRBQWd5bSt3Y2pNMUxlMWJaWE5HOEtKT0NMRHowcWhFUVN0KzdJTlJJNVV1M05lbHkxa2hXanFkU3JVeVAyVGFiUEFBK2kyWlZKUVNRZnQ5UXdzUUE5T1NKTWIxUXZKOENiY3N5Mmx3dHdBMjFRYWhsM3BOSllYbUdLSW5PL25IMVpNenhLT2ZDTFFoQmkzbkdxU2U0SnEyR1RHL0lRWkl0dlc5aXJmRGRIaTgzVVRCUW1XTjdmNG9VckNlUFhZZEJKSFRmdlM2d1hBSkdPNTRhQTlPMGVVbWtXK3R3NC91SExVTGZLTDlnQ1JQbFNWTGcvT2g2VTlSLzJueE9oUDNQbUpnRmVrS0ZrdUR3eVNZYmhQWUZCd3RtY25pUXRqR1pvVVVKU2NDZkJqaEd5Ykw5Myt3TzhlZTFoMWp1T21uMW1yTEFSaEF6R3pUbWdVcVh6MStHVkwyVVhSQXZ3Z0dLWkFOYmdYOG5ISjV6NTNlY1IwYm93UWlXc1BhVkZITjlmZjU3UzkvZzQwUk0wS3lmakxZT3JTSmhTZSt6NGVuWloxVUlPZGdvSWxJK0NqNE04SWR3aEkyWmpxdFM4NnJCVnRFT3kvalZJSVk2SEtKYVdIdVNFeWVnS256Nlg4N1NvYVh6VXkvUHJtUXU0VmZNUmEyOEthRXRtVkhKQms3eHJRRWY2Skl2OVcrYytpZkZWdFc5Q3hVUlFFcDNZWitaUkowTDRwRmxKNDZaZEg3d0FxNlE5T01xUEkwWFNOd2M4aWVaQklWK0pZVVVJMjNGL0F3anROS0x5NTJ6aFcrRjcwWjZndDJNd00yaXNoYXFTV1VxZFdrcnppMW1LN3Z3Unk1bmlNa1ltU0RkdzJwcWg0Vzh4ZlV3K012MmdrTGlzT1VMSkswM3Z2QlprbnpIU2FnRFZNQVU0K0I4Nmt1OFRVcjdPbnlVckZ3QkErVkhmN2FRclRzd0Z4UlFRZVkrai9tVmVnWjRYN09LQndSOFZZRzBHaEFHYVRmaW0rRTZ3OVNhL0MrdUtqS21WQ1RhUHg5dXFYbk5zVlhmMFoxR2Mxc2xkQjFKdTNjcll4SmN4eDdkUDY5RjdUdkloZTRMNXJkWHFtL0dQK2xHLzM3WXRSeDZtc2pEYmZRNDRaQ0JlTlJBSVpnSWk4d2wxNlJCcWZ5Q0VaN3BTY1J0WmdpS1pMMzMwWkgvK3had0s2VHJLK3Z4OStUdFdFcEFsUTBoNTc2Qzc4Njg3ZzJDdWE0ZyttMTdqWDBBZ3BPL3BXVG1WbGxhc1VxNEgyMEtaZzN2a3c5WncwVzk1ZGMxakFlZm4yeTN0bk1qRWQzMlY1Uk9TeCs3NEJaYjlvalA1OEt4Q2JOMi9TVXRDQVB6QjNMRG5pTkZvQnlrVDdQU2lidndXSlFNNFZFblRtSGFGSWdXRURwek1WWERNK29qbURTUEUvb0xQRWttUURnUkZnaHlkWmhaVVdoZThnTTg0N3d0YWF3eE1KQ21nM0FFbUhIemVrWjFTKzlQNk5EUnM3SCtEZis5eWpkbTZac0ZUVTEyS1hNcC9xaWt6OXVNSjRubjNCZ2E0SlUrVFVGSmhUYzZWS1M4VUZLYTUyUjBIb0NvZWVIbVZSdkFVVXRnRDl1UGFZYysrNjJOcDdqREgvYllLUFJUc1RxdU9FZm9iSEtQR201blJ2N1FRODAwckt2d1p2aW55akNDMkxDWkV2SUVDaFptdHI1bFdxa2gyUE5DS3owZ1pOa2pBR0ZndnNraXRuNlAxTDhwUzRUS0Y2NWl5QkViRHAzdm41MHI0RHBsMVdhcWdlYzFMalFERnNqaEtFUUFqSE1vRUZhRnViZTZpKzFHUDVjaHptRUlwMEhsN2pqNms1M1hYMGQzSk5vejJSc0h2bUxCRkZhWml3Y0UwNGFSVFVrN2toaktxNEV3Rzh0NytBT0xJNjJ5MldHSDRuSWtoMnVWb29hdTh2THVoQUxtdUdxNWpNR3YxSDVKUndBRXVFYkZlSGsxVSszdmpXV3J3R3VZY0lOdEU0ZVc4QU5uS0VGRi9ZdkJIa0NDSUYxMlBid3JGY25wb2F0c2w2ek82QjU3cXlyTjZ0SWdtZkZWRytDazJxYmh2K3d3MStPZW1jZEx4SE1PQ0toL216eHh6aU4zVnAwaVEzemMyL1NneGN5TmkxbmhpbWhPM2tnY1ZWLzYwUHdtdks5RlUwYldGbkJHWUtac1Y3dmpyaEx4MmN0enNkdVBHUnRZV2kvTGJEanhjZUVGcWRxSE1TK084UTJKUHZ5ODI3VXhQVWt2Sm9qUTh0MWxRTGx6VFErOG5LeDJBVnlhcUFlako4b0NPTExJQzdUdnNjUTRHblV3QVAyL0xDK1JVeFJxVWFlUEpiU0FNOUFySlU1M1o3K2lqUzY2UnBmTVIwVXVuaXUra1M5T29zTFBCUFdRTkkvOElxRS9oc2tSbi9zOExWK1AxdkNPQ050ckpPT3JpR1dvcXFsWjQ2ZUNNakVnc3VBVXBUZURUdjFHWG9UcjFNMzZoMjkyem5XS2dpZlFycEpjQ1F6aXRUZHdOd3hMWUNIRzA4RTZGWDcxZUd2ZjRXcFROdlo2RDE5d1MvS3VQblhzdG1zSGMvWm9OUk5Fb1Q2N2ZQTTRpZ2FkbXZBV0hyWEVXWWhlTmxqcjRjUm8ydWtQYWtzbmU2WS9qQkFMcTdQcWpaVlR6OWNJUm5WU1FoOHBvcENhL2xncVlaRVZqU2FRbW1YK3FoMDI0cmVKNkZUSmorODgvSzNyYUQ1TGRMVGw1RXorVXZ3L1l1S2xNSGo3bzZETFpYTHlxcEcwR1RPNENwRDBHeUVCcmVuY0ZJTkhueG5zdCt3ZTRxTlp5QkhtbE8vQ3pWdnZiWGRYNEt1NWRweFZZZnEzTG9STlVpLzlRYmE4WCtEdC9JeFZlaGtEVXlnTmdYYmdkUkw5aEF3dWNvd2lTejAxdS9NWXFmYyttU1VpNThtd3hlL3RncDh6S1NWU3ZnY3FqLzBFVWt6aWZnS3hTYWliN2g0Nk9SZW81aGdHb01WZmdUeVJZTDJqaDdZSlk4MVN2ZHJ2WDYwRUI5NXZITDVIOXlIU3RjYXp3THk4RER6Zm9COFZmKzBhaDZGaUNORVJaL2o2aDAwU2VOaDBqcWhMcmY2b3FKQ2RLYkh2SWcxK2VpUlhZNy9UTTlDeitvQ1ZteVZuY20xaUhYaDZMZThxSWllRUtKdGdCR3Z2WDdHVEdjMTFyWlJKMjN4Nk03N3M1MkpKYjRWVWpEdTJKSjJqalVMcmlId3FuQmRncjVOZ2pDSW54dVNCYndFcXE2dmdaUGFjanhUWGtTVld4K2VmcUZFS2xBK25SR0pwemJwV1BPQkp6U056WWUrWW5EWUQyQUdSTTBrbjBLOWR1Wjd3S2RmYzZVKytSUEpWeDBwazNkTTZ2ZWlyM2dJV2xlM1o2R0hlK3hTa1U0V2UrcFVPNmg5N3JINjN3dnhLWjRTZG9CVHhGZElSQWpidkF0SHV5RkNXNGE0L285VkJFVGQrQnR4cWtyamg1UllaTVREMExLVG5WRHE2a3RoRWh6RVp0WmVkRS9oWVdzLzBxVW9Ycy9oWGNnbGlQOTBNaEZvZW5JRklXRFcrVVRsdXpweEZWK1VwWCtEalp0akd3WGFwQnk2eHdUVFhMNEFPbmw5OWRybXdqeTZBai9ZQmF3NlVNVzhyREpGWU1LWExWam9kYnFMWXNadmNqaERqU09MaDVDQTFXeXpmbGRrZDNFQlRGN0I1dTlvUGM0NWZUYWRuSE1UQlg5TFlkUmRxamJLSDA4SVV4Sm52RFFZdkZEVkRzeFM4Q1dRelp6NFlETC9oZm9EQ3RkZlI3aDRYOWhGWE03cnZiREorUW03eHkyeWZkRjBPRWhhSHNqazJOU3lNVEdaTlJ6dm4yRnZyeEpXSTk5WVlNWmJ2UERwQTRISjB6WFRLK2JRZExNUTk1dmt0anVnd1BtSFVLa2V5YU9CemZhZGpvQUNKNVQxVkdpSFljd25sN3JKSnBRT1dsWkppdWdsOVk4RkV4SVl1TEIvSUJ6WEh5VzJIY2VSamNBMFlQa1RLUU5tZVI1bUkyajVKWnpsSTBBOVozcDZudWxiSTVqbERKQUI3cHhkc3hTOEY4Mm1oQmVXYWMrU3FzNkNsNFdDdHZISzJ5NDlBSTVEamU3eENzTm45WVZLNzB3aTVPWkRtd1c4UzJDTWdWQjhIMkVtMEdBMzlwWWFhQnpSRHIwT1ZjaWFDTVFmMTFscy9LL0JIeVVEQUlyK1gyWDlNMm9QY0Vld1k4eUVma3JDSWFOcFpOZXBudTVpQmNFQVdpYmlxZVFVYVFaRWIyMm9OSzVSSkFEY0JOb2xsbnIyNWZnTkw1RTlPQllZQmEvNG9GYnlQcFBmZ3VVcmZHQm5YV2FNdUVvNTExNVVYVTMrT29sZGVrOWRacDN4cGcxTXFwQTVjOFc2dUtUZlo2aThLcDBBSU9YZWRmUjNyemU1SlVQalU4dGFEZzYvTmFCWmJpVHp1VC9UbERDbnZVWEs5eFZhNktseDNSMzVwVll0aFJkbVh0WllwVHdKL29FQVpTa2tKQ3dhd0dGUWlRRnhrV0tHTTBQdnRJRXgzbXVXR0x5NHRDNmNqLzhCSHllSkQveExubGNOa3dYSUxQaXRoOElnQnVqeHk5eXBlM2lCVFpKM1BNZXNZVnVHUGV1NFZ0UU1zNktFSUFxemJ5RjIzWGRIclVZWlNraFphZWltWExQTmhkeW5lUE9kQmdscVo1SzNPK1VsYUZ0U1FBMDBaUXY3TnpVbnRlRENGcFF2S1lkUWJBZGdNZXlTN2xIZmJLSG5KWlJUSWVSYlVwTTl2ZHNEWlNTODJpK0M5ZHBkM2IvSzBkYStBd3lyWEJZTERGR3gyNDRZbWFKKzNnTVpjanltYS94OVA1UVF1TnFGai9vTnA1Z1V6WHpnNXorM3lpSGZkY040Z2U5bVZ5cWpwNHlGbVBkdlNjbDdXZ0pMNCttUkJJTXE3QTBjRHhxY0FQRGFGZklIVzNOZGMxZjl6aXppdXFwaWxTVFByamR2ZVZvbHB2RkJKRVJMTGRDR0szc0FFcGdIaHhEWFE3ZWc1eXc5ZXVDMEhFeXJkRGJMZ1FQSEhtdzczeGJSZXpzSHNGOGowRDluTU1FUnBjMjBBaW5SRUpaeFBiMnlCaUZBOEVibmJuY2pKcTBiVWJWZEt0UWd4WUFNcktxd0NzOVRsb2RpM1R5RXo1bGFmM2RSbnJBSlUwQ1djWXRRZVNnQ3R2b1J1dzVCOSthRENuVWdvREdCSmkwZ0hiUC85UXlQN0JtdjRNZmpWdnY1RG9uWXVpUm9hWnFBVE9yMGVJUk95eG93S3FCK0Z0QXJQNTdJOWVjdjlIamhyQm4xMVYrU2JIRDBmU2I3Y1RXSC9yNzhTbEVRYWZKeWlpMkl2K2N5VzI5SFkrK2kxMy95Q1V6bU82U0lEclNqSjAvbDduQVZyYldiRVhYWDJlVGZxNTI5UGw1eUU5bTBHQVVYVWRlVU1mMStMU0FoT1pEM0ZENy9wMko1TWttT09LK1VBdGhBbktVSHFPQnZaY3FlZG5sRncwaVhtcUJLaTF4UXhURVkxRFBKZkJBeG9GQU10UDJwVGxvWTcvdlFuYzIvelZHN2NWa1RVN2RzL1VFaVo0OUZHblZXMnY3RWlkdWNObW84YXcxcFFObmJRdDcxek85RUVIeVY0dXBYZGNxQWlTVmxTaWxpU2dpd0U4TzFYYTNMWSthUGZqTHlHTGpwUFZKRTVaaklXS1d2S3ZmTldadGQ4VjByTlFVNUtDR2JMdTh1NzJ6cE5lQlQ0QkxTUER5djRPemNTMGxHOC9kNjZiN3Zvbzh6RWt3WUUrR21Vc1hMdlBVOEtjYVRqU3R4N0ovMnJ4QlRBYnNPbjNYQ3BVaGpKMS9td1VVRlhZVElQc25tMHBXZmJGcVRrZ3JMenJhVXhuTXE2N2NtaVBUMGtrWnRTU0V4Q1N6Sk56ei9HTHBjeDB4RGQ2MFd5QkMxdHROOUZpZlk5RXVtQ2pjNHdtLzYrL1MyZXNWbTJRSHVSOXhidGd4ckNaUE8vMmVyWmpTZm51ZVFSdE5mWUJGM0V6cnFIUlRDVU9GVWtmdWRySmVpeEw3S25QM2I3N0gvMVB5VkFCYW8ybm5tYXZzT2FqNnJPRkR5UVFqV2dQRkREMkVRTXRxa2dJN3BwRFUzRmtKdFpXUFYwQ3hTaUdnZGdyL0swOVhldmJPVFFrOFMvemdxRTRvL2ErSUxsYXZiTlJiRnlCampCTUhrVjlqdVZRQUlueU5ibWtnZUFra0o4Vmd4L1VhbUZHSUd6aWkzQXJkcnRXMHh3MTdNVDEyQUJwSjBnOERnVFpOSjNnWFNPclc3NmorU1JaVk9GQVFIQmFYbWtDWS9aWEZtaG10ckNQbHdpUXM3Skg0ay8yc09ESmtybitFQU9QSVczU1paQUprQ0Vta1NiK1F3RGdRTTk3VklDcWg1RGY4SjlLemNxeFdUMGxqampNb1FGVURCdWNwZTNyM2c3U1FKeEhZTkRhNWNrY3dzZzlkNFJSVEcvMEFXK04ySWZTWG5lYkljRE5FNllLQ2tyU1dPYXFUK01QQmtVcTlMRHBjSGc1c0hlaDRjdTAxQ0pKTzRENjNDdFRXSnQ4anI0K1ZCdjF3elNOL0NxL0F1OGhlN05tTzZFSHZKK3VnYkM2Ynd0YVZHZy81OCtQRlVoQ0JYN2Q0SE1jOVBEZkVRYnIwdWNEVDBHYjJkNnh4Z0orL3B4S2FlVkNCWk9KdFBaSW43WU1ITmdUWGI3MUNhTmNCYmU3N2IxVmM5SjBpeEovd3ZTczhpc2JOYnlHamh6cDNCa2lDSmYyb2FKUjhNbDcyM1VhOXZTTUw5TTVXVW4zYjN3Q0cxT3R1RnBYeDBEOXRGNWlweXVKS0JkdlcrZTFiSXpyNFdFUFFPQStWQlJpcmtrWHM2aXNJWDNPcmNRN1ZEYnFsTHZQRjh2YjV5d0p4Qjh6KytPRjlxdWpLL1B1MXhyRTR2M0JSQWVaSjFZMEdzZWtqWlhVWU9UbDhwRm1TTE44LzU0Zy9aN2N2OUNnTHQwTENCdnplWFlnTHNTSUZ4SWpCSDRpc1NVTytrOXIwc2dIY2VnL3pBYU81aE8xc0huY0t3VWdQVnJkTUxKd05kN1RtVS9mVS81d1dCTDAxakNUREJrUXI2c2VwWnBnNWlaZlhvemk0TlZoTitudlkvTDBaNzJrYlhCR0puNnZ2SVhBNjJ1RkNhNE0vVk5PTjYzKzBhZmRYNldHbHgySEVKdGw5R0dYREJ2ZE9Ta2lPYUR3OWdlVlN2bUgzVW0zY0xIMkE0aWlMYmYvalI0Rm51RkNpekFLcTgwcXN3Tm92TUs5OHlMK3FlU3lXajJsM29zVFV2L3JqQkovSHpQZmtOWGhOdjZ5b2R6Z2Y5aXBxZnFZb2hWWUpRd29zdkZ5V1Rad3lFRlQ2TDJ2MWpLNFJRYlV0TzZxN2NpbU5TZmlQbElPRFVtRWcxM2p1M0dUVmJDTkhRa3JpRng1cXRuRnRqWHJ4QmxvM0NNeXhSVG9STnRmS3M4TU1jZ2ZkYmcyb25WaDI2U2N1K2tMVitIYnNSYzFkRTVTQzloT3drVnNKUjdYQXdMR2E5eEJDN1ZacjR4ZDdlLzNRclJOblYwaDFsbFVQR21tOTlZdkdXWUhxbFhWMlZaUTlCRVlmSytBeTJhaUQ0RVg2WDJPbUw0UEgxTU1PTDZMZnhvRFBhemlTV0ZkdTdENHN0SDYvUC9SRFllT0RwRDFCSmZWNWNhQ1Bvc05zUGtJSFliMy9GQ21NSkF3WUV6aml2Q0hSWVZXT3FURzRzZFFxa1dVYTVQOXNWOVNjVzg1V2hZeHFNTGJ4aUM0Z3VjQ2p3ZEdpckI5VUVqK0Z1YzcvL1BTQVpJNU9VandTSmtrNHNuT0VhaUpPWVU3Q0FuM0dJTnJMTE0vU2N0czdIZ3Eyd0xHZk54RmJjWWhxNVVSYXJ1WSs1TVFPZElOYnc2TklQZVkyQWFOTFhCKzE1M3lxK1NmNWpmazZRUnpBMEg4Yzh6MGRuVmFwSFBFS1FVTXdWeDM0enloNEowZU52UlBHdUFVWHpPNzArUlJnckpwQWI0R2tiNWNKR2dGWWJ0MDQwQnNmc3E1bENlTHFpQitHQzYvK1h6ZzhKVnVjbzBhUTRReVo0VStJSERnYS9VY3g2TEVZSTZjYUs5ejVhT1lPZWRYWmcwV1EwOFFadXhnMG1NMzFrQ2NvVmxYOHpBclh4bmJXSFpVcU5NcUFjbUxZdXR4bnA4ZXJwTko1YjhENEFpVngwSG14RkFzeFpVcG9lcEE1dXgvTWl6SFZSb2c4STVQZjkrSUFROHZzbkJ2V1hvYUJMVFZVSGxHZ2VPaitHNENnWjVJZzkrR0NWcE43S29kdWdsS3NYaTFNZmwrV3VBR2VtQUtkZlR5NFFoYXBOVWp3dlhIRVhISmdrODJvNzh4MnNwdDdGQXpNd3VlanNneHZ5UUFxZExWYTFsVHMwSURHeVFpZlhDaEdzVWtybE4vR2xqOXhaSyt0RjlUODlwK3I4UCtmMHE3K0VlZGRsbEFhWmJJYWxBU1FNT25xZEp6ejFnejhkTlBXdG9jUlhsYytacFN4TFNUSGtzc3BFOVNham5KZStWZVNKaWhUUUFGMG40NVZickxyK1E1aUozTVhqcWp4bTE5dEt0NUp4QkNRZnRMSERhdmJHdEhLdUVNOGY0MGUyREYxSG9SWG1YVmhBZUkwMUZ6ZmpPQWZlei9aeEtGWHFIWEVvckxxUmQ5Wld6dWg4YUppMUh3RWxXbUVWcXdUQ1ZrN3d4QzdkY3BEcFVBLzExYkpHTktvU2NHNFA0WFdBeEUzSFpyMWoxb3ZOSFRxb1Y3VGZZS0xHdXZ3UzlUMzYxSUpjYXE2c0RuQUEycGl4bTFKS3Q1REZ1UnNRL3VGbERlQ2dpaWg4ZXZSb1BET2h6amwwbnphOEFqK0hxMFZkY1E1eWpyVjdlZERaY2RnOUI4OGtzOHV5QWlEcjEwaUdwekd0QWEwYWpPcDh0YTZoaXJxSE9ORkpPRlZDcTNOcTdSSWtoOHczNVJib1BOWEhxQ2JSVG5tQzBLeDZ1RjhkZ1FkNFpiMVpqMFIwLzhFeElZNTJncHNOVmdZSjJRODBQQ082QWdZMnhPS3dTT01OVWVTUzBoQ0V3UkxrWloyMEpEN1VyL2VWMExQaUNPODVoQTA4eXh6QUk2cWxRbXZLbHVaQVhaaWVTR3JrVVBscVBXejVueWNTYWMzMTNJSHZqT2doRmJtWGpkNVlTeXlCUk1vdGtmaUp1NEJKWlFTVVk3NE90ZWhER3c1ZHZkTHMxR1drcE9zNlQ1Z1djM1JEZzBScFZWQkdqTWZxR3NCWTVjMC9MTlFMcXlvdTRweFhhSzZ5bDFkRVNscEJjaHBQSmJHc21QbnY0bG9QNGlpbUxtN1pSOEZKcWwxODJMU2V0OFg1aFJHWWIzbTh2MGszaENMT0MzL1RoVTF2MkwxMHg4ZUtiUjZkUDJKSkZtUEo3V2hyeFJkeUQ0WFIxcFRETW1QQTh6WFR1TVdtc3RzNjVhOEtFWmJNT2t0a2lwdzBvUzNUcmwzMDZreW5yRnJxOUxoRTVZR2lucTd3Wk93TEt2d21HQ2pwaGNrbXh0dkVyemJ6SzR0ZGhUNzRsckNNUzY2Mm5oQ25saUdFSHFhWkhnMzJCM0thZGxDc2pkbW5TL2drVzhjVnJkeFMzTndQaU1CR29oR1ZPWThobkZXdjY2UjVscy9BMXRCbW51L0ZYTTZwQTlCbVRTMzFVeUc2WWNzWUZiK01zWkdxV2VaWXZHeDlFWTdsUnBrdXFja1E3RG52cUg4dmdoNWVTRlMrTFdMK2lLWVh1M3ZsR2J5SGtyT2pHWVlaamJYUTd2Z0VHN09lSWM0di9za3orRHB5Z0RCQjNKZE5vUmVMRWV1Nk1idlgwMzZpR1VjSVRQV3ZJTkhJS0xmdzFQa0t2akowZzR2TUdWWnRRTVMxZVI5ZDVyZDR2VmU3aFZuVGVyYmR1bGJxRkNFL1ViMkcxcGZXaXFMOEtSY3ErT0E3MzVhaXhhTFdvWkc5TWtWbXhEZFhaRHdxTXRQVXMyaE9zZkM3MWR5dzU3SjdkUUVLUzIwM2Q5KzVHMlVNNFVpc2ZBUVpzQmd6UVpCRVdRZlFiYUN6aFhjQko0WkNVOGJ6TDdIWStwNjFrSzMrM3g0Q3RiNUprcHBibmhPTjVHdWxxYnNxNkUwVWRMVGlXYzNnZ3F2cE5rUWUySytHZ2FhZFVORHMrOENSbzBTM043amZlZTVJS0xrTExhNWVjeStSVWZZL1FZd1YwQzViNVNDN0lBVVBUNEhTUkJiWWprUVVqMDRDYWkvcElRNHZNaWJUUlhFZWVaRVRYbHFjMWJ6di9IREtiTkJlYXdoWEtqcXoxTjdBMHVyeERFVHRWYzhxQ0VURVRWMWhKZGVBK1hnRmo5d0VkYldkbHJWODllZ2dCNE90OVNMejRzQmdMMlRrOVVDT1NFNmI2d1NQZmRhbkRmbm00VFNsMEVid09tZjhMMkJiZ1Bmd01VdWlyRWVUUkg4UXo5ejNlM3VnWno3TFZLbldUY0ZhakJhMDRHU0IzZjhyUkhxU1Jlb1dWZjh1WTY2VkIvbmViMkJsN1Iyajg1eXdPVmhDMGYyMVc4RXNVL2kwWEFIb1pPeGIzWXEzOGkwR1hXVmFkMlBlRXA0VnpLd1ZRRjdFS080UWI3ODhwdk9DZURDRFFPN1Z1eHVtalB3NExNQ2VUWHYyNUlhcUxsd2ZUM2pOVGZIUGt5c0dZcExaM21QUlF1Wm5PQXh1R0IvQ2tiS0VNR1NrUm9nQ3hORFMySks1Z2FuV2lGUEFOZ2RhbXBsWCs0c1R4YnovTHlnU0c5SXdYMTV4TVh5UnNob1VicTFydkg2UDJieUpyTC9sQnY5OEh2WllCcGJkajBBSGpmZTh0eFlPTTJYVTZ1OWtqZ0todm5GTUZidmhNMzBIUHlZK29IVnNHVm1CNXc2REFDRkF0bVdKQkcyTituZmpUSXF2WjFTYkU0aWsxNjVZclpJYzFTTHJSa0RtdTVkUUhUSDVmNm04SDUxTkhON2EwTGI1U1dlQU56VHdxSmJsdjE3S203ODc1MUJYVzF3cXh2c0FZUVBNZ0tiaWpCUi9aRXZUSC95a1ViYUdNODVKM2dyNDdUMmlhNkhKU0dlSWVtRkFYQkx4bEpIYzlFNTlsU3lpWEhtZzNzL1VMc0UweWZBcjUxeFhjcGl5WGpZOVJ2TFlPWi82RTZaMlNrRFFkUUgxQWNES2NycCtORGphbVpHdll0SktOUUp1WG9hdlM4VXZEMXlCWDFOd1Z0ZTJOK3V0bmtDUFFHZzdZLy9KeXRRZ01LelhIK1J1UzFJcU0rRlY3cS9HWjBrRzgydjY0MmxyN2lIK1p6bFNNVjBsemt6R1pMS0ppcXhYZGtpZHFhdktobS81dHRMYjg1S2JSVFRXZWFXOVNxQVF4N2pzdmZTVkdNaC80TzRrYkRjaXNMR3lUMzB1WHFLWVZZR256eVp5NkxBMW4xSnkwUzNqbjMyVENYUG9KTUhGSUJlbVNzTVhyYnd3MkNvV0RTNkk0bkJldCtCZFJRY1psamQxVWtRTVh3aGh5QUhsSnNEaEo5Nkx1R2NuT3ArNkV5cUNtU0VvMVZ4K3VmdngzMk94akVIdlg1MHF6TVN3Qy8xUTFZRm9xWjVTakc4MTRyS29FOExXNVFZVGpOTUNFZnhTbkUySzNaMlRVSkNCa0tQbVVVM1Z4MEZMV1hyaEMxTWZSak9FWnFMMWEvSUlaYTJGUW95bjg1b0x2WkY1bmd4TVJ4am90UUlERGViblQwUUc4bGJpYmhZbTJFNjJtYnhadVY4bDRIQlBmSWFkVVdZaWFCWFhqVHcvVW1ETk5sMWU0ZmdlZk9pYXZFUUNkNzVaZXZNeHBZT1BUMlAvN1k5VE5yVGlkRkhHQlMwcFdNb3A4TWNwVEpKc2R2eXdEbHdiN2VyNmJwYWMweDkzVlJ0TGhEdmhkQmFaOXFJN1Y0dHlsU1dEd21sY3d0YmgvdldUZGtMZERRQW84b1k2S05LWFhmRFMrRnRXeUQxR29NZ3E4bG9ZbmNGZUZ2N1RoWVF2NGNZUktLMnkxNlVnbHFhODYyQjMvaHpxRWZWMVNib0tNMW1jZDF0YjRBQU85RCtyNnI3QVN0OElwbEFBNlEvTGg5WnZLY2tsQ0pIeVovdkZSSjgxUlNCTU5qbzNHQTIwV1h3STR3RDhVZmROdEZFOGhaV3VlbEkyQkdEbXh4ekhDN05nS3VuSE83VVB2NzEvUlFZZkZrYzYzNDNjUVhscWpnbVpWazVzSHlJMXdVQkl1VXY5Y1hXQVdYbDJkdU54ZURmaThoRlJXWldrN2FwK2xmUTFCbDFzOHdEb1pudUNYTGo0MnRlQjVHTHByT3NLdHF1bzF0NGJWNXY4V3ZrZkhvWm5GMytjYzlrVFdQMTNsaEVFTFRSeCt1eHdJTng1alh1MklqL216dGZPY2dwaU9abHZVek1VWHpJd3BQMUhodVNtOGtid1JUTT08L3hlbmM6Q2lwaGVyVmFsdWU%2BPC94ZW5jOkNpcGhlckRhdGE%2BPC94ZW5jOkVuY3J5cHRlZERhdGE%2BPC9zYW1sMjpFbmNyeXB0ZWRBc3NlcnRpb24%2BPC9zYW1sMnA6UmVzcG9uc2U%2B
    HTTP/1.1 302 Found
    Date: Mon, 11 Feb 2013 20:47:42 GMT
    Server: Apache/2.2.15 (CentOS)
    Set-Cookie: _shibsession_64656661756c7468747470733a2f2f64766e2d766d322e686d64632e686172766172642e6564752f73686962626f6c657468=_aca81ab83e42855afd1d0d7e04088fb8; path=/; HttpOnly
    Expires: Wed, 01 Jan 1997 12:00:00 GMT
    Cache-Control: private,no-store,no-cache,max-age=0
    Location: https://dvn-vm2.hmdc.harvard.edu/secure/
    Content-Length: 315
    Connection: close
    Content-Type: text/html; charset=iso-8859-1
    ----------------------------------------------------------
    https://dvn-vm2.hmdc.harvard.edu/secure/
    GET /secure/ HTTP/1.1
    Host: dvn-vm2.hmdc.harvard.edu
    User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:17.0) Gecko/20100101 Firefox/17.0
    Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8
    Accept-Language: en-US,en;q=0.5
    Accept-Encoding: gzip, deflate
    Connection: keep-alive
    Referer: https://idp.testshib.org/idp/profile/SAML2/Redirect/SSO
    Cookie: _shibsession_64656661756c7468747470733a2f2f64766e2d766d322e686d64632e686172766172642e6564752f73686962626f6c657468=_aca81ab83e42855afd1d0d7e04088fb8
    HTTP/1.1 200 OK
    Date: Mon, 11 Feb 2013 20:47:42 GMT
    Server: Apache/2.2.15 (CentOS)
    Last-Modified: Mon, 11 Feb 2013 18:31:36 GMT
    Etag: "4011d-b-4d5771e832bba"
    Accept-Ranges: bytes
    Content-Length: 11
    Connection: close
    Content-Type: text/html; charset=UTF-8
    ----------------------------------------------------------

## See also

- http://shibboleth.net/pipermail/users/2013-February/008056.html
- https://redmine.hmdc.harvard.edu/issues/2657
