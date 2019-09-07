# reece.ooo
Hello there internet passer-byer, this here repository contains all of the code for my website [reece.ooo](https://reece.ooo). The entire website is written using the vibe.d library, a web framework written in D that employs meta-programming to create a high performant, dynamic webserver. The bulma.io css library is also used for the front end simply because it looks nice and is easy to use (I'm not much of a web programmer, so it works fine enough for me).
## features
Some of the features this site current includes are:
+ Blog system that contains everthing needed except comments (haven't gotten around to it yet).
+ User authentification sytsem.
+ Home page with links n' stuff.
+ Logs statistics of page loads/requests.
I know, it's not that much yet, but I hope for this to be the base of my website for the future. After many iterations from awful PHP webpages to horrendous CSS hacks, this site is by far the best in terms of style and design.
## cool things
I don't know why you even care about this, but here are some of the really cool things with this site.
1. Uses MongoDB. Revolutionary, I know. I'm not much of an expert at SQL, but I do understand JSON very well and MongoDB uses JSON documents to store and represent data so it was a pretty obvious choice for me especially since I really am not doing anything complicated with this site.
2. Insane amount of metaprogramming on the backend. Serisouly guys, the backend is completely nuts. I read a single struct at compile time, and the entire backend adjusts to support the fields of the struct. I can simply add a new field like `comments` to the struct, and the backend would support it without any additional modification to the backend. I love it.
3. vibe.d. I like vibe.d. It's relatively simple. It runs D code to make your pages dynamic. What more do you want from me?!?!
