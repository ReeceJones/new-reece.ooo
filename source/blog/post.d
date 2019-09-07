module blog.post;

/// Structure representing a blog post.
struct BlogPost
{
    string date         = "unknown date";   /// Date that the blog post was posted
    string name         = "unknown title";  /// Name of the blog post
    string description  = "no description"; /// Description of the blog post
    string content      = "no content";     /// Actual content of the blog post
    string url          = "";               /// Blog post url
    string author       = "no author";      /// Author of the blog post
    Comment[] comments  = [];               /// The comments on a post
}

struct Comment
{
    string author;
    string content;
    int context;
    Comment[] replies;
}
