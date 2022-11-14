# Transfer large files via rclone

To transfer large files like shotgun sequencing data, you will not want to download your data and then reupload it to the cluster.
Thankfully, there is an alternative, using the `rclone` package.

## Installation and setup

The initial setup for drive involves getting a token from Google Drive which you need to do in your browser.

First, you need to install `rsync` and `rclone` inside you BioBakery3 conda environment. 
This should have been set up previously, and contain all your other tools for shotgun data analysis.

```bash
# Activate the biobakery3 environment
conda activate biobakery3

# Install rsync and rclone via conda
conda install rsync rclone
```

You can view your rclone configurations by using the command `rclone config`.
The first time you do this, you should see something similar to the following output:

```
No remotes found - make a new one
n) New remote
s) Set configuration password
q) Quit config
n/s/q>
```

Select n, and give the remote a name. In this case, `googledrive`.

```bash
name> googledrive
```

It will come up with the following output:

```
Type of storage to configure.
Enter a string value. Press Enter for the default ("").
Choose a number from below, or type in your own value
{many numbered options...}
```

Select the option for `Google Drive`, which as of writing this document, is number `15`.
You will see the following output:

```
** See help for drive backend at: https://rclone.org/drive/ **

Google Application Client Id
Setting your own is recommended.
See https://rclone.org/drive/#making-your-own-client-id for how to create your own.
If you leave this blank, it will use an internal key which is low performance.
Enter a string value. Press Enter for the default ("").
```

You will then want to follow their instructions and [set up a Google API client ID](https://rclone.org/drive/#making-your-own-client-id).
Not only will this increase performance, but will later give you access to your files.

As per their instructions, it does not matter which Google account you use for the initial set-up, but it cannot be your Monash account.
Unfortunately, as of now, Monash has not granted permission for your account to be used with the Google API.
Therefore, you will need to use a personal account; you will then set it up to use your Monash account for data collection later on.

During the process of creating your __credentials__, it will give you a Client ID and a Client Secret. You will need these to set up `rclone`.
You should save these values somewhere, such as in a .txt file for example, for easy access in case you need them in the future.
In any case, you can always view these values in your Google Cloud Platform account.

Input the Client ID in bash.

```bash
client_id> {your client id}
```
 It will then ask for the secret:
 
```
OAuth Client Secret
Leave blank normally.
Enter a string value. Press Enter for the default ("").
```

Input the Client Secret.

```bash
client_secret> {your client secret}
```

It will then ask you to specify the scope of access for when `rclone` is accessing your drive.

```
Scope that rclone should use when requesting access from drive.
Enter a string value. Press Enter for the default ("").
Choose a number from below, or type in your own value
 1 / Full access all files, excluding Application Data Folder.
   \ "drive"
 2 / Read-only access to file metadata and file contents.
   \ "drive.readonly"
   / Access to files created by rclone only.
 3 | These are visible in the drive website.
   | File authorization is revoked when the user deauthorizes the app.
   \ "drive.file"
   / Allows read and write access to the Application Data folder.
 4 | This is not visible in the drive website.
   \ "drive.appfolder"
   / Allows read-only access to file metadata but
 5 | does not allow any access to read or download file content.
   \ "drive.metadata.readonly"
```

You can always change this later by editing via `rclone config`, but for now, input `1` to give full access (except the Application Data folder).

```bash
scope> 1
```

It will ask you to specify the root folder, but you can leave this blank. 
You can also leave the next input (the Service Account Credentials JSON file path) blank.

It will ask if you want to edit advanced config. You can input `n`.

Then, it will ask if you need to use `remote config`. 
Because you are working remotely on the cluster, the default (auto config) will not work, so therefore you need to select `n`.

It will present you with a link to follow. Log in to this and authorise using your __Monash__ account.

Copy and paste the code Google provides you into the field:

```bash
Enter verification code> {unique Google code}
```

It will ask you if you want to configure this as a Shared Drive (Team Drive).
You can select `n` for now.

It will present you with a summary of the configuration settings. 
Input `y` to confirm this looks correct.

This completes the setup of `rclone`. Input `q` to exit the configuration menu.

## Transferring files

Transferring files in a folder from your Google Drive is simple:

```bash
# Navigate to the folder you want you fastq files to be downloaded to
cd path/to/folder

# Transfer shotgun files (example path)
rclone copy -v --fast-list --max-backlog=999999 --drive-chunk-size=512M \
googledrive:/03_Sequencing_MarslandLab/Australia/NovaSeq/NovaSeq09_Celine_Matt_shotgun/Matt_data .
```

At this stage, the wildcard `*` in filenames is not allowed directly within the path, but typically you will want everything in the shotgun data folder anyway.

If however you do want to select individual files, or a set of files by wildcard `*`, you can use the `--include` flag.
For example, if I wanted all files beginning with `137` (samples for patient 137), I could use the command:

```bash
# Transfer just files beginning with "137" from the example folder above
rclone copy -v --fast-list --max-backlog=999999 --drive-chunk-size=512M --include "137*" \
googledrive:/03_Sequencing_MarslandLab/Australia/NovaSeq/NovaSeq09_Celine_Matt_shotgun/Matt_data .
```

If you wanted to transfer files back to Google Drive from the cluster, you would just invert the directory order and place `googledrive:/` second.
