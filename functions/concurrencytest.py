import os
import time
import json

class StaticClass():
  initTime = time.time()
  print('Static block was executed at {}'.format(initTime))

  cold_start_sleep_interval_val = os.environ.get('COLD_START_DELAY')
  if cold_start_sleep_interval_val is None:
    cold_start_sleep_interval = 5
  else:
    cold_start_sleep_interval = int(cold_start_sleep_interval_val)

  time.sleep(cold_start_sleep_interval)

def lambda_handler(event, context):

  obj = StaticClass()
  currentTime = time.time()

  execute_sleep_interval = event.get('sleep')

  if execute_sleep_interval is None:
    execute_sleep_interval = 3
  time.sleep(execute_sleep_interval)

  msg = 'Hello from Concurrency Test Lambda, creation:{}, execution: {}!'.format(obj.initTime, currentTime)
  response = {
    'msg': msg,
    'creation': obj.initTime,
    'execution': currentTime
  }
  
  return {
    'statusCode': 200,
    'body': json.dumps(response)
  }
