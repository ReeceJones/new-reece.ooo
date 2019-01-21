module utils.routing;

import std.stdio;

import utils.log;

import vibe.d;

import std.json;
import std.conv;

import blog.database;
import blog.post;
import blog.manipulation;

import blog.user.auth;
import blog.user.user;
import blog.user.captcha;

import blog.stats.page;

/**
Function to uniformly render a diet page. This allows us to log page requests, add authentification to each page, etc.
Params:
    PAGE - The diet page that we want to render.
    ALIASES - The variable aliases that are passed to the rendering of each page.
    req - HTTPServerRequest
    res - HTTPServerResponse
Returns: nothing.
*/
public void renderPage(string PAGE, ALIASES...)(HTTPServerRequest req, HTTPServerResponse res)
{
    log("page: " ~ PAGE ~ " requested. (url: " ~ req.requestURL ~ ")");

    // do anything you want here
    auto session = req.session;
    bool active = false;
    bool admin = false;

    dbConnect();
    statPageLoad(req.requestURL);


    if (session)
    {
        string username = session.get!string("username");
        admin = session.get!bool("admin");
        active = true;

        res.render!(PAGE, /* our own aliases here */ active, username, admin, ALIASES);
    }
    else
        res.render!(PAGE, /* our own aliases here */ active, admin, ALIASES);
}

/// Index router
public void routeIndex(HTTPServerRequest req, HTTPServerResponse res)
{
    auto posts = getAllPosts();
    foreach(ref post; posts)
        post.content = filterMarkdown(post.content, MarkdownFlags.backtickCodeBlocks | MarkdownFlags.keepLineBreaks | MarkdownFlags.tables);
    renderPage!("home.dt", posts)(req, res);
}

/// Blog index router
public void routeBlogIndex(HTTPServerRequest req, HTTPServerResponse res)
{
    auto posts = getAllPosts();
    renderPage!("blog.dt", posts)(req, res);
}

/// Blog request router
public void routeBlogRequest(HTTPServerRequest req, HTTPServerResponse res)
{
    // /blog/
    // writeln(req.requestURI[6..$]);
    auto getPosts() // use this to prevent variable shadowing error
    {
        string url = req.requestURI[6..$];
        dbConnect();
        auto posts = postQuery!(url);
        return posts;
    }
    // submit the db query
    auto posts = getPosts();
    if (posts.length > 0)
    {
        auto post = posts[0]; // there shouldn't be any duplicate posts, but we will take the first one
        static foreach(i, member; __traits(allMembers, BlogPost))
            mixin(typeof(__traits(getMember, BlogPost, __traits(allMembers, BlogPost)[i])).stringof ~ " " ~ __traits(allMembers, BlogPost)[i] ~ " = post." ~ __traits(allMembers, BlogPost)[i] ~ ";"); // I love metaprogramming
        content = filterMarkdown(content, MarkdownFlags.backtickCodeBlocks | MarkdownFlags.keepLineBreaks | MarkdownFlags.tables);
        renderPage!("post.dt", date, name, description, content, url, author)(req, res);
    }
    else
    {
        string error = "404: You've made a wrong turn";
        renderPage!("error.dt", error)(req, res);
    }
}

/// Authentification router
public void routeAuth(HTTPServerRequest req, HTTPServerResponse res)
{
    //missing username/password, tell the user to fill them out
    if (!("username" in req.form && "password" in req.form))
    {
        JSONValue j = JSONValue("{}");
        j["error"] = JSONValue(2);
        auto vibeJson = Json(j);
        res.writeJsonBody(vibeJson);
        return;
    }

    // submit the captcha to make sure this is legit
    string captcha = req.form["g-recaptcha-response"];
    if (!submitCaptchaRequest(captcha))
    {
        JSONValue j = JSONValue("{}");
        j["error"] = JSONValue(1);
        auto vibeJson = Json(j);
        res.writeJsonBody(vibeJson);
        return;
    }

    string username = req.form["username"];
    string password = req.form["password"];

    auto authResult = authenticateUser(username, password);

    if (authResult == UserAuth.AUTH_SUCCESS_NORMAL || authResult == UserAuth.AUTH_SUCCESS_PRIVILAGED)
    {
        auto session = res.startSession();
        session.set("username", username);
        if (authResult == UserAuth.AUTH_SUCCESS_PRIVILAGED)
            session.set("admin", true);
    }

    JSONValue j = parseJSON("{}");
    switch(authResult)
    {
        default:
        case UserAuth.AUTH_ERR_DATABASE:
        j["error"] = JSONValue(3);
        break;
        case UserAuth.AUTH_ERR_PASSWORD:
        j["error"] = JSONValue(2);
        break;
        case UserAuth.AUTH_SUCCESS_NORMAL:
        case UserAuth.AUTH_SUCCESS_PRIVILAGED:
        j["error"] = JSONValue(0);
        break;
    }
    auto vibeJson = Json(j);
    res.writeJsonBody(vibeJson);
}

/// Creation router
public void routeCreate(HTTPServerRequest req, HTTPServerResponse res)
{
    //missing username/password, tell the user to fill them out
    if (!("username" in req.form && "password" in req.form))
    {
        JSONValue j = JSONValue("{}");
        j["error"] = JSONValue(2);
        auto vibeJson = Json(j);
        res.writeJsonBody(vibeJson);
        return;
    }

    // submit the captcha to make sure this is legit
    string captcha = req.form["g-recaptcha-response"];
    if (!submitCaptchaRequest(captcha))
    {
        JSONValue j = JSONValue("{}");
        j["error"] = JSONValue(1);
        auto vibeJson = Json(j);
        res.writeJsonBody(vibeJson);
        return;
    }

    string username = req.form["username"];
    string password = req.form["password"];

    auto createResult = createUser(username, password);

    if (createResult == UserAuth.AUTH_SUCCESS_NORMAL || createResult == UserAuth.AUTH_SUCCESS_PRIVILAGED)
    {
        auto session = res.startSession();
        session.set("username", username);
        if (createResult == UserAuth.AUTH_SUCCESS_PRIVILAGED)
            session.set("admin", true);
    }

    JSONValue j = parseJSON("{}");
    switch(createResult)
    {
        default:
        case UserAuth.AUTH_ERR_DATABASE:
        j["error"] = JSONValue(3);
        break;
        case UserAuth.AUTH_ERR_PASSWORD:
        j["error"] = JSONValue(2);
        break;
        case UserAuth.AUTH_SUCCESS_NORMAL:
        case UserAuth.AUTH_SUCCESS_PRIVILAGED:
        j["error"] = JSONValue(0);
        break;
    }
    auto vibeJson = Json(j);
    res.writeJsonBody(vibeJson);
}


/// get router
public void routeGetPost(HTTPServerRequest req, HTTPServerResponse res)
{
    auto session = req.session;
    if (!session || !session.get!bool("admin"))
    {
        res.redirect("/");
        return;
    }

    string url = req.form["url"];

    BlogPost post = postQuery!(url)()[0];

    JSONValue j = parseJSON("{}");
    j["title"] = JSONValue(post.name);
    j["description"] = JSONValue(post.description);
    j["content"] = JSONValue(post.content);
    j["url"] = JSONValue(post.url);
    auto vibeJson = Json(j);
    res.writeJsonBody(vibeJson);
}

/// edit router
public void routeEditPost(HTTPServerRequest req, HTTPServerResponse res)
{
    auto session = req.session;
    if (!session || !session.get!bool("admin"))
    {
        res.redirect("/");
        return;
    }

    string url = req.form["url"];
    string title = req.form["title"];
    string description = req.form["description"];
    string content = req.form["content"];

    updatePost(url, title, description, content);
    res.redirect("/control-panel");
}

/// delete router
public void routeDeletePost(HTTPServerRequest req, HTTPServerResponse res)
{
    auto session = req.session;
    if (!session || !session.get!bool("admin"))
    {
        res.redirect("/");
        return;
    }

    removePost(req.form["url"]);

    res.redirect("/control-panel");
}


/// Logout router
public void routeLogout(HTTPServerRequest req, HTTPServerResponse res)
{
    // terminate our session if it exists
    auto session = req.session;
    if (session)
    {
        res.terminateSession();
    }
    res.redirect("/");
}

/// Control panel router
public void routeControlPanel(HTTPServerRequest req, HTTPServerResponse res)
{
    auto session = req.session;
    // go back home if the session is invalid
    if (!session)
    {
        res.redirect("/");
        return;
    }
    string author = session.get!string("username");
    auto posts = postQuery!(author)();
    auto stats = statsQuery!()();
    renderPage!("control-panel.dt", posts, stats)(req, res);
}

public void routeNewPost(HTTPServerRequest req, HTTPServerResponse res)
{
    auto session = req.session;
    if (!session || !session.get!bool("admin"))
    {
        res.redirect("/");
        return;
    }
    string title = req.form["title"];
    string description = req.form["description"];
    string content = req.form["content"];
    string author = session.get!string("username");
    simpleCreatePost(title, description, author, content);
    res.redirect("/control-panel");
}
