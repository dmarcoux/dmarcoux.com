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

There are many backup solutions available online. I had a few criteria to guide
my decision:

- Based in Europe, since this is where live.
- Reliability
- Resilience
- Environmental impact
- Pricing
- Have a S3-compatible API to ease automation
- Availability of cold storage for long term archival

With this in mind, this is why I went with [Scaleway](https://www.scaleway.com/)
for their *Scaleway Object Storage* and *Scaleway Glacier* products.

Backing up my music involves two steps, first with
[rclone](https://rclone.org/). It is configurable with `rclone config`. The
configuration is encrypted with a password stored in my password manager. This
is how the remote I use is configured in *rclone*:

{{< highlight plaintext >}}
Remote "scaleway-storage-fra"

- type: s3
- provider: Scaleway
- access_key_id: MY_ACCESS_KEY_ID
- secret_access_key: MY_SECRET_ACCESS_KEY
- region: fr-par
- endpoint: s3.fr-par.scw.cloud
- acl: private
- storage_class: ONEZONE_IA
{{< / highlight >}}

This remote is for buckets in the Paris region and by default, it will store
files in a single data center. The redundancy from extra data centers isn't
needed since I also put everything on *Scaleway Glacier*.

Then it's as easy as running this to copy my music to my bucket on *Scaleway*:

{{< highlight bash >}}
rclone copy -P ~/music scaleway-storage-fra:my-music-collection
{{< / highlight >}}

`~/music` is the folder where my music is located, after it has been processed
by *beets*. `scaleway-storage-fra` is the remote in *rclone*, then
`my-music-collection` is the bucket name on *Scaleway Object Storage*.

Finally, I use `aws-cli2` to sync my bucket from *Scaleway Object Storage* to
another bucket from *Scaleway Glacier*.

I avoid storing credentials in plain text in `~/.aws/credentials`, instead
passing them inline in environment variables. I have an alias
([scw](https://github.com/dmarcoux/dotfiles/blob/a9b5425c4649674a0700bf97a04bb87c99c4f153/home-manager/scaleway.nix#L53))
to achieve this without typing again and again those environment variables.

<!-- markdownlint-disable -->
{{< highlight bash >}}
scw s3 sync s3://my-music-collection s3://my-music-collection-glacier --storage-class GLACIER
{{< / highlight >}}
<!-- markdownlint-enable -->

`my-music-collection` is the bucket on *Scaleway Object Storage*, while
`my-music-collection-glacier` is the bucket on *Scaleway Glacier*. Do not forget
to pass the `GLACIER` storage class, otherwise this is going to store everything
in *Scaleway Object Storage*.

## Getting My Music Collection To My Phone

My phone's storage can be expanded via a SD card, so this is what I went with.
To get my music collection onto the SD card, I either take it out and put it in
my computer. This is rather cumbersome as I need to take out the battery every
time. I usually rely on the [FolderSync app](https://foldersync.io/) on Android
to easily sync my bucket on *Scaleway Object Storage* to my phone. This is
especially convenient when only transferring a few songs.

This is how I configure *FolderSync* to work with *Scaleway*.

### On Scaleway

I create an API key, then a policy for it. It can be restricted to only
*Scaleway Object Storage* and *Scaleway Glacier*.

### In FolderSync

Create an account with the *Access key ID* and the *Secret access key*. Those
fields refer to the API key on *Scaleway*. Afterwards, the *Server address* and
*Region* refer to the bucket on *Scaleway Object Storage*, not on *Scaleway
Glacier* since this would take much longer to download the files as they have to
be restored. As an example for a bucket in the Paris region, the *Server
address* would look like `s3.fr-par.scw.cloud/my-bucket-name` and the *Region*
is `EUParis`.

## Final Countdown

That's it, I hope this helped you. How do you setup your digital music
collection? Let me know what you think through my *Contact Me* form.
