<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
        "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">

<%! String current = "documentation"; %>
<%@ include file="header.jsp" %>

<body>

<a name="top"/>

<div id="container">
    <%@ include file="menu.jsp" %>

    <div id="content">
        <div id="main-col">
            <h1>Documentation</h1>

            <ul class="list">
                <li><b><a href="installation.jsp">Installation instructions</a></b><br>
                    How to install Subsonic on Windows, Mac and Linux.
                </li>
                <li><b><a href="getting-started.jsp">Getting started</a></b><br>
                    How to configure your Subsonic server by setting up music folders and remote access. 
                </li>
                <li><b><a href="forum.jsp">Forum</a></b><br>
                    Discuss and ask questions to fellow users. Roughly 30 new posts per day.
                </li>
                <li><b><a href="transcoding.jsp">Transcoding</a></b><br>
                    Detailed documentation of how Subsonic automatically converts between music formats.
                </li>
                <li><b><a href="translate.jsp">Translation instructions</a></b><br>
                    How to translate Subsonic to a new language.
                </li>
                <li><b><a href="api.jsp">API documentation</a></b><br>
                    How to access Subsonic using the REST API. (For developers)
                </li> 

            </ul>

        </div>

        <div id="side-col">
            <%@ include file="download-subsonic.jsp" %>
        </div>

        <div class="clear">
        </div>
    </div>
    <hr/>
    <%@ include file="footer.jsp" %>
</div>


</body>
</html>