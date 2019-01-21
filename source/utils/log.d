module utils.log;

import std.stdio;
import std.datetime.systime;

/// Write to our logfile, writeln stile
/// Also logs the time the log is written for a specific line
public void log(T...)(T param)
{
    auto timestamp = "[ " ~ Clock.currTime.toSimpleString ~ " ] ";
    File(LOGFILE, "a").writeln(timestamp, param);
}

private
{
    // our log file
    enum LOGFILE="site-access.log";
}