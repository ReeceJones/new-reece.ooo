module blog.stats.page;

import blog.database;
import blog.stats.stat;

/// called when a page is loaded, so that we can store its stats
void statPageLoad(string url)
{
    // we want to increment the pageload counter by one
    auto stats = statsQuery!(url)();
    int loads;
    if (stats.length == 0)
    {
        loads = 0;
    }
    else
        loads = stats[0].loads + 1;
    updateStatRecord!(loads)(url);
}

