import boto3
from boto3.dynamodb.conditions import Key
from boto3.dynamodb.types import TypeDeserializer
import os
import numpy as np
import json
import base64
from urllib import request

dynamodb = boto3.resource("dynamodb", region_name=os.environ["AWS_REGION"])
deserializer = TypeDeserializer()


class NumpyEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, np.ndarray):
            return obj.tolist()
        return json.JSONEncoder.default(self, obj)


def lambda_handler(event, _):
    table = dynamodb.Table(event["tableName"])
    result = table.query(
        KeyConditionExpression=Key("execution").eq(event["executionId"])
    )

    with table.batch_writer() as batch:
        for item in result["Items"]:
            batch.delete_item(Key={"execution": item["execution"], "id": item["id"]})

    data = [
        {
            "id": result["id"],
            "url": result["url"],
            "encodings": [
                np.frombuffer(base64.b64decode(encoding.value))
                for encoding in result["encodings"]
            ],
        }
        for result in result["Items"]
    ]

    req = request.Request(
        event["callback"],
        data=json.dumps(data, cls=NumpyEncoder).encode(),
        headers={"content-type": "application/json"},
    )
    request.urlopen(req)

    return "done"
