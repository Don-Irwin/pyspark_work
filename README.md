## Background -- How slow is Python, and is "everything Microsoft" bad?

I love Python.  It is slow, though.  Just how slow is it compared to other languages?  -- In this case we compare it to .Net Core / C#.

It comes as no news to many that Windows is not a good platform for the development of serious systems.

It's expensive to license, it's internals are clunky, its architecture is archane, it's security is poor, and its interfaces are proprietary and non-standard.

MacOS is a little better, but it's still not as clean as Linux, and its the M1/M2 chips do not always play well with 

By contrast, Linux / BDS etc, are beautiful systems.  Not withstanding their quirks they are efficient, lightweight, and power the internet, big data, the internet of things, and now Data Science AI and ML.

Some of Microsoft's offerings are not without their benefits.  .Net Core (Open source .Net Framework that runs on Linux) is arguable a better platform than Java, in that it is fast, does not rely on a runtime, and is less bloated.  -- Best of all, it is free.

## System Requirements

Linux/Ubutu, Bash, Python, Docker, .Net Core (C#)

![Depdendencies](artifacts/images/dependencies.png)

## The Sequence

With this very simple project, we generate a data file that is 1GB large in python.

We then generate the exact same data file using C# (Running within a docker container so as not to complicate our systems deployments).


