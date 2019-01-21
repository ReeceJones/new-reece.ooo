module blog.user.captcha;

import std.net.curl;
import std.json;
import std.conv;
import std.stdio;
import std.string;
import utils.config;

SiteConfig config;

/// Submit a captcha request
bool submitCaptchaRequest(string captcharesponse)
{
    if (config is null)
        config = new SiteConfig("reece.ooo.json");

    string secret = config.lookup("recaptcha", "secret");

    //https://www.google.com/recaptcha/api/siteverify?secret=$your_secret&response=$client_captcha_response&remoteip=$user_ip
    auto result = parseJSON(get("https://www.google.com/recaptcha/api/siteverify?secret=" ~ secret ~ "&response=" ~ captcharesponse));

    return to!bool(result["success"].toString);//result["success"].type == JSONType.true_;
}
