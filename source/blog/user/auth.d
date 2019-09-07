module blog.user.auth;

import blog.database;
import dauth;
import utils.log;
import blog.user.user;

///
enum UserAuth
{
    AUTH_ERR_PASSWORD = 0,      /// Password is invalid
    AUTH_ERR_DATABASE,          /// Some database error occured
    AUTH_SUCCESS_NORMAL,        /// Password is correct, user is non-admin
    AUTH_SUCCESS_PRIVILAGED     /// Password is correct, user is admin
}

/**
Given a username, and a hashed password, try and authenticate the user
Params:
    username - The username of the user
    password - The password that they entered
Returns: UserAuth enum value 
*/
UserAuth authenticateUser(string username, string password)
{
    auto users = userQuery!(username)();
    if (users.length == 0)
        return UserAuth.AUTH_ERR_DATABASE;
    auto user = users[0];

    if (isSameHash(toPassword(cast(char[])password), parseHash(cast(string)user.password)))
    {
        log("success: user ", username, " logged in. [", user.admin ? "admin":"normal", "]");
        return user.admin ? UserAuth.AUTH_SUCCESS_PRIVILAGED : UserAuth.AUTH_SUCCESS_NORMAL;
    }
    else
    {
        return UserAuth.AUTH_ERR_PASSWORD;
    }
}

/**
Given a username, and a hashed password try and create the user
Params:
    username - The username of the user that we want to create
    pass - The user's password
Returns: UserAuth enum value
*/
UserAuth createUser(string username, string pass)
{
    // make sure that the password meets some basic complexity requirements
    if (pass.length < 8)
        return UserAuth.AUTH_ERR_PASSWORD;

    string password = makeHash(toPassword(cast(char[])pass)).toString();
    bool admin = false;
    auto r = insertUserSafe!(username, password, admin);
    if (r == true)
    {
        return UserAuth.AUTH_SUCCESS_NORMAL;
    }   
    return UserAuth.AUTH_ERR_DATABASE; 
}


