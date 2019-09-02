import vibe.d;

import std.stdio;

import utils.log;
import utils.routing;
import utils.config;

import blog.user.auth;

import std.conv;

import mood.vibe;

shared static this()
{
	config = new SiteConfig("reece.ooo.json");
	string sitekey = config.lookup("recaptcha", "sitekey");

	log("Starting webserver - reece.ooo");
	log("Setting up page routing");

	auto router = new URLRouter;

	router.get("/", moodRender!"index.html");
	router.get("/login", moodRender!("login.html", sitekey));
	router.get("/create", moodRender!("create.html", sitekey));
	router.get("/logout", &routeLogout);
	router.get("/blog", moodRender!"blog.html");
	router.get("/blog/*", &routeBlogRequest);
	router.get("/control-panel", &routeControlPanel);
	router.get("/projects", moodRender!"projects.html");
	router.get("/altitude", &renderPage!("altitude.dt"));

	// default rule, auto-server file from the public/ directory
	router.get("*", serveStaticFiles("public/"));

	router.post("/login", &routeAuth);
	router.post("/create", &routeCreate);
	router.post("/new-post", &routeNewPost);
	router.post("/get-post", &routeGetPost);
	router.post("/edit-post", &routeEditPost);
	router.post("/delete-post", &routeDeletePost);
	router.post("/comment", &routeComment);
	router.post("/remove-comment", &routeDeleteComment);


	log("Loading server settings...");
	auto settings = new HTTPServerSettings;
	settings.port = 9001;
	settings.bindAddresses = ["::1", "0.0.0.0"];
	settings.sessionStore = new MemorySessionStore;


	void handleError(HTTPServerRequest req, HTTPServerResponse res, HTTPServerErrorInfo err)
	{
		if (err.code == 404)
		{
			string error = "404: You've made a wrong turn";
			renderPage!("error.dt", error)(req, res);
		}
		else
		{
			string error = text(err.code);
			renderPage!("error.dt", error)(req, res);
		}
	}


	settings.errorPageHandler = &handleError;

	log("Listening for requests");
	listenHTTP(settings, router);
}
