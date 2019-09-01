module utils.config;

import std.stdio;
import std.json;
import utils.log;
import std.algorithm;
import core.thread;
import std.conv;

public SiteConfig config;

/// A class that can be used to store certain config values
class SiteConfig
{
public:
    /// Constructs SiteConfig object
    this(string filePath)
    {
        this.filePath = filePath;
    }
    /**
    Lookup for a specified value within the config file.
    Params:
        section - The section that the key is in. This is used to differentiate between different config values.
        key - The key that we want to retrieve the value of.
    Returns: The value as a string.
    */
    string lookup(string section, string key)
    {
        while (locked) Thread.sleep(dur!"msecs"(5));
        locked = true;
        scope(exit) locked = false;
        // reopen the file
        config.reopen("r");
        // close on scope exit
        scope(exit) 
        {
            config.close();
        }
        // read the file contents into a buffer
        string fileBuffer;
        file.byLine.each!(ln => fileBuffer ~= ln );

        // parse the json, and return the value
        try
        {
            auto json = parseJSON(fileBuffer);
            return json[section][key].str;
        }
        catch (JSONException jex)
        {
            log("json parsing error: " ~ jex.msg);
        }
        return ""; // return something
    }
    /**
    Set a specified config value.
    Params:
        section - The section of the config.
        key - The key of the section.
        value - The value.
    Returns: nothing
    */
    void write(T)(string section, string key, T value)
    {
        while (locked) Thread.sleep(dur!"msecs"(5));
        locked = true;
        scope(exit) locked = false;
        config.reopen("r");
        // read the file contents into a buffer
        string fileBuffer;
        file.byLine.each!(ln => fileBuffer ~= ln );

        config.close();
        // parse the json, and return the value
        try
        {
            auto json = parseJSON(fileBuffer);
            json[section][key] = JSONValue(value.text);
            // now we rewrite back to the file
            config.reopen("w");
            scope(exit) config.close();
            file.write(json.toPrettyString);
            
        }
        catch (JSONException jex)
        {
            log("json parsing error: " ~ jex.msg);
        }
    }
    /// Check to see if the config is locked.
    bool getLocked()
    {
        return locked;
    }
private:
    /// Reopen the file with mode
    void reopen(string mode)
    {
        file = new File(filePath, mode);
    }
    /// Close the file
    void close()
    {
        file.close();
    }
    File* file;
    string filePath;
    alias config = typeof(this);
    bool locked;
}


