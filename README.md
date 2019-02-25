What is Goper2Redis?
===

Redis recently introduced support to talk the Gopher protocol. Yes, that
protocol that in the '90s used to be the alternative to the web and now
is almost forgotten. You can read more info about Redis and Gopher
here [in the antirez's blog post](http://antirez.com/news/127).

For the documentation about the Redis Gopher implementation please
check the Redis official doc, specifically the
[Gopher protocol](https://redis.io/topics/gopher) page.

However the raw Redis implementation is able to serve Redis keys using
the Gopher protocol. If you want to create your own "Gopher hole", i.e.
your site with your own content served via the Redis Gopher implementation
(in that specific case at least), you need some kind of authoring tool.

This Ruby script, `gopher2redis.rb`, converts a directory and its
subdirectories, with the text, gif, and binary files it contains, into
a Redis key structure that can be served via the Redis Gopher implementation.

## Creating your Gopher hole

Gopher sites are listings that point to other nested listings of
resources or to files that can be loaded as text-only documents to read, or
as binary files to download or GIF images to visualize.

To create your Gopher hole (i.e a site inside the Gopher
universe), create a directory somewhere, with subdirectories if you want
to have some tree-like organization of your content, which is the Gopher way.

Every file that contains a "-" character inside, like `0000-Who_Am_I.txt`,
will be part of the content generated in the Redis server. The part
before the "-" is used to sort the listing, and is not shown in
the final Gopher site. The underscores are converted into spaces.

For instance if I put the following files:

    0001-My_Document_is_here.txt
    0000-README.txt
    0003-cat.gif

What I'll see in the final Gopher site is a listing like this:

    README.txt
    My Document is here.txt
    cat.gif

Sometimes it is useful to show the content in reverse order, for instance
you may take a blog in your Gopher hole (that is a **phlog** in Gopher slang),
and start every post with the date like:

    2019.02.05-5 Feb 2019: Programming_in_Ruby.txt
    2019.02.04-4 Feb 2019: Today_strange_journey.txt

and other files with similar names. In a blog it makes sense to show the last
written post as the first entry. To have such effect create an empty file
called `REVERSE` in the directory if you want the listing to be sorted in the
reverse order.

## File extensions

The extension of the file selects the "type" of item in the Gopher menu
for that file: if it is a text file, a binary file, a gif, an image and
so forth. Here is the current map:

* zip, bin, gz, tgz, o: binary files
* gif: GIF file
* jpg, jpeg, png: Image file
* html, htm: HTML file
* link: Gopher link file (see later)
* info: Some text that will be put inline into the listing as "info" fields
* i: Same as .info but the filename itself is rendered as "info" field
* All the other extensions, such as txt, c: plain text files

By default everything is a text file if not expressly specified by
a different extension. In Gopher text files are the content users want
to see.

## Links

Sometimes you want to link other Gopher sites from your site. In order
to create a Gopher link in your listings, create a file named
`0004-Also_visit_this.link` site (.link extension) containing a Gopher URI like:

    gopher://gopher.somesite.xyz

Or

    gopher://gopher.somesite.xyz:99/0/resource

And so forth. If you specify a given resource in another Gopher server, make
sure that the path includes the resource type, like the `/0/` part in the
URI above.

## Nested directories

You can create all the nested directories you want: they'll be
processed recursively and create other nested menu items.

## Usage

Typical usage is like so:

    ./goper2redis.rb --host 127.0.0.1 --port 70 \
                     --root /Users/Alice/mygopherhole \
                     --localhost gopher.alicesite.net --localport 70

The `--host` and `--port` options tell the program how to connect to
Redis in order to change its content (WARNING: don't write to the wrong
Redis server for an error).

The `--root` option is used in order to specify which directory (and nested
directories) you want to load into Redis for your Gopher site.

Finally the `--localhost` and `--localport` options are used to tell the
utility in which host and port the public Redis Gopher service will run, so that
the utility can generate the Gopher references in the listings to point to
the right hostname and port.

For instance if your public gopher server will be `gopher.myserver.xyz`,
specify that. To test this program locally use `localhost`.

For other options please use the `--help` switch.

## Example of directory structure to render as a Gopher site

This repository contains an `example-gopherhole` directory that contains a few
files that will render in a site you can display with a Gopher client. You can 
explore the directory to check how it is assembled.  Follow these steps if you
want to render the site into your local Redis instance and view it with
`lynx` as the Gopher client:

* Start a Redis instance, latest `unstable` branch (or any Redis version 6 if already released -- at the time of writing it's alpha code), with the `--gopher-enabled yes` option in the command line, or with the same option inside `redis.conf`.
* Translate the example Gopher hole directory into the Redis dataset using the gopher2redis.rb script: `./goper2redis.rb --host 127.0.0.1 --port 6379 --root ./example-gopherhole --localhost localhost --localport 6379`
* See the result with `lynx gopher://localhost:6379`

Note that this time we are using port 6379 which is not the default Gopher port.
If you want to use the default port, that is 70, run Redis using such port (but you have to run it as a root user, or with alternative methods to give the process access to the lower TCP ports), and change the above command line as needed. If you plan to run such setup in production, make sure to read the next section about securing your environment.

## Configuring and securing Redis

Warning: even if in Gopher mode, Redis will continue to serve normal commands:
make sure to set a password using the `requirepass` option. Also make sure
to set the `gopher-enabled` option to yes in the Redis configuration, otherwise
the server will not talk the Gopher protocol.

Once you set a password in your Redis instance, you can use the `--pass`
gopher2redis option in order to write the new site content using the
Redis clients authentication.
