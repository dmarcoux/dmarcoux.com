+++
title = "Manage a Music Collection with whipper, beets, Terraform and rclone"
description = """\
                I enjoy listening to music and after cancelling my subscription \
                to a music streaming service, I decided to go back to owning music \
                again. This is how I organize my digital music collection.\
              """
date = "2023-07-31"
updated = "2024-09-27"

[extra.meta]
type = "article"
keywords = "music, music collection, Linux, whipper, beets, Terraform, rclone, Scaleway, FolderSync"

# TODO: This doesn't work with multilingual pages due to the symlink
# aliases = ["how-i-organize-my-digital-music-collection"]
+++

I enjoy listening to music and some time ago after cancelling my subscription to
a music streaming service, I decided to go back to owning music again. I wanted
to listen to my music across multiple devices, so I streamlined my setup until I
was satisfied with it. This is how I organize my digital music collection on a
Linux-based workflow, but the tools are available on Windows and Mac OS. Details
on some concepts might be left out, since this blog post is more of a notebook
for myself to get this out of my head. Anyway, perhaps it can still help out
someone.

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
```bash
docker run -ti --rm --device=/dev/cdrom \
--mount type=bind,source=${HOME}/.config/whipper,target=/home/worker/.config/whipper \
--mount type=bind,source=${HOME}/music-to-import,target=/output \
whipperteam/whipper:0.10.0 cd rip --prompt
```
<!-- markdownlint-enable -->

`--device=/dev/cdrom` refers to the CD drive in my computer.

Both `--mount` options are bound to directories which must exist, otherwise the
command won't work. It's as simple as running `mkdir -p "${HOME}/.config/whipper"
"${HOME}/music-to-import"` to address this.

The first `--mount` is to mount the *whipper* configuration into the *Docker*
container. This configuration was generated with `whipper drive analyze`, so the
same command as above, but by replacing `cd rip` for `drive analyze`. After
executing `drive analyze`, it is also needed to run `drive offset`.

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

```bash
beet import path/to/music/album-1 path/to/music/album-2 (...)
```

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

### Provisioning the Infrastructure with Terraform

While I could create the infrastructure in the *Scaleway* web UI, I always
prefer to achieve this through code. *Terraform*, an Infrastructure as
Code (IaC) tool, is a great fit for this.

What I need is:

- a bucket to store my music collection
- an IAM application with limited privileges to sync my music in the bucket via `rclone`

Let's first write a *Terraform* configuration file named `main.tf`. Be sure to
replace the placeholder `BUCKET_NAME` and the values in `locals`. Remember that
the bucket name must be globally unique, so across all *Scaleway*'s buckets. If
needed, adapt the zone and region.

<!-- markdownlint-disable -->
```terraform
terraform {
  required_providers {
    scaleway = {
      source = "scaleway/scaleway"
    }
  }
  required_version = ">= 0.13"
}

# Documentation: https://registry.terraform.io/providers/scaleway/scaleway/latest/docs
provider "scaleway" {
  zone   = "fr-par-1"
  region = "fr-par"
}

locals {
  # Found at https://console.scaleway.com/iam/users
  # An IAM user which should have access to the bucket if needed, for example
  # via the web UI or the AWS CLI with `aws s3`. It could be the default IAM
  # user, but it does not have to.
  IAM_user_id = "11111111-1111-1111-1111-111111111111"
  # Found at https://console.scaleway.com/project
  project_id = "11111111-1111-1111-1111-111111111111"
}

# IAM application with limited privileges to sync objects in the bucket via `rclone`
resource "scaleway_iam_application" "API-Object_Storage" {
  name        = "API - Object Storage"
  description = "This is to restrict an API key only to the Object Storage buckets"
}

resource "scaleway_iam_policy" "API-Object_Storage" {
  name = "Object Storage - Buckets Read Write - Objects Read Write Delete"
  application_id = scaleway_iam_application.API-Object_Storage.id
  rule {
      permission_set_names = [
          "ObjectStorageBucketsRead",
          "ObjectStorageBucketsWrite",
          "ObjectStorageObjectsDelete",
          "ObjectStorageObjectsRead",
          "ObjectStorageObjectsWrite",
      ]
      project_ids = [
          local.project_id,
      ]
  }
}

# When looking at the state of a resource, its sensitive values will always be masked.
# I still need to store the secret key of the API key in my password manager.
# The command below returns the secret key:
# terraform show -json | jq -r '.values.root_module.resources[] | select(.address=="scaleway_iam_api_key.API-Object_Storage").values.secret_key'
resource "scaleway_iam_api_key" "API-Object_Storage" {
  application_id = scaleway_iam_application.API-Object_Storage.id
}

# Bucket
resource "scaleway_object_bucket" "BUCKET_NAME" {
  name = "BUCKET_NAME"
}

resource "scaleway_object_bucket_acl" "BUCKET_NAME" {
  bucket = scaleway_object_bucket.BUCKET_NAME.name
  acl = "private"
}

resource "scaleway_object_bucket_policy" "BUCKET_NAME" {
  bucket = scaleway_object_bucket.BUCKET_NAME.name
  policy = templatefile("${path.module}/bucket_policy.tftpl", {
    bucket_name = scaleway_object_bucket.BUCKET_NAME.name,
    IAM_user_id = IAM_USER_ID,
    IAM_application_id = scaleway_iam_application.API-Object_Storage.id,
    IAM_application_name = scaleway_iam_application.API-Object_Storage.name
  })
}
```
<!-- markdownlint-enable -->

The bucket policy is in a *Terraform* template file (`bucket_policy.tftpl`).
Since the JSON document of a policy can be sometimes quite large, I find this
approach much easier to reason about than having everything together.

<!-- markdownlint-disable -->
```terraform
${jsonencode({
  "Version": "2023-04-17",
  "Id": "${bucket_name}-policy",
  "Statement": [
    {
      "Sid": "Allow everything in the bucket ${bucket_name} and its objects for my user",
      "Effect": "Allow",
      "Principal": {
        "SCW": "user_id:${IAM_user_id}"
      },
      "Action": "*",
      "Resource": [
        "${bucket_name}",
        "${bucket_name}/*"
      ]
    },
    {
      "Sid": "Grant access to the bucket ${bucket_name} for the application '${IAM_application_name}'",
      "Effect": "Allow",
      "Principal": {
        "SCW": "application_id:${IAM_application_id}"
      },
      "Action": "s3:ListBucket",
      "Resource": "${bucket_name}"
    },
    {
      "Sid": "Allow reads and writes of objects in the bucket ${bucket_name} for the application '${IAM_application_name}'",
      "Effect": "Allow",
      "Principal": {
        "SCW": "application_id:${IAM_application_id}"
      },
      "Action": [
        "s3:PutObject",
        "s3:GetObject"
      ],
      "Resource": [
        "${bucket_name}",
        "${bucket_name}/*"
      ]
    }
  ]
})}
```
<!-- markdownlint-enable -->

For *Terraform* to provision the bucket, it must first authenticate to
*Scaleway*. It's simple, I create an API key for my IAM user and store its
*Access Key Id* and *Secret Key* in my password manager (*1Password*). This
isn't the same API key as the one created above with *Terraform*, it must have
the permissions to create resources for my *Scaleway* account.

By relying on environment variables, I avoid storing secrets on disk. With the
help of [direnv](https://direnv.net/), environment variables are automatically
exported/unexported whenever I enter/leave the directory containing this
`.envrc` file:

```bash
export SCW_ACCESS_KEY="$(op read 'op://reference/to/Access Key Id')"
export SCW_SECRET_KEY="$(op read 'op://reference/to/Secret Access Key')"
```

And now with `terraform init`, followed by `terraform plan`, I ensure that the
bucket would be provisioned as I expect it to. Afterwards, I apply the execution
plan with `terraform apply`.

### Uploading Objects to the Bucket With rclone

Backing up my music on the bucket I created above with *Terraform* involves two
steps. First with [rclone](https://rclone.org/). It is configurable with `rclone
config`. The configuration is encrypted with a password stored in my password
manager. This is how the remotes I use are configured in *rclone*:

```text
[homeserver]
type = sftp
host = MY_HOMESERVER_IP
user = MY_USER

[scaleway-storage-fra-GLACIER]
type = s3
provider = Scaleway
access_key_id = ACCESS_KEY_ID
secret_access_key = SECRET_ACCESS_KEY
region = fr-par
endpoint = s3.fr-par.scw.cloud
acl = private
storage_class = GLACIER
```

The placeholders `ACCESS_KEY_ID` and `SECRET_ACCESS_KEY` both refer to the API
key belonging to the IAM application created above with *Terraform*.

Here's how I upload my music to my home server:

```bash
rclone copy --progress --checksum ~/music homeserver:/path/to/music/directory
```

`~/music` is the folder where my music is located on my computer, after it has
been processed by *beets*. `homeserver` is the remote in *rclone*, followed by
the path to the music directory on my home server.

As for uploading my music to *Scaleway Glacier*, my home server does it daily
with a script containing this:

```bash
rclone copy --progress --checksum ~/music scaleway-storage-fra-GLACIER:my-music-collection
```

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
collection?
