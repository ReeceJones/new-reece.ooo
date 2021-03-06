module blog.database;

import vibe.db.mongo.mongo;
import std.algorithm;
import std.range;
import utils.log;
import blog.post;
import blog.user.user;
import blog.stats.stat;
import vibe.d: filterMarkdown, MarkdownFlags;

import std.stdio;

private
{
    MongoClient mongoClient;
    MongoCollection users;
    MongoCollection blogs;
    MongoCollection stats;
}

// Connect to the mongo database
shared static this()
{
    mongoClient = connectMongoDB("127.0.0.1");
    users = mongoClient.getCollection("reece-ooo.users");
    blogs = mongoClient.getCollection("reece-ooo.blogs");
    stats = mongoClient.getCollection("reece-ooo.stats");
}

/**
Query BlogPost given the specified parameters. These parameters are independent of the initialization values of the BlogPost structure, so there is no need to create a query that uses all members of the BlogPost structure.
Params:
    ALIASES - The parameters of the query. These aliases' names must be according to the member name of the blog post structure, i.e. image won't work, but date will
Returns: An array of BlogPost that meet the specified query.
*/
public BlogPost[] postQuery(ALIASES...)()
{
    // construct our query using the provided aliases, and their values
    Bson[string] query;
    static foreach(i; ALIASES.length.iota)
    {
        query[__traits(identifier, ALIASES[i])] = Bson(ALIASES[i]);
    }
    auto posts = blogs.find!(BlogPost)(query).array;

    posts.sort!((a,b) => a.date > b.date);
    return posts;
}

/**
Insert a post based on a given set of queries.
<strong>Warning:</strong> Missing fields will be passed as their defaults. This means that unless there is good reason, there should always be all of the members from BlogPost.
Params:
    ALIASES - Members used to construct the BlogPost. Values and identifiers are derived using __traits.
Returns: nothing
*/
public bool insertPost(ALIASES...)()
{
    BlogPost post;
    static foreach(i, member; ALIASES)
    {
        // pragma(msg, "post." ~ __traits(identifier, ALIASES[i]) ~ " = ALIASES[i];");
        mixin("post." ~ __traits(identifier, ALIASES[i]) ~ " = ALIASES[i];");
    }
    const bool exists = !blogs.find(Bson(["name" : Bson(post.name)])).empty;
    //could not create user
    if (exists == true)
        return false;
    
    // user doesn't exist, so we continue as normal
    blogs.insert(post);
    return true;
}

/// insertPost, but ensures that all ALIASES are a part of the BlogPost structure.
public void insertPostSafe(ALIASES...)()
{
    // make sure we have the same number of members
    static if (ALIASES.length != __traits(allMembers, BlogPost).length)
        static assert(0, "insertPostSafe error: incorrect amount of parameters passed to the function. ALIASES:\n\t" ~ __traits(allMembers, ALIASES));
    // check to see if there are any members that are not a part of the BlogPost structure
    static foreach(member; ALIASES)
    {
        static if (!__traits(hasMember, BlogPost, __traits(identifier, member)))
            static assert(0, "insertPostSafe error: member \"" ~ __traits(identifier, member) ~ "\" not a part of the BlogPost structure.");
    }
    insertPost!(ALIASES)();
}

public bool updatePost(string url, string title, string description, string content, string date)
{
    bool exists = !blogs.find(Bson(["url" : Bson(url)])).empty;
    if (exists == false)
        return false;
    auto bp = postQuery!url()[0];
    bp.description = description;
    bp.content = content;
    bp.date = date.length == 0 ? bp.date : date;
    bp.name = title;
    blogs.update(Bson([
        "url": Bson(url)
        ]), bp);

    return true;
}

public void removePost(string url)
{
    blogs.remove( Bson(["url" : Bson(url) ]) );
}

public User[] userQuery(ALIASES...)() 
{
    // construct our query using the provided aliases, and their values
    Bson[string] query;
    static foreach(i; ALIASES.length.iota)
    {
        query[__traits(identifier, ALIASES[i])] = Bson(ALIASES[i]);
    }
    auto queryResult = users.find(query);
    // now we fill out the post structs
    User[] users;
    foreach(document; queryResult)
    {
        User user;
        static foreach(i, member; __traits(allMembers, User))
        {
            // pragma(msg, "post." ~ __traits(allMembers, BlogPost)[i] ~ " = cast(" ~ typeof(__traits(getMember, BlogPost, __traits(allMembers, BlogPost)[i])).stringof ~ ")document[\"" ~ __traits(allMembers, BlogPost)[i] ~ "\"];");
            mixin("user." ~ __traits(allMembers, User)[i] ~ " = cast(" ~ typeof(__traits(getMember, User, __traits(allMembers, User)[i])).stringof ~ ")document[\"" ~ __traits(allMembers, User)[i] ~ "\"];");
        }
        users ~= user;
    }
    return users;
}

public bool insertUser(ALIASES...)()
{
    User user;
    static foreach(i, member; ALIASES)
    {
        mixin("user." ~ __traits(identifier, member) ~ " = ALIASES[i];");
    }
    const bool exists = !users.find(Bson(["username" : Bson(user.username)])).empty;
    //could not create user
    if (exists == true)
        return false;
    
    // user doesn't exist, so we continue as normal
    users.insert(Bson([
        "username" : Bson(user.username),
        "password" : Bson(user.password),
        "admin"   : Bson(cast(bool)user.admin)
    ]));
    return true;
}

public bool insertUserSafe(ALIASES...)()
{
    // make sure we have the same number of members
    static if (ALIASES.length != __traits(allMembers, User).length)
        static assert(0, "insertUserSafe error: incorrect amount of parameters passed to the function. ALIASES:\n\t" ~ ALIASES);
    // check to see if there are any members that are not a part of the BlogPost structure
    static foreach(i, member; ALIASES)
    {
        static if (!__traits(hasMember, User, __traits(identifier, ALIASES[i])))
            static assert(0, "insertUserSafe error: member \"" ~ __traits(identifier, ALIASES[i]) ~ "\" not a part of the User structure.");
    }
    return insertUser!(ALIASES)();
}

public Stats[] statsQuery(ALIASES...)() 
{
    // construct our query using the provided aliases, and their values
    Bson[string] query;
    static foreach(i; ALIASES.length.iota)
    {
        query[__traits(identifier, ALIASES[i])] = Bson(ALIASES[i]);
    }
    auto queryResult = stats.find(query);
    // now we fill out the post structs
    Stats[] statslist;
    foreach(document; queryResult)
    {
        Stats stat;
        static foreach(i, member; __traits(allMembers, Stats))
        {
            // pragma(msg, "post." ~ __traits(allMembers, BlogPost)[i] ~ " = cast(" ~ typeof(__traits(getMember, BlogPost, __traits(allMembers, BlogPost)[i])).stringof ~ ")document[\"" ~ __traits(allMembers, BlogPost)[i] ~ "\"];");
            mixin("stat." ~ __traits(allMembers, Stats)[i] ~ " = cast(" ~ typeof(__traits(getMember, Stats, __traits(allMembers, Stats)[i])).stringof ~ ")document[\"" ~ __traits(allMembers, Stats)[i] ~ "\"];");
        }
        statslist ~= stat;
    }
    return statslist;
}

public void updateStatRecord(ALIASES...)(string pageURL)
{
    string url = pageURL;
    auto allstats = statsQuery!(url)();
    if (allstats.length == 0)
    {
        stats.insert(Bson([
            "url": Bson(pageURL),
            "loads": Bson(0)
        ]));
    }
    else
    {
        Stats stat = allstats[0];
        static foreach(i,member;ALIASES)
        {
            mixin("stat."~__traits(identifier, ALIASES[i])~"=cast(" ~ typeof(ALIASES[i]).stringof ~ ")ALIASES[i];");
        }

        stats.update(
            Bson(["url":Bson(pageURL)]),
            Bson([
            "url":Bson(cast(string)url),
            "loads":Bson(cast(int)stat.loads)
            ])
        );
    }
}

