from azure.storage.blob import BlockBlobService

import argparse
import os

# https://docs.python.org/3/howto/argparse.html#id1
parser = argparse.ArgumentParser(description='Upload file to blob storage')

parser.add_argument('file', help='path to video to upload')
parser.add_argument('account', help='account name')
parser.add_argument('sas', help='SAS signature name')
parser.add_argument('--container', help='container name (default:video-uploads)', default="video-uploads");

#parser.add_argument('container', help='container name')

# parser.add_argument('sas', help='shared access signature')
args = parser.parse_args()

file = args.file

if not os.path.isfile(file):
    print("File is missing: " +file)
    exit(1)

if not os.access(file, os.R_OK):
    print("File is not readable: " +file)
    exit(1)

print(args)

blob_name = os.path.basename(args.file)

#print(args.container, blob_name, args.file)

service = BlockBlobService(account_name=args.account, sas_token=args.sas)

service.create_blob_from_path(args.container, blob_name, args.file);