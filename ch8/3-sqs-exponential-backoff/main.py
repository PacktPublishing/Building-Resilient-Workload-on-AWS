import boto3
import random
import time

sqs = boto3.client('sqs')
queue_url = 'https://sqs.us-east-1.amazonaws.com/123456789012/my-queue'

def send_message_with_backoff(message_body):
    delay = 1  # Initial delay in seconds
    max_delay = 60  # Maximum delay in seconds

    while True:
        try:
            response = sqs.send_message(
                QueueUrl=queue_url,
                MessageBody=message_body
            )
            return response
        except sqs.exceptions.TooManyEntriesInBatchException as e:
            # Handle throttling exception
            if delay > max_delay:
                raise e
            # Introduce jitter to avoid synchronous retries
            sleep_time = delay + random.random()
            time.sleep(sleep_time)
            delay *= 2  # Exponential backoff
        except Exception as e:
            # Handle other exceptions
            raise e