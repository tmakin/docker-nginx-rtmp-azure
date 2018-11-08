from azure.storage.blob import BlockBlobService
from azure.common import AzureHttpError

import argparse
import os
import json
from datetime import datetime, timedelta

minFileSize = 100*1000 # 100 kB

# https://docs.python.org/3/howto/argparse.html#id1
parser = argparse.ArgumentParser(description='Upload file to blob storage')

parser.add_argument('file', help='path to video to upload')
parser.add_argument('account', help='account name')
parser.add_argument('sas', help='SAS signature name')
parser.add_argument('--container', help='container name (default:video-uploads)', default="video-uploads");

args = parser.parse_args()

filePath = args.file
fileName = os.path.basename(filePath)

now = datetime.utcnow()
if_unmodified_since = now- timedelta(hours=0, minutes=30)
print(if_unmodified_since)

def getFileInfo():
    data = {
        'fileName': fileName,
        'size': 0,
        'time': now.isoformat(),
        'error': None
    }

    if not os.path.isfile(filePath):
        data['error'] = "File is missing"
        return data;

    if not os.access(filePath, os.R_OK):
        data['error'] = "File is not readable"
        return data;

    # Get size in kB
    size = data['size'] = os.path.getsize(filePath)

    #if size < minFileSize:
        #data['error'] = "File size too small. min={0} bytes".format(minFileSize)

    return data


# get file info
fileInfo = getFileInfo()

# write log file
logFilePath = filePath+'.log'
logFileName = fileName+'.log'
with open(logFilePath, 'w') as outfile:
    json.dump(fileInfo, outfile)

print(fileInfo)

#print(args.container, blob_name, args.file)

# upload blobs
service = BlockBlobService(account_name=args.account, sas_token=args.sas)

# upload helper
def upload_blob(path):
    blob_name = os.path.basename(path)

    try:
        service.create_blob_from_path(args.container, blob_name, path, if_unmodified_since=if_unmodified_since)
    except AzureHttpError as e:
        # print(dir(e))
        print('Failed to upload blob: ' + e.error_code);


if not fileInfo['error']:
    upload_blob(filePath)

upload_blob(logFilePath)
