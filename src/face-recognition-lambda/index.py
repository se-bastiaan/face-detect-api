import face_recognition
import json
from urllib.request import urlopen
import numpy as np
from PIL import Image
import logging

logging.basicConfig(level=logging.DEBUG)

class NumpyEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, np.ndarray):
            return obj.tolist()
        return json.JSONEncoder.default(self, obj)


def lambda_handler(event, context):
    print(event)
    logging.debug(event)
    if event["requestContext"]["http"]["method"] != "POST":
        return {
            "statusCode": 405,
            "headers": {"Content-Type": "application/json", "Allow": "POST"},
        }

    try:
        input = parse_event_body(event)
    except ValueError as e:
        return {
            "statusCode": 422,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({"error": str(e)}),
        }

    result = []
    for item in input:
        result.append(obtain_face_encodings(item))

    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(result, cls=NumpyEncoder),
    }


def obtain_face_encodings(input):
    img = Image.open(urlopen(input["url"]))
    img = img.convert("RGB")
    img.thumbnail((500, 500))
    encodings = face_recognition.face_encodings(np.array(img))
    return {"id": input["id"], "url": input["url"], "encodings": encodings}


def parse_event_body(event):
    headers = event["headers"]

    try:
        if headers["content-type"] != "application/json":
            raise ValueError("Input is not a valid JSON array")

        body = json.loads(event["body"])
    except Exception as e:
        logging.exception(e)
        raise ValueError("Input is not a valid JSON array")

    if not isinstance(body, list):
        logging.debug("body is not a list")
        raise ValueError("Input is not a valid JSON array")

    for item in body:
        if not "url" in item:
            raise ValueError("Not all items in the input array have an url")
        if not "id" in item:
            raise ValueError("Not all items in the input array have an id")

    return body
