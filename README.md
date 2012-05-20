## What's this?

This is the *Next-Gen Deck*, a tool that makes it very easy to QC your
[Next-Gen sequencing](http://en.wikipedia.org/wiki/DNA_sequencing) data.

## I want to know more

The *Next-Gen Deck* is divided in two parts: the
[Frontend](https://github.com/drio/next-gen-deck/tree/master/frontend)
and the
[Backend](https://github.com/drio/next-gen-deck/tree/master/backend).
The backend extracts data from
[bam](http://samtools.sourceforge.net/SAM1.pdf) files and loads them
in [redis](http://redis.io/). The frontend is a web application that
queries the redis server to visualize the different metrics available
for the different bams. This makes it very easy to find potential issues
and keep track of your data.

## Backend

The backend is divided in two parts. The first part is a tool
that extracts metrics from a [bam](http://samtools.sourceforge.net/SAM1.pdf)
and creates csv files with the different metrics (Mapped reads, duplicate reads,
insert size values for the pairs, mapping qualities, etc ...). This part is
written in C using [samtools API](http://samtools.sourceforge.net/samtools-c.shtml).

Once the csvs are computed per each
[bam](http://samtools.sourceforge.net/SAM1.pdf) we can use the second tool to
store all these information in the [redis](http://redis.io) database.

Notice that the paths to the bams are used to keep track of different projects
or subprojects. So we can have a filesystem layout like this:

```bash
$ pwd
/tmp/bams
$ mkdir project1
$ mkdir project2
$ ln -s /some_path/bam1 ./project1/
$ ln -s /some_path/bam2 ./project2/

$ ln -s /other_path/bam1 ./project2/
$ ln -s /other_path/bam2 ./project2/
$ ln -s /other_path/bam3 ./project2/
```

## Frontend

The frontend is basically a web app that pulls data from redis and visualizes
the different metrics for all the different events(bams) available.

At its heart, the app uses [d3](http://d3js.org/), a data driven javascript
library for manipulating documents based on data.

The main plots show you dotplots of the percentage of mapped reads and
duplicates for all your events so you can quickly look for errors.

The *Next-Gen Deck* will load all your events, but very soon I am going to
add support for filtering based on the name of your events so you can focus
on specific projects. Actually that's something that can be done very easily
by just dumping data for the projects you are interested on.


## Dependencies

The C tool uses the [samtools API](http://samtools.sourceforge.net/samtools-c.shtml).
The ruby tool uses libraries that come standard with ruby. You just need a
[ruby](http://www.ruby-lang.org/en/) interpreter.

We dump all the metrics in [redis](http://redis.io). Redis does not accept
http queries natively. Luckily, there is a very lightweight tool called
[wedis](https://github.com/nicolasff/webdis) that fixes that.

The frontend is a web app. It uses html, css and javascript. From the
[d3](http://d3js.org/) site:

```
only works in “modern” browsers, which generally means everything except IE8 and below
```

## Usage

First, clone the project and compile the backend tool:

```bash
git clone git@github.com:drio/next-gen-deck
cd next-gen-deck/backend ; make
```

You probably want to put the backend dir in your PATH.

Now create your the structure for your bams. Remember, the directory path will be
stored so you can focus on specific projects and sub-projects.

Once you have that in place, run ngd-stats against all your bams. You probably
want to run those in parallel. Most likely you have all these in a HPC cluster.

Now we should have all the data extracted in csv format per each of the bams.

It is time to load all that to the redis server. Make sure that you have redis
up and running and then run the ruby tool:

```bash
$ cd bams_path
$ load2redis.rb
>> Loading csvs ...
>> Dumping into redis ...
```

That shouldn't take too much time. It is basically sucking all the csvs and
dumping them to [redis](http://redis.io).

Now we are ready to use the frontend.

Make sure that [wedis](https://github.com/nicolasff/webdis) is up and running.

We haven't kept the js dependencies in this repo, but I have a convenient
makefile in frontend/ that will download them for you. Just run:

```
$ cd frontend
$ make
```

Now, fire up your favorite browser and point it to the index.html in
the frontend directory.

You should see the dotplot of the % of dups for your data. Click any of the
bams (dots) and detail metrics for that bam will show up. Repeat as necessary.

## TODO

There is a lot of things that can be done from here. Feel free to send me
pull requests with new features or just request them in the ticket system.
Any type of feedback would be very welcome.
