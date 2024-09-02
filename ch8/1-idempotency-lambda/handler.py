import boto3
import time
from botocore.exceptions import ClientError


dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('Orders')

def lambda_handler(event, context):
    order_id = event['orderId']

    # Check if order already exists (deduplication)
    try:
        response = table.get_item(Key={'orderId': order_id})
    except ClientError:
        return {'statusCode': 500, 'body': 'Error retrieving order'}

    if 'Item' in response:
        return {'statusCode': 200, 'body': 'Order already processed'}

    # Acquire lock
    lock_key = f'lock_{order_id}'
    try:
        table.put_item(Item={'key': lock_key}, ConditionExpression='attribute_not_exists(key)')
    except ClientError as e:
        if e.response['Error']['Code'] == 'ConditionalCheckFailedException':
            return {'statusCode': 200, 'body': 'Order already being processed'}
        raise e

    try:
        # Process order
        unique_id = f'{order_id}_{int(time.time())}'
        table.put_item(Item={'orderId': order_id, 'status': 'processed', 'uniqueId': unique_id})
    finally:
        # Release lock
        table.delete_item(Key={'key': lock_key})

    return {'statusCode': 200, 'body': 'Order processed successfully'}