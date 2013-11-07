<%@page contentType="text/html" pageEncoding="UTF-8"%>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN"
    "http://www.w3.org/TR/html4/loose.dtd">
<html>
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=MacRoman">
        <title>Shibboleth Attribute Dump</title>
    </head>
    <body>
        <p>Attributes from <% out.println(request.getAttribute("Shib-Identity-Provider"));%></p>
        <ul>
            <li><% out.println("Shib-Identity-Provider: " + request.getAttribute("Shib-Identity-Provider"));%></li>
            <li><% out.println("eppn: " + request.getAttribute("eppn"));%></li>
            <li><% out.println("affiliation: " + request.getAttribute("affiliation"));%></li>
            <li><% out.println("unscoped-affiliation: " + request.getAttribute("unscoped-affiliation"));%></li>
            <li><% out.println("entitlement: " + request.getAttribute("entitlement"));%></li>
            <li><% out.println("persistent-id: " + request.getAttribute("persistent-id"));%></li>
        </ul>
        <p>Return <a href="index.jsp">Home</a>.</p>
    </body>
</html>
