import os

import boto3
from tqdm import tqdm


def download_all_objects_in_folder(bucket, prefix, local):
    s3_resource = boto3.resource("s3")
    my_bucket = s3_resource.Bucket(bucket)
    objects = my_bucket.objects.filter(Prefix=prefix)
    if not os.path.exists(local):
        os.mkdir(local)
    for obj in tqdm(objects):
        path, filename = os.path.split(obj.key)
        if not filename:
            continue
        dest_pathname = obj.key.replace(prefix, f"{local}/")
        if not os.path.exists(os.path.dirname(dest_pathname)):
            os.makedirs(os.path.dirname(dest_pathname))
        my_bucket.download_file(obj.key, dest_pathname)


def main():
    if not os.getenv("S3_DATA_PATH"):
        raise Exception("S3_DATA_PATH haven't define")
    if not os.getenv("BUCKET_NAME"):
        raise Exception("BUCKET_NAME haven't define")
    download_all_objects_in_folder(
        prefix=os.getenv("S3_DATA_PATH"),
        local=os.getenv("DATADIR", "data"),
        bucket=os.getenv("BUCKET_NAME"),
    )


if __name__ == "__main__":
    main()
