module blog.database;

import vibe.db.mongo.mongo;
import std.algorithm;
import std.range;
import utils.log;
import blog.post;
import blog.user.user;
import blog.stats.stat;

import std.stdio;

private
{
    MongoClient mongoClient;
    MongoCollection users;
    MongoCollection blogs;
    MongoCollection stats;
}

/// Connect to the mongo database
public void dbConnect()
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
    auto queryResult = blogs.find(query);
    // now we fill out the post structs
    BlogPost[] posts;
    foreach(document; queryResult)
    {
        BlogPost post;
        static foreach(i, member; __traits(allMembers, BlogPost))
        {
            // pragma(msg, "post." ~ __traits(allMembers, BlogPost)[i] ~ " = cast(" ~ typeof(__traits(getMember, BlogPost, __traits(allMembers, BlogPost)[i])).stringof ~ ")document[\"" ~ __traits(allMembers, BlogPost)[i] ~ "\"];");
            mixin("post." ~ __traits(allMembers, BlogPost)[i] ~ " = cast(" ~ typeof(__traits(getMember, BlogPost, __traits(allMembers, BlogPost)[i])).stringof ~ ")document[\"" ~ __traits(allMembers, BlogPost)[i] ~ "\"];");
        }
        posts ~= post;
    }
    posts.sort!((a,b) => a.id > b.id);
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
    blogs.insert(Bson([
        "date" : Bson(post.date),
        "name" : Bson(post.name),
        "id"   : Bson(cast(int)post.id),
        "description" : Bson(post.description),
        "content" : Bson(post.content),
        "url" : Bson(post.url),
        "author" : Bson(post.author)
    ]));
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

public bool updatePost(string url, string title, string description, string content)
{
    bool exists = !blogs.find(Bson(["url" : Bson(url)])).empty;
    if (exists == false)
        return false;
    auto bp = postQuery!url()[0];
    blogs.update(
        Bson(["name" : Bson(bp.name)]),
        Bson([
        "date" : Bson(bp.date),
        "name" : Bson(title),
        "id"   : Bson(cast(int)bp.id),
        "description" : Bson(description),
        "content" : Bson(content),
        "url" : Bson(bp.url),
        "author" : Bson(bp.author)
    ]));
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

