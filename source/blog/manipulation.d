module blog.manipulation;

import blog.post;
import blog.database;
import std.base64;
import utils.log;
import utils.config;
import std.conv;
import std.datetime.systime;
import std.stdio;


/// Create a post
bool simpleCreatePost(string title, string subtitle, string creator, string post, string overrideDate)
{
    log("creating post: ", title, ", ", subtitle, ", ", creator, ", ", post);
    if (config is null)
        config = new SiteConfig("reece.ooo.json");

    dbConnect();

    string name = title;
    string description = subtitle;
    string author = creator;
    string content = post;

    string strid = config.lookup("database", "id");
    int id = to!int(strid);
    config.write("database", "id", id+1);
    string url = Base64URL.encode(cast(ubyte[])title);
    string date;
    if (overrideDate.length == 0)
        date = "[ " ~ Clock.currTime.toSimpleString ~ " ] ";
    else
        date = overrideDate;
    return insertPost!(name, date, description, content, url, author, id);
}


BlogPost[] getAllPosts()
{
    dbConnect();
    return postQuery!()();
}


