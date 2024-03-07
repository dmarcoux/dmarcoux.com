---
title: "How I Organize My Digital Music Collection on Linux"
date: 2023-07-31T10:43:16+02:00
---

I enjoy listening to music and some time ago after cancelling my subscription to
a music streaming service, I decided to go back to owning music again. I
wanted to listen to my music across multiple devices, so I streamlined my setup
until I was satisfied with it. This is how I organize my digital music
collection on a Linux-based workflow. Details on some concepts might be left
out, since this blog post is more of a notebook for myself to get this out of my
head. Anyway, perhaps it can still help out someone.

## Ripping CDs With whipper

The albums I own are partly in a digital format while others are CDs. I want all
my music to be in [FLAC](https://en.wikipedia.org/wiki/FLAC), a lossless format
to have the best sound quality possible and even though this takes more storage
space than a lossy format like MP3, I don't care since storage is cheap nowadays.

I rely on [whipper](https://github.com/whipper-team/whipper) to accurately rip
my CDs. To avoid needing to worry about the required dependencies for *whipper*,
I use its [*Docker* image](https://hub.docker.com/r/whipperteam/whipper)
provided by the developers themselves.

Here is an example of how I use *whipper* with *Docker*:

<!-- markdownlint-disable -->
{{< highlight bash >}}
docker run -ti --rm --device=/dev/cdrom \
--mount type=bind,source=${HOME}/.config/whipper,target=/home/worker/.config/whipper \
--mount type=bind,source=${HOME}/music-to-import,target=/output \
whipperteam/whipper:0.10.0 cd rip --prompt
{{< / highlight >}}
<!-- markdownlint-enable -->

`--device=/dev/cdrom` refers to the CD drive in my computer.

The first `--mount` is to mount the *whipper* configuration into the *Docker*
container. This configuration was generated with `whipper drive analyze`, so the
same command as above, but by replacing `cd rip` for `drive analyze`.

The second `--mount` is where *whipper* will output the songs from CDs it ripped.

As for `whipperteam/whipper:0.10.0`, this is using the latest *whipper* version at
the time of writing.

Finally, `cd rip` is the command passed to *whipper*. It would be the same as
running `whipper cd rip` if *whipper* was installed as a package on my computer.
As for the `--prompt` flag, this is for *whipper* to let me decide which CD
release to pick if somehow multiple matches are available. This happens often
for CDs with releases in multiple countries or with various editions like deluxe
or what not.

## Cataloging Music With beets

I am using [beets](https://beets.io/) since I haven't found another software as
good to correctly catalog my music. It takes care of handling the metadata
that it fetches from [MusicBrainz](https://musicbrainz.org/). One cool thing
about *beets* is how flexible it is with its various plugins.

Command example to import music into my music collection:
{{< highlight bash >}}
beet import path/to/music/album-1 path/to/music/album-2 (...)
{{< / highlight >}}

For details on how I configured *beets* and some of its plugins, my configuration
is in my
[dotfiles](https://github.com/dmarcoux/dotfiles/blob/09696224f416e37c57233c09e08e0b3267ddf332/home-manager/beets.nix).

## Backing Up My Music Collection

Beside having my music both on my computer and my phone, I also back it up on my
home server and a cloud provider.

There are many cloud providers available. I had a few criteria to guide my
decision:

- Based in Europe, since this is where live.
- Reliability
- Resilience
- Environmental impact
- Pricing
- Have a S3-compatible API to ease automation
- Availability of cold storage for long-term archival

With this in mind, this is why I went with the cloud provider
[Scaleway](https://www.scaleway.com/) for *Scaleway Glacier*, a subset of their
*Scaleway Object Storage* product. It offers a *cold* storage solution for
long-term archival in the Paris region. This is perfect for my needs.

Backing up my music involves two steps, first with
[rclone](https://rclone.org/). It is configurable with `rclone config`. The
configuration is encrypted with a password stored in my password manager. This
is how the remotes I use are configured in *rclone*:

{{< highlight plaintext >}}
[homeserver]
type = sftp
host = MY_HOMESERVER_IP
user = MY_USER

[scaleway-storage-fra-GLACIER]
type = s3
provider = Scaleway
access_key_id = MY_ACCESS_KEY_ID
secret_access_key = MY_SECRET_ACCESS_KEY
region = fr-par
endpoint = s3.fr-par.scw.cloud
acl = private
storage_class = GLACIER
{{< / highlight >}}

Here's how I upload my music to my home server:

{{< highlight bash >}}
rclone copy --progress --checksum ~/music homeserver:/path/to/music/directory
{{< / highlight >}}

`~/music` is the folder where my music is located on my computer, after it has
been processed by *beets*. `homeserver` is the remote in *rclone*, followed by
the path to the music directory on my home server.

As for uploading my music to *Scaleway Glacier*, my home server does it daily
with a script containing this:

{{< highlight bash >}}
rclone copy --progress --checksum ~/music scaleway-storage-fra-GLACIER:my-music-collection
{{< / highlight >}}

This time, *rclone* uploads to the `scaleway-storage-fra-GLACIER` remote which
stores files in *Scaleway Glacier*. `my-music-collection` is the bucket name on
*Scaleway Glacier*.

## Getting My Music Collection To My Phone

My phone's storage can be expanded via a SD card, so this is what I went with.
To get my music collection onto the SD card, I could take it out and put it in
my computer. This is rather cumbersome as I need to take out the battery every
time. Instead, I usually rely on the [FolderSync app](https://foldersync.io/) on
Android to easily sync my music from my home server to my phone while I'm in my
local network. This is especially convenient when only transferring a few songs.

And yes, I did give a try to the good old USB cable, but it's not reliable on
Linux. Somehow, my phone isn't always detected by the OS and when it does, it
sometimes gets disconnected for no apparent reason. Oh well... FolderSync it is
then!

### How To Configure FolderSync

On my home server, I have a user with read-only access. In FolderSync, create an
account for SMB with this user's username and password. Enter the IP address of
my home server, then the SMB share name where my music collection is stored.
Pick SMB3 and enable *Require encryption*.

Afterwards, create a folder pair with the sync type *To local folder*. Set the
remote folder to the folder where my music collection is stored on my home
server. As for the local folder, it is where I want to have my music collection
on my phone, so as long as it's on the SD card, it's all good.

Now for the *Sync options* of the folder pair, choose *Never* for the option
*Overwrite old files* and choose *Use remote file* for the option *If both local
and remote file have been modified*.

Finally, under *Advanced*, enable *Use MD5 checksums*.

## Final Countdown

That's it, I hope this helped you. How do you setup your digital music
collection? Let me know what you think through my *Contact Me* form.
