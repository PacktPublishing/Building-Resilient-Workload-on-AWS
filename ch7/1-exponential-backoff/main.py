import time
import random

MAX_RETRIES = 5  # Maximum number of retries
INITIAL_DELAY = 1  # Initial delay in seconds
MAX_DELAY = 60  # Maximum delay in seconds

def exponential_backoff(retries, delay):
    """
    Exponential backoff function to calculate the delay for the next retry.

    """

    delay = min(delay * 2, MAX_DELAY)
    jitter = random.uniform(0, delay / 2)
    return delay + jitter

def make_request(retry_count=0):
    """
    Function to make a request and handle retries with exponential backoff.

    """

    try:
        # Make the request here
        # If successful, return the response
        print("Request successful!")
        return "Success"
    except Exception as e:
        # Request failed
        if retry_count < MAX_RETRIES:
            delay = exponential_backoff(retry_count, INITIAL_DELAY)
            print(f"Request failed. Retrying in {delay} seconds...")
            time.sleep(delay)
            return make_request(retry_count + 1)
        else:
            print("Maximum retries exceeded. Request failed.")
            raise e

# Example usage
response = make_request()
print(response)