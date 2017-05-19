## Pipeline for ingesting S3 geotiffs into an GCS and Earth Engine

These are the notes documenting how to move tif data from S3 or Google cloud storage
into Image Collections in Google's Earth Engine platform.

### Requirements

[AWS command line interface](http://docs.aws.amazon.com/cli/latest/userguide/installing.html)

 [google cloud SDK](https://cloud.google.com/sdk/?utm_source=google&utm_medium=cpc&utm_campaign=2017-q1-cloud-emea-gcp-bkws-freetrial&gclid=CLK_keLP-dMCFQeeGwod0lkISw)

[Google Earth Engine Python API](https://developers.google.com/earth-engine/command_line)

### Procedure

S3 Bucket --> Google Cloud Storage --> to Google Earth Engine

## S3

If you need to move files between buckets, for example lots of tif files:

```bash
aws s3 cp s3://my_bucket/folder_path/ s3://other_bucket/ --recursive --includes "*.tif"
```

If you want to see the size of a bucket contents in S3, use the following command:
`aws s3 ls s3://my_bucket/folder_path/ --human-readable --summarize`


## Google Cloud Storage

(Assuming you have access to google cloud computing platform and a google cloud storage account.)

The easiest way to move files between S3 and Google cloud storage is via the Google Cloud Platform interface `Transfer` under Storage. There, you can simply connect to public buckets
and transfer to a target Google bucket.

Note, in the transfer system, you specify the bucket root name as the source
bucket, then, if your data are in a folder within that bucket, you can
specify this path as a prefix. For example, imagine you wanted to transfer S3://my_bucket/sub_folder1/another_folder/my_image1.tif
S3://my_bucket/sub_folder1/another_folder/my_image2.tif

You would only specify `my_bucket` as the S3 target. And then  `sub_folder1/another_folder`
as the prefix. (Also keys if needed.)

After specifying the destination Google Cloud Storage, and transfering, the files
will move with exactly the same path as they had on the S3 bucket.
E.g. You may specify `gs://my_google_bucket` as the destination, and start
the transfer job. The files will automatically be placed at:
`gs://my_google_bucket/sub_folder1/another_folder/my_image1.tif` and `gs://my_google_bucket/sub_folder1/another_folder/my_image2.tif`

#### Another option is to use CLI tools:

Authenticate your google cloud CLI:

`gcloud auth login`

Connect to your Google Cloud project

e.g. `gcloud config set project gfw-apis`

At this point, you should be able to access your google cloud resources, e.g. listing GCS buckets:

```bash
$gsutil ls
gs://asithappens/
gs://carbonloss_test/
gs://gfw-apis-analysis/
gs://gfw-apis-country/
gs://gfw-apis-truth/
gs://gfw_subscriptions_150407/
gs://gfw_subscriptions_backups/
gs://landsat-2015/
gs://landsat-cache/
gs://s3_2gee/
```

If you need to connect to an S3 bucket that requires authentication, then
create a `.boto` file in your users home directory, with the following contents:

```
[Credentials]
aws_access_key_id=XXXXXXXXXXX
aws_secret_access_key=XXXXXXXXXXXX

```

You should then be able to copy file(s) from S3 to GCS as follows:

```
gsutil -m cp -R s3://target_bucket/target_file gs://destination_bucket/
```
Note, the -m flag enables parallel transfers.


## Earth Engine data ingress

You will need to authenticte your earthengine command line tool:

`earthengine authenticate`

Once your data is in Google Cloud Storage, we can easily move it into Earth Engine.

First, we need to list the files we are interested in moving:

```bash
gsutil ls gs://s3_2gee/sam/carbon_budget
gs://s3_2gee/sam/carbon_budget/bgc/
gs://s3_2gee/sam/carbon_budget/carbon/
gs://s3_2gee/sam/carbon_budget/deadwood/
gs://s3_2gee/sam/carbon_budget/litter/
gs://s3_2gee/sam/carbon_budget/soil/
gs://s3_2gee/sam/carbon_budget/total_carbon/
```

e.g. imagine we wanted to create a list of all the tiff files in the soil folder:

`gsutil ls gs://s3_2gee/sam/carbon_budget/soil > gcs_flist`


```
cat gcs_flist | head -n 3
gs://s3_2gee/sam/carbon_budget/soil/00N_000E_soil.tif
gs://s3_2gee/sam/carbon_budget/soil/00N_010E_soil.tif
gs://s3_2gee/sam/carbon_budget/soil/00N_020E_soil.tif
```

Now we have a list of targets, we need to create a collection asset in Earth Engine
to use as a write target.

```bash
earthengine create collection users/benlaken/soil_carbon_collection
```

Next, we use the upload command to send individual images to the collection like so:

```
earthengine upload image --asset_id users/benlaken/soil_carbon_collection/00N_000E_soil gs://s3_2gee/sam/carbon_budget/soil/00N_000E_soil.tif
```
Note the name of the **destination** image must be specified after the collection name.

Note, the **“projects/wri-datalab”** Earth Engine account has extended data, and
should be used to ingest and hold Data Layers for WRI. Ask for write access to this
account if you need to add large volumes of data to Global Forest Watch projects.

To send all the image targets we can put all this together to create a bash script as follows:


```bash
#!/bin/bash
bucket="gs://s3_2gee/sam/carbon_budget/soil/"
EE_user="users/benlaken/soil_carbon_collection"
suffix=".tif"
gsutil ls ${bucket} > gcs_flist
cat gcs_flist | while read f
 do
   fname_short=${f#$bucket}
   fname_short=${fname_short%$suffix}
   earthengine upload image --asset_id ${EE_user}/${fname_short} ${f}
done
 ```
